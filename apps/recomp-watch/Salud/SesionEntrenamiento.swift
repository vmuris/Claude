import Foundation
import HealthKit
import Combine

/// Entrenamiento en vivo desde el reloj. Es lo que hace que el gasto del día
/// deje de ser una estimación: durante la sesión se mide frecuencia cardiaca
/// y energía real, y al terminar queda guardado en Salud.
@MainActor
public final class SesionEntrenamiento: NSObject, ObservableObject {
    @Published public private(set) var activa = false
    @Published public private(set) var enPausa = false
    @Published public private(set) var kcal: Double = 0
    @Published public private(set) var pulso: Double = 0
    @Published public private(set) var duracion: TimeInterval = 0
    @Published public private(set) var error: String?

    private let store = HKHealthStore()
    private var sesion: HKWorkoutSession?
    private var constructor: HKLiveWorkoutBuilder?
    private var inicio: Date?
    private var reloj: Timer?

    public enum Tipo: String, CaseIterable, Identifiable, Sendable {
        case fuerza
        case caminata
        case carrera
        case bici
        case intervalos

        public var id: String { rawValue }

        public var etiqueta: String {
            switch self {
            case .fuerza: return "Fuerza"
            case .caminata: return "Caminata"
            case .carrera: return "Carrera"
            case .bici: return "Bici"
            case .intervalos: return "Intervalos"
            }
        }

        public var simbolo: String {
            switch self {
            case .fuerza: return "dumbbell.fill"
            case .caminata: return "figure.walk"
            case .carrera: return "figure.run"
            case .bici: return "bicycle"
            case .intervalos: return "bolt.heart.fill"
            }
        }

        var actividad: HKWorkoutActivityType {
            switch self {
            case .fuerza: return .traditionalStrengthTraining
            case .caminata: return .walking
            case .carrera: return .running
            case .bici: return .cycling
            case .intervalos: return .highIntensityIntervalTraining
            }
        }
    }

    public func iniciar(_ tipo: Tipo) {
        guard HKHealthStore.isHealthDataAvailable(), !activa else { return }

        let configuracion = HKWorkoutConfiguration()
        configuracion.activityType = tipo.actividad
        configuracion.locationType = tipo == .caminata || tipo == .carrera ? .outdoor : .indoor

        do {
            let nueva = try HKWorkoutSession(healthStore: store, configuration: configuracion)
            let builder = nueva.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store,
                                                         workoutConfiguration: configuracion)
            nueva.delegate = self
            builder.delegate = self

            let ahora = Date()
            nueva.startActivity(with: ahora)
            builder.beginCollection(withStart: ahora) { [weak self] _, error in
                guard let error else { return }
                Task { @MainActor in self?.error = error.localizedDescription }
            }

            sesion = nueva
            constructor = builder
            inicio = ahora
            activa = true
            enPausa = false
            kcal = 0
            pulso = 0
            duracion = 0
            arrancarReloj()
        } catch {
            self.error = error.localizedDescription
        }
    }

    public func pausar() {
        sesion?.pause()
        enPausa = true
    }

    public func reanudar() {
        sesion?.resume()
        enPausa = false
    }

    public func terminar() {
        guard let sesion, let constructor else { return }
        let fin = Date()
        sesion.end()
        constructor.endCollection(withEnd: fin) { [weak self] _, _ in
            constructor.finishWorkout { _, _ in
                Task { @MainActor in self?.limpiar() }
            }
        }
    }

    public func descartar() {
        sesion?.end()
        constructor?.discardWorkout()
        limpiar()
    }

    private func limpiar() {
        reloj?.invalidate()
        reloj = nil
        sesion = nil
        constructor = nil
        inicio = nil
        activa = false
        enPausa = false
    }

    private func arrancarReloj() {
        reloj?.invalidate()
        reloj = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let inicio = self.inicio, !self.enPausa else { return }
                self.duracion = Date().timeIntervalSince(inicio)
            }
        }
    }

    public var duracionTexto: String {
        let total = Int(duracion)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

extension SesionEntrenamiento: HKWorkoutSessionDelegate {
    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession,
                                           didChangeTo toState: HKWorkoutSessionState,
                                           from fromState: HKWorkoutSessionState,
                                           date: Date) {
        Task { @MainActor in
            switch toState {
            case .running: self.enPausa = false
            case .paused: self.enPausa = true
            case .ended, .stopped: self.activa = false
            default: break
            }
        }
    }

    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession,
                                           didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error.localizedDescription
            self.limpiar()
        }
    }
}

extension SesionEntrenamiento: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                           didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for tipo in collectedTypes {
            guard let tipoCantidad = tipo as? HKQuantityType,
                  let estadisticas = workoutBuilder.statistics(for: tipoCantidad) else { continue }

            if tipoCantidad == HKQuantityType(.activeEnergyBurned) {
                let valor = estadisticas.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor in self.kcal = valor }
            } else if tipoCantidad == HKQuantityType(.heartRate) {
                let unidad = HKUnit.count().unitDivided(by: .minute())
                let valor = estadisticas.mostRecentQuantity()?.doubleValue(for: unidad) ?? 0
                Task { @MainActor in self.pulso = valor }
            }
        }
    }
}
