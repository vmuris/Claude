import Foundation

/// Estatus operativo de un pedimento. Decodifica tolerante: un valor
/// desconocido del backend no rompe la lista completa.
public enum EstatusPedimento: String, Codable, CaseIterable, Sendable {
    case capturado
    case pagado
    case modulado
    case cruzado
    case facturado
    case detenido
    case desconocido

    public init(from decoder: Decoder) throws {
        let crudo = try decoder.singleValueContainer().decode(String.self)
        self = EstatusPedimento(rawValue: crudo.lowercased()) ?? .desconocido
    }

    public var etiqueta: String {
        switch self {
        case .capturado: return "Capturado"
        case .pagado: return "Pagado"
        case .modulado: return "Modulado"
        case .cruzado: return "Cruzado"
        case .facturado: return "Facturado"
        case .detenido: return "Detenido"
        case .desconocido: return "Sin estatus"
        }
    }

    /// Avance del flujo, 0 a 1. Sirve para la barra de progreso del detalle.
    public var avance: Double {
        switch self {
        case .capturado: return 0.2
        case .pagado: return 0.4
        case .modulado: return 0.6
        case .cruzado: return 0.8
        case .facturado: return 1.0
        case .detenido, .desconocido: return 0.0
        }
    }

    public var requiereAtencion: Bool {
        self == .detenido
    }
}

public enum Severidad: String, Codable, Sendable {
    case info
    case alta
    case critica

    public init(from decoder: Decoder) throws {
        let crudo = try decoder.singleValueContainer().decode(String.self)
        self = Severidad(rawValue: crudo.lowercased()) ?? .info
    }
}

public struct Alerta: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let titulo: String
    public let detalle: String
    public let severidad: Severidad

    public init(id: String, titulo: String, detalle: String, severidad: Severidad) {
        self.id = id
        self.titulo = titulo
        self.detalle = detalle
        self.severidad = severidad
    }
}

/// KPIs del día. Es lo que ve el usuario al levantar la muñeca.
public struct ResumenDia: Codable, Hashable, Sendable {
    public let fecha: Date
    public let pedimentosDelDia: Int
    public let crucesDoda: Int
    public let pendientesFacturar: Int
    public let carteraTotalMXN: Double
    public let carteraVencidaMXN: Double
    public let alertas: [Alerta]

    enum CodingKeys: String, CodingKey {
        case fecha
        case pedimentosDelDia = "pedimentos_del_dia"
        case crucesDoda = "cruces_doda"
        case pendientesFacturar = "pendientes_facturar"
        case carteraTotalMXN = "cartera_total_mxn"
        case carteraVencidaMXN = "cartera_vencida_mxn"
        case alertas
    }

    public init(fecha: Date, pedimentosDelDia: Int, crucesDoda: Int, pendientesFacturar: Int,
                carteraTotalMXN: Double, carteraVencidaMXN: Double, alertas: [Alerta]) {
        self.fecha = fecha
        self.pedimentosDelDia = pedimentosDelDia
        self.crucesDoda = crucesDoda
        self.pendientesFacturar = pendientesFacturar
        self.carteraTotalMXN = carteraTotalMXN
        self.carteraVencidaMXN = carteraVencidaMXN
        self.alertas = alertas
    }

    /// Porcentaje de la cartera que ya venció. 0 cuando no hay cartera.
    public var proporcionVencida: Double {
        guard carteraTotalMXN > 0 else { return 0 }
        return min(carteraVencidaMXN / carteraTotalMXN, 1)
    }

    public static let vacio = ResumenDia(
        fecha: Date(timeIntervalSince1970: 0),
        pedimentosDelDia: 0, crucesDoda: 0, pendientesFacturar: 0,
        carteraTotalMXN: 0, carteraVencidaMXN: 0, alertas: []
    )
}

public struct Pedimento: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let numero: String
    public let patente: String
    public let aduana: String
    public let clave: String
    public let cliente: String
    public let clienteID: Int
    public let estatus: EstatusPedimento
    public let valorUSD: Double
    public let fechaPago: Date?
    public let moduladoEn: Date?
    public let doda: String?
    public let facturado: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case numero
        case patente
        case aduana
        case clave
        case cliente
        case clienteID = "cliente_id"
        case estatus
        case valorUSD = "valor_usd"
        case fechaPago = "fecha_pago"
        case moduladoEn = "modulado_en"
        case doda
        case facturado
    }

    public init(id: String, numero: String, patente: String, aduana: String, clave: String,
                cliente: String, clienteID: Int, estatus: EstatusPedimento, valorUSD: Double,
                fechaPago: Date?, moduladoEn: Date?, doda: String?, facturado: Bool) {
        self.id = id
        self.numero = numero
        self.patente = patente
        self.aduana = aduana
        self.clave = clave
        self.cliente = cliente
        self.clienteID = clienteID
        self.estatus = estatus
        self.valorUSD = valorUSD
        self.fechaPago = fechaPago
        self.moduladoEn = moduladoEn
        self.doda = doda
        self.facturado = facturado
    }

    public var cruzo: Bool {
        doda?.isEmpty == false
    }
}

public struct ClienteCartera: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let cliente: String
    public let saldoMXN: Double
    public let vencidoMXN: Double
    public let documentos: Int
    public let diasPromedio: Int

    enum CodingKeys: String, CodingKey {
        case id
        case cliente
        case saldoMXN = "saldo_mxn"
        case vencidoMXN = "vencido_mxn"
        case documentos
        case diasPromedio = "dias_promedio"
    }

    public init(id: Int, cliente: String, saldoMXN: Double, vencidoMXN: Double,
                documentos: Int, diasPromedio: Int) {
        self.id = id
        self.cliente = cliente
        self.saldoMXN = saldoMXN
        self.vencidoMXN = vencidoMXN
        self.documentos = documentos
        self.diasPromedio = diasPromedio
    }

    /// Semáforo de cobranza por antigüedad promedio.
    public var riesgo: Severidad {
        if diasPromedio >= 90 { return .critica }
        if diasPromedio >= 45 { return .alta }
        return .info
    }
}

/// Foto completa de la operación. Es la unidad que se cachea y la que lee
/// la complicación.
public struct Instantanea: Codable, Hashable, Sendable {
    public let resumen: ResumenDia
    public let pedimentos: [Pedimento]
    public let cartera: [ClienteCartera]
    public let actualizada: Date

    public init(resumen: ResumenDia, pedimentos: [Pedimento], cartera: [ClienteCartera], actualizada: Date) {
        self.resumen = resumen
        self.pedimentos = pedimentos
        self.cartera = cartera
        self.actualizada = actualizada
    }

    public static let vacia = Instantanea(
        resumen: .vacio, pedimentos: [], cartera: [], actualizada: Date(timeIntervalSince1970: 0)
    )
}
