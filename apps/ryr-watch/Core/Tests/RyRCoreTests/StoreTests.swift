import XCTest
@testable import RyRCore

/// Cliente falso controlable: sirve para probar el store sin red.
private struct ClienteFalso: ClienteAPI {
    var instantaneaFija: Instantanea = ClienteAPIDemo.datos
    var fallar: ErrorAPI?

    func resumen() async throws -> ResumenDia {
        if let fallar { throw fallar }
        return instantaneaFija.resumen
    }
    func pedimentos(limite: Int) async throws -> [Pedimento] {
        if let fallar { throw fallar }
        return instantaneaFija.pedimentos
    }
    func pedimento(id: String) async throws -> Pedimento {
        if let fallar { throw fallar }
        guard let p = instantaneaFija.pedimentos.first(where: { $0.id == id }) else {
            throw ErrorAPI.respuestaInvalida(404)
        }
        return p
    }
    func cartera() async throws -> [ClienteCartera] {
        if let fallar { throw fallar }
        return instantaneaFija.cartera
    }
}

@MainActor
final class StoreTests: XCTestCase {

    private func almacenLimpio() -> AlmacenAjustes {
        let suite = "pruebas.\(UUID().uuidString)"
        return AlmacenAjustes(defaults: UserDefaults(suiteName: suite)!)
    }

    private func cacheTemporal() -> CacheInstantanea {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("instantanea-\(UUID().uuidString).json")
        return CacheInstantanea(archivo: url)
    }

    func testRefrescarLlenaLaInstantaneaYDejaEstadoListo() async {
        let store = OperacionesStore(cache: cacheTemporal(), almacen: almacenLimpio()) { _ in ClienteFalso() }
        await store.refrescar()
        XCTAssertEqual(store.estado, .listo)
        XCTAssertEqual(store.instantanea.pedimentos.count, ClienteAPIDemo.datos.pedimentos.count)
        XCTAssertTrue(store.hayDatos)
    }

    func testErrorDeRedDejaMensajeLegible() async {
        let store = OperacionesStore(cache: cacheTemporal(), almacen: almacenLimpio()) { _ in
            ClienteFalso(fallar: .noAutorizado)
        }
        await store.refrescar()
        XCTAssertTrue(store.estado.esError)
        XCTAssertEqual(store.estado.mensaje, ErrorAPI.noAutorizado.errorDescription)
    }

    func testLaCacheSobreviveAUnStoreNuevo() async {
        let cache = cacheTemporal()
        let store = OperacionesStore(cache: cache, almacen: almacenLimpio()) { _ in ClienteFalso() }
        await store.refrescar()

        let otro = OperacionesStore(cache: cache, almacen: almacenLimpio()) { _ in
            ClienteFalso(fallar: .red("sin señal"))
        }
        XCTAssertTrue(otro.hayDatos, "La app debe abrir con el último dato conocido")
        await otro.refrescar()
        XCTAssertTrue(otro.estado.esError)
        XCTAssertEqual(otro.instantanea.pedimentos.count, ClienteAPIDemo.datos.pedimentos.count,
                       "Un error de red no debe borrar lo que ya se mostraba")
    }

    func testPendientesPrioriizaDetenidos() async {
        let store = OperacionesStore(cache: cacheTemporal(), almacen: almacenLimpio()) { _ in ClienteFalso() }
        await store.refrescar()
        let pendientes = store.pendientes
        XCTAssertEqual(pendientes.first?.estatus, .detenido)
        XCTAssertTrue(pendientes.allSatisfy { $0.estatus.requiereAtencion || ($0.cruzo && !$0.facturado) })
    }

    func testAjustesSinBackendCaenEnModoDemo() {
        let ajustes = Ajustes(urlBase: "", token: "", modoDemo: false)
        XCTAssertFalse(ajustes.usaBackend)
        XCTAssertNil(ClienteAPIRest(ajustes: ajustes))
    }

    func testAjustesCompletosUsanBackend() {
        let ajustes = Ajustes(urlBase: "https://api.ryr.test", token: "abc", modoDemo: false)
        XCTAssertTrue(ajustes.usaBackend)
        XCTAssertNotNil(ClienteAPIRest(ajustes: ajustes))
    }
}
