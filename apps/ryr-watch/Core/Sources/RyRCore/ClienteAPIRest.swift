import Foundation

/// Cliente REST contra el backend de RyR. Solo lee: no hay un solo método
/// que escriba en Darwin desde el reloj, a propósito.
public struct ClienteAPIRest: ClienteAPI {
    public let base: URL
    public let token: String
    private let sesion: URLSession

    public init(base: URL, token: String, sesion: URLSession = .shared) {
        self.base = base
        self.token = token
        self.sesion = sesion
    }

    /// Construye el cliente desde los ajustes. Devuelve nil si falta algo.
    public init?(ajustes: Ajustes) {
        guard !ajustes.urlBase.isEmpty, !ajustes.token.isEmpty,
              let url = URL(string: ajustes.urlBase) else { return nil }
        self.init(base: url, token: ajustes.token)
    }

    public func resumen() async throws -> ResumenDia {
        try await pedir("v1/resumen")
    }

    public func pedimentos(limite: Int) async throws -> [Pedimento] {
        try await pedir("v1/pedimentos", consulta: [URLQueryItem(name: "limite", value: String(limite))])
    }

    public func pedimento(id: String) async throws -> Pedimento {
        try await pedir("v1/pedimentos/\(id)")
    }

    public func cartera() async throws -> [ClienteCartera] {
        try await pedir("v1/cartera")
    }

    private func pedir<T: Decodable>(_ ruta: String, consulta: [URLQueryItem] = []) async throws -> T {
        guard var componentes = URLComponents(url: base.appendingPathComponent(ruta),
                                              resolvingAgainstBaseURL: false) else {
            throw ErrorAPI.urlInvalida
        }
        if !consulta.isEmpty { componentes.queryItems = consulta }
        guard let url = componentes.url else { throw ErrorAPI.urlInvalida }

        var peticion = URLRequest(url: url)
        peticion.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        peticion.setValue("application/json", forHTTPHeaderField: "Accept")
        peticion.timeoutInterval = 15

        let datos: Data
        let respuesta: URLResponse
        do {
            (datos, respuesta) = try await sesion.data(for: peticion)
        } catch {
            throw ErrorAPI.red(error.localizedDescription)
        }

        guard let http = respuesta as? HTTPURLResponse else { throw ErrorAPI.respuestaInvalida(0) }
        if http.statusCode == 401 || http.statusCode == 403 { throw ErrorAPI.noAutorizado }
        guard (200..<300).contains(http.statusCode) else {
            throw ErrorAPI.respuestaInvalida(http.statusCode)
        }

        do {
            return try CodificadorRyR.decodificador.decode(T.self, from: datos)
        } catch {
            throw ErrorAPI.decodificacion(String(describing: error))
        }
    }
}
