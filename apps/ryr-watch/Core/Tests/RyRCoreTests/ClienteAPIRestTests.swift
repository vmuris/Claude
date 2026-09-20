import XCTest
@testable import RyRCore

/// Intercepta las peticiones para probar el cliente REST sin servidor.
private final class ProtocoloFalso: URLProtocol {
    static var respuesta: (Int, Data) = (200, Data())
    static var ultimaPeticion: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.ultimaPeticion = request
        let (codigo, datos) = Self.respuesta
        let http = HTTPURLResponse(url: request.url!, statusCode: codigo,
                                   httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: datos)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class ClienteAPIRestTests: XCTestCase {

    private func cliente() -> ClienteAPIRest {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ProtocoloFalso.self]
        return ClienteAPIRest(base: URL(string: "https://api.ryr.test")!,
                              token: "token-de-prueba",
                              sesion: URLSession(configuration: config))
    }

    func testMandaElTokenYLaRutaCorrecta() async throws {
        ProtocoloFalso.respuesta = (200, Data("[]".utf8))
        _ = try await cliente().cartera()
        let peticion = try XCTUnwrap(ProtocoloFalso.ultimaPeticion)
        XCTAssertEqual(peticion.value(forHTTPHeaderField: "Authorization"), "Bearer token-de-prueba")
        XCTAssertEqual(peticion.url?.path, "/v1/cartera")
    }

    func testLimiteViajaComoParametro() async throws {
        ProtocoloFalso.respuesta = (200, Data("[]".utf8))
        _ = try await cliente().pedimentos(limite: 25)
        let url = try XCTUnwrap(ProtocoloFalso.ultimaPeticion?.url)
        XCTAssertEqual(url.query, "limite=25")
    }

    func testUn401SeTraduceANoAutorizado() async {
        ProtocoloFalso.respuesta = (401, Data())
        do {
            _ = try await cliente().cartera()
            XCTFail("Debió lanzar")
        } catch let error as ErrorAPI {
            XCTAssertEqual(error, .noAutorizado)
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
    }

    func testJSONInvalidoSeTraduceADecodificacion() async {
        ProtocoloFalso.respuesta = (200, Data("{no-json".utf8))
        do {
            _ = try await cliente().cartera()
            XCTFail("Debió lanzar")
        } catch let error as ErrorAPI {
            guard case .decodificacion = error else {
                return XCTFail("Se esperaba error de decodificación, llegó \(error)")
            }
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
    }
}
