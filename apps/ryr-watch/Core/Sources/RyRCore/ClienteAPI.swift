import Foundation

public enum ErrorAPI: LocalizedError, Equatable, Sendable {
    case sinConfigurar
    case urlInvalida
    case noAutorizado
    case respuestaInvalida(Int)
    case red(String)
    case decodificacion(String)

    public var errorDescription: String? {
        switch self {
        case .sinConfigurar: return "Falta configurar el servidor en el iPhone."
        case .urlInvalida: return "La dirección del servidor no es válida."
        case .noAutorizado: return "Token rechazado. Revísalo en el iPhone."
        case .respuestaInvalida(let codigo): return "El servidor respondió \(codigo)."
        case .red(let detalle): return "Sin conexión: \(detalle)"
        case .decodificacion(let detalle): return "Respuesta ilegible: \(detalle)"
        }
    }
}

/// Contrato de datos. La app solo conoce este protocolo, así que la vista
/// funciona igual con el backend real que con los datos de demostración.
public protocol ClienteAPI: Sendable {
    func resumen() async throws -> ResumenDia
    func pedimentos(limite: Int) async throws -> [Pedimento]
    func pedimento(id: String) async throws -> Pedimento
    func cartera() async throws -> [ClienteCartera]
}

public extension ClienteAPI {
    /// Trae todo de un jalón. Las tres llamadas van en paralelo.
    func instantanea(limitePedimentos: Int = 40) async throws -> Instantanea {
        async let r = resumen()
        async let p = pedimentos(limite: limitePedimentos)
        async let c = cartera()
        return Instantanea(resumen: try await r,
                           pedimentos: try await p,
                           cartera: try await c,
                           actualizada: Date())
    }
}

public enum CodificadorRyR {
    public static var decodificador: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let texto = try decoder.singleValueContainer().decode(String.self)
            if let fecha = FormatoFecha.iso.date(from: texto) { return fecha }
            if let fecha = FormatoFecha.isoFraccion.date(from: texto) { return fecha }
            if let fecha = FormatoFecha.soloDia.date(from: texto) { return fecha }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Fecha no reconocida: \(texto)")
            )
        }
        return d
    }

    public static var codificador: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { fecha, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(FormatoFecha.iso.string(from: fecha))
        }
        return e
    }
}
