import Foundation
import HealthKit
import RecompCore

/// Implementación real sobre HealthKit. Lee sueño, energía y entrenamientos;
/// escribe lo que tú registras (comida y peso). Nada sale del dispositivo.
public struct SaludHealthKit: FuenteSalud {
    private let store: HKHealthStore
    private let calendario: Calendar

    public init(store: HKHealthStore = HKHealthStore(), calendario: Calendar = .current) {
        self.store = store
        self.calendario = calendario
    }

    private static let energiaConsumida = HKQuantityType(.dietaryEnergyConsumed)
    private static let proteina = HKQuantityType(.dietaryProtein)
    private static let energiaActiva = HKQuantityType(.activeEnergyBurned)
    private static let energiaBasal = HKQuantityType(.basalEnergyBurned)
    private static let peso = HKQuantityType(.bodyMass)
    private static let pulso = HKQuantityType(.heartRate)
    private static let sueno = HKCategoryType(.sleepAnalysis)

    public static var tiposLectura: Set<HKObjectType> {
        [energiaConsumida, proteina, energiaActiva, energiaBasal, peso, pulso, sueno,
         HKObjectType.workoutType()]
    }

    public static var tiposEscritura: Set<HKSampleType> {
        [energiaConsumida, proteina, peso, energiaActiva, HKObjectType.workoutType()]
    }

    public func pedirPermisos() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw ErrorSalud.noDisponible }
        do {
            try await store.requestAuthorization(toShare: Self.tiposEscritura, read: Self.tiposLectura)
        } catch {
            throw ErrorSalud.permisoNegado
        }
    }

    public func dia(_ fecha: Date) async throws -> ResumenDia {
        let inicio = calendario.startOfDay(for: fecha)
        let fin = calendario.date(byAdding: .day, value: 1, to: inicio) ?? inicio
        let rango = HKQuery.predicateForSamples(withStart: inicio, end: fin, options: .strictStartDate)

        async let kcal = suma(Self.energiaConsumida, unidad: .kilocalorie(), predicado: rango)
        async let prot = suma(Self.proteina, unidad: .gram(), predicado: rango)
        async let activa = suma(Self.energiaActiva, unidad: .kilocalorie(), predicado: rango)
        async let basal = suma(Self.energiaBasal, unidad: .kilocalorie(), predicado: rango)
        async let horas = horasDeSueno(para: inicio)
        async let entrenos = entrenamientos(inicio: inicio, fin: fin)
        async let pesoDelDia = ultimoPeso(hasta: fin)

        let (fuerza, cardio) = try await entrenos
        return ResumenDia(fecha: inicio,
                          energiaConsumida: try await kcal,
                          proteinaConsumida: try await prot,
                          energiaActiva: try await activa,
                          energiaBasalMedida: try await basal,
                          horasSueno: try await horas,
                          minutosFuerza: fuerza,
                          minutosCardio: cardio,
                          pesoKg: try await pesoDelDia)
    }

    public func ultimosDias(_ cantidad: Int) async throws -> [ResumenDia] {
        let hoy = calendario.startOfDay(for: Date())
        var resultado: [ResumenDia] = []
        for desplazamiento in 0..<cantidad {
            guard let fecha = calendario.date(byAdding: .day, value: -desplazamiento, to: hoy) else { continue }
            resultado.append(try await dia(fecha))
        }
        return resultado
    }

    public func registrarComida(kcal: Double, proteinaG: Double, fecha: Date) async throws {
        var muestras: [HKQuantitySample] = []
        if kcal > 0 {
            muestras.append(HKQuantitySample(
                type: Self.energiaConsumida,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                start: fecha, end: fecha))
        }
        if proteinaG > 0 {
            muestras.append(HKQuantitySample(
                type: Self.proteina,
                quantity: HKQuantity(unit: .gram(), doubleValue: proteinaG),
                start: fecha, end: fecha))
        }
        guard !muestras.isEmpty else { return }
        do {
            try await store.save(muestras)
        } catch {
            throw ErrorSalud.consulta(error.localizedDescription)
        }
    }

    public func registrarPeso(_ kg: Double, fecha: Date) async throws {
        let muestra = HKQuantitySample(
            type: Self.peso,
            quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg),
            start: fecha, end: fecha)
        do {
            try await store.save(muestra)
        } catch {
            throw ErrorSalud.consulta(error.localizedDescription)
        }
    }

    public func tendenciaPeso(dias: Int) async throws -> TendenciaPeso? {
        let fin = Date()
        guard let inicio = calendario.date(byAdding: .day, value: -dias, to: fin) else { return nil }
        let muestras = try await pesos(inicio: inicio, fin: fin)
        guard muestras.count >= 2, let primera = muestras.first, let ultima = muestras.last else { return nil }

        // Promedio de los tres primeros y los tres últimos: una báscula suelta
        // varía medio kilo por el agua, y ese ruido no debe mover el plan.
        let inicial = promedio(muestras.prefix(3).map(\.kg))
        let final = promedio(muestras.suffix(3).map(\.kg))
        let span = calendario.dateComponents([.day], from: primera.fecha, to: ultima.fecha).day ?? 0
        guard span > 0 else { return nil }
        return TendenciaPeso(pesoInicialKg: inicial, pesoFinalKg: final, dias: span)
    }

    // MARK: - Consultas

    private func promedio(_ valores: [Double]) -> Double {
        guard !valores.isEmpty else { return 0 }
        return valores.reduce(0, +) / Double(valores.count)
    }

    private func suma(_ tipo: HKQuantityType, unidad: HKUnit, predicado: NSPredicate) async throws -> Double {
        try await withCheckedThrowingContinuation { continuacion in
            let consulta = HKStatisticsQuery(quantityType: tipo,
                                             quantitySamplePredicate: predicado,
                                             options: .cumulativeSum) { _, estadisticas, error in
                if let error = error as? HKError, error.code == .errorNoData {
                    return continuacion.resume(returning: 0)
                }
                if let error {
                    return continuacion.resume(throwing: ErrorSalud.consulta(error.localizedDescription))
                }
                let total = estadisticas?.sumQuantity()?.doubleValue(for: unidad) ?? 0
                continuacion.resume(returning: total)
            }
            store.execute(consulta)
        }
    }

    /// Ventana de sueño: de las 6 de la tarde del día anterior al mediodía.
    private func horasDeSueno(para inicioDelDia: Date) async throws -> Double {
        guard let desde = calendario.date(byAdding: .hour, value: -6, to: inicioDelDia),
              let hasta = calendario.date(byAdding: .hour, value: 12, to: inicioDelDia) else { return 0 }
        let predicado = HKQuery.predicateForSamples(withStart: desde, end: hasta, options: [])

        let muestras: [HKCategorySample] = try await withCheckedThrowingContinuation { continuacion in
            let consulta = HKSampleQuery(sampleType: Self.sueno, predicate: predicado,
                                         limit: HKObjectQueryNoLimit,
                                         sortDescriptors: nil) { _, resultado, error in
                if let error {
                    return continuacion.resume(throwing: ErrorSalud.consulta(error.localizedDescription))
                }
                continuacion.resume(returning: (resultado as? [HKCategorySample]) ?? [])
            }
            store.execute(consulta)
        }

        let dormido = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))
        let segundos = muestras
            .filter { dormido.contains($0.value) }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return segundos / 3600
    }

    private func entrenamientos(inicio: Date, fin: Date) async throws -> (fuerza: Double, cardio: Double) {
        let predicado = HKQuery.predicateForSamples(withStart: inicio, end: fin, options: .strictStartDate)
        let muestras: [HKWorkout] = try await withCheckedThrowingContinuation { continuacion in
            let consulta = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicado,
                                         limit: HKObjectQueryNoLimit,
                                         sortDescriptors: nil) { _, resultado, error in
                if let error {
                    return continuacion.resume(throwing: ErrorSalud.consulta(error.localizedDescription))
                }
                continuacion.resume(returning: (resultado as? [HKWorkout]) ?? [])
            }
            store.execute(consulta)
        }

        var fuerza = 0.0
        var cardio = 0.0
        for entreno in muestras {
            let minutos = entreno.duration / 60
            if Self.esFuerza(entreno.workoutActivityType) {
                fuerza += minutos
            } else {
                cardio += minutos
            }
        }
        return (fuerza, cardio)
    }

    static func esFuerza(_ tipo: HKWorkoutActivityType) -> Bool {
        switch tipo {
        case .traditionalStrengthTraining, .functionalStrengthTraining, .crossTraining:
            return true
        default:
            return false
        }
    }

    private func pesos(inicio: Date, fin: Date) async throws -> [(fecha: Date, kg: Double)] {
        let predicado = HKQuery.predicateForSamples(withStart: inicio, end: fin, options: [])
        let orden = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        let muestras: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuacion in
            let consulta = HKSampleQuery(sampleType: Self.peso, predicate: predicado,
                                         limit: HKObjectQueryNoLimit,
                                         sortDescriptors: orden) { _, resultado, error in
                if let error {
                    return continuacion.resume(throwing: ErrorSalud.consulta(error.localizedDescription))
                }
                continuacion.resume(returning: (resultado as? [HKQuantitySample]) ?? [])
            }
            store.execute(consulta)
        }
        return muestras.map { ($0.startDate, $0.quantity.doubleValue(for: .gramUnit(with: .kilo))) }
    }

    private func ultimoPeso(hasta fecha: Date) async throws -> Double? {
        guard let desde = calendario.date(byAdding: .day, value: -3, to: fecha) else { return nil }
        return try await pesos(inicio: desde, fin: fecha).last?.kg
    }
}
