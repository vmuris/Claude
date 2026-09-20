import Foundation

public enum ErrorSalud: LocalizedError, Sendable {
    case noDisponible
    case permisoNegado
    case consulta(String)

    public var errorDescription: String? {
        switch self {
        case .noDisponible: return "Salud no está disponible en este dispositivo."
        case .permisoNegado: return "Falta permiso de Salud. Actívalo en el iPhone."
        case .consulta(let detalle): return "No se pudo leer Salud: \(detalle)"
        }
    }
}

/// Todo lo que la app necesita de Salud. La interfaz solo conoce esto, así
/// que funciona igual con HealthKit real que con datos de demostración.
public protocol FuenteSalud: Sendable {
    func pedirPermisos() async throws
    func dia(_ fecha: Date) async throws -> ResumenDia
    func ultimosDias(_ cantidad: Int) async throws -> [ResumenDia]
    func registrarComida(kcal: Double, proteinaG: Double, fecha: Date) async throws
    func registrarPeso(_ kg: Double, fecha: Date) async throws
    func tendenciaPeso(dias: Int) async throws -> TendenciaPeso?
}

/// Datos sintéticos coherentes para el simulador y las vistas previas:
/// alguien que come bien entre semana, duerme poco el jueves y baja
/// alrededor de medio por ciento a la semana.
public actor FuenteSaludDemo: FuenteSalud {
    private var comidasExtra: [Date: (kcal: Double, proteina: Double)] = [:]
    private let calendario = Calendar.current

    public init() {}

    public func pedirPermisos() async throws {}

    public func dia(_ fecha: Date) async throws -> ResumenDia {
        generar(fecha)
    }

    public func ultimosDias(_ cantidad: Int) async throws -> [ResumenDia] {
        let hoy = calendario.startOfDay(for: Date())
        return (0..<cantidad).compactMap { desplazamiento in
            calendario.date(byAdding: .day, value: -desplazamiento, to: hoy).map(generar)
        }
    }

    public func registrarComida(kcal: Double, proteinaG: Double, fecha: Date) async throws {
        let dia = calendario.startOfDay(for: fecha)
        let previo = comidasExtra[dia] ?? (0, 0)
        comidasExtra[dia] = (previo.kcal + kcal, previo.proteina + proteinaG)
    }

    public func registrarPeso(_ kg: Double, fecha: Date) async throws {}

    public func tendenciaPeso(dias: Int) async throws -> TendenciaPeso? {
        let serie = try await ultimosDias(dias).compactMap(\.pesoKg)
        guard let final = serie.first, let inicial = serie.last, serie.count >= 2 else { return nil }
        return TendenciaPeso(pesoInicialKg: inicial, pesoFinalKg: final, dias: serie.count - 1)
    }

    private func generar(_ fecha: Date) -> ResumenDia {
        let dia = calendario.startOfDay(for: fecha)
        let indice = calendario.dateComponents([.day], from: dia, to: calendario.startOfDay(for: Date())).day ?? 0
        let diaSemana = calendario.component(.weekday, from: dia)   // 1 = domingo
        let esFinde = diaSemana == 1 || diaSemana == 7
        let extra = comidasExtra[dia] ?? (0, 0)

        return ResumenDia(
            fecha: dia,
            energiaConsumida: (esFinde ? 2880 : 2465) + Double((indice % 3) * 40) + extra.kcal,
            proteinaConsumida: (esFinde ? 150 : 182) + extra.proteina,
            energiaActiva: esFinde ? 320 : 540 + Double((indice % 4) * 35),
            energiaBasalMedida: 1810,
            horasSueno: diaSemana == 5 ? 5.4 : (esFinde ? 8.2 : 7.1),
            minutosFuerza: [2, 4, 6].contains(diaSemana) ? 52 : 0,
            minutosCardio: esFinde ? 40 : 0,
            pesoKg: 92.0 - Double(28 - min(indice, 28)) * 0.065
        )
    }
}
