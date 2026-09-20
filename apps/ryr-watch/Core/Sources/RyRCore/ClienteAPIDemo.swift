import Foundation

/// Datos de muestra deterministas. Permiten abrir la app en el simulador
/// sin backend y ver exactamente la misma interfaz.
public struct ClienteAPIDemo: ClienteAPI {
    public let retardo: Duration

    public init(retardo: Duration = .milliseconds(250)) {
        self.retardo = retardo
    }

    public func resumen() async throws -> ResumenDia {
        try await esperar()
        return Self.datos.resumen
    }

    public func pedimentos(limite: Int) async throws -> [Pedimento] {
        try await esperar()
        return Array(Self.datos.pedimentos.prefix(limite))
    }

    public func pedimento(id: String) async throws -> Pedimento {
        try await esperar()
        guard let p = Self.datos.pedimentos.first(where: { $0.id == id }) else {
            throw ErrorAPI.respuestaInvalida(404)
        }
        return p
    }

    public func cartera() async throws -> [ClienteCartera] {
        try await esperar()
        return Self.datos.cartera
    }

    private func esperar() async throws {
        if retardo > .zero { try await Task.sleep(for: retardo) }
    }

    /// Instantánea fija de demostración, también usada por las vistas previas.
    public static let datos: Instantanea = {
        let hoy = Date()
        let pedimentos: [Pedimento] = [
            Pedimento(id: "5000123", numero: "26 40 3721 5000123", patente: "3721", aduana: "400",
                      clave: "A1", cliente: "POCHTECA MATERIAS PRIMAS", clienteID: 29,
                      estatus: .cruzado, valorUSD: 184_320.55,
                      fechaPago: hoy.addingTimeInterval(-7 * 3600),
                      moduladoEn: hoy.addingTimeInterval(-2 * 3600),
                      doda: "DODA-8821-4417", facturado: false),
            Pedimento(id: "5000124", numero: "26 40 3721 5000124", patente: "3721", aduana: "400",
                      clave: "IN", cliente: "TRANS-PACKAGING DE MEXICO", clienteID: 437,
                      estatus: .modulado, valorUSD: 42_780.00,
                      fechaPago: hoy.addingTimeInterval(-4 * 3600),
                      moduladoEn: hoy.addingTimeInterval(-40 * 60),
                      doda: nil, facturado: false),
            Pedimento(id: "5000125", numero: "26 40 3721 5000125", patente: "3721", aduana: "400",
                      clave: "V1", cliente: "TRANSPAKING CRATES", clienteID: 936,
                      estatus: .pagado, valorUSD: 9_410.20,
                      fechaPago: hoy.addingTimeInterval(-90 * 60),
                      moduladoEn: nil, doda: nil, facturado: false),
            Pedimento(id: "5000126", numero: "26 40 3721 5000126", patente: "3721", aduana: "400",
                      clave: "A1", cliente: "UNIVAR SOLUTIONS MEXICO", clienteID: 883,
                      estatus: .detenido, valorUSD: 311_500.00,
                      fechaPago: hoy.addingTimeInterval(-26 * 3600),
                      moduladoEn: hoy.addingTimeInterval(-22 * 3600),
                      doda: nil, facturado: false),
            Pedimento(id: "4100987", numero: "26 22 1941 4100987", patente: "1941", aduana: "220",
                      clave: "A1", cliente: "POCHTECA MATERIAS PRIMAS", clienteID: 29,
                      estatus: .facturado, valorUSD: 76_050.10,
                      fechaPago: hoy.addingTimeInterval(-52 * 3600),
                      moduladoEn: hoy.addingTimeInterval(-48 * 3600),
                      doda: "DODA-7719-2203", facturado: true)
        ]
        let cartera: [ClienteCartera] = [
            ClienteCartera(id: 883, cliente: "UNIVAR SOLUTIONS MEXICO", saldoMXN: 1_842_300.00,
                           vencidoMXN: 940_100.00, documentos: 14, diasPromedio: 96),
            ClienteCartera(id: 29, cliente: "POCHTECA MATERIAS PRIMAS", saldoMXN: 612_450.00,
                           vencidoMXN: 128_900.00, documentos: 9, diasPromedio: 51),
            ClienteCartera(id: 437, cliente: "TRANS-PACKAGING DE MEXICO", saldoMXN: 288_770.00,
                           vencidoMXN: 0, documentos: 6, diasPromedio: 22)
        ]
        let resumen = ResumenDia(
            fecha: hoy,
            pedimentosDelDia: 12,
            crucesDoda: 7,
            pendientesFacturar: 4,
            carteraTotalMXN: cartera.reduce(0) { $0 + $1.saldoMXN },
            carteraVencidaMXN: cartera.reduce(0) { $0 + $1.vencidoMXN },
            alertas: [
                Alerta(id: "a1", titulo: "Pedimento detenido",
                       detalle: "26 40 3721 5000126 lleva 22 h en reconocimiento.",
                       severidad: .critica),
                Alerta(id: "a2", titulo: "Cruzados sin facturar",
                       detalle: "4 pedimentos moduló y no se han facturado.",
                       severidad: .alta)
            ]
        )
        return Instantanea(resumen: resumen, pedimentos: pedimentos, cartera: cartera, actualizada: hoy)
    }()
}
