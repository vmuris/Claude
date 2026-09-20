import XCTest
@testable import RecompCore

@MainActor
final class DiarioStoreTests: XCTestCase {

    private func almacenLimpio() -> AlmacenPerfil {
        AlmacenPerfil(defaults: UserDefaults(suiteName: "pruebas.\(UUID().uuidString)")!)
    }

    private func store(_ almacen: AlmacenPerfil? = nil) -> DiarioStore {
        DiarioStore(salud: FuenteSaludDemo(), almacen: almacen ?? almacenLimpio())
    }

    func testCargarLlenaSemanaYDejaEstadoListo() async {
        let s = store()
        await s.cargar()
        XCTAssertEqual(s.estado, .listo)
        XCTAssertEqual(s.semana.count, 7)
        XCTAssertGreaterThan(s.hoy.energiaConsumida, 0)
    }

    func testRegistrarComidaSubeElConsumoYBajaLoRestante() async {
        let s = store()
        await s.cargar()
        let antes = s.kcalRestantes
        await s.registrarComida(kcal: 400, proteinaG: 35)
        XCTAssertEqual(s.kcalRestantes, antes - 400, accuracy: 2)
    }

    func testGuardarPerfilRecalculaObjetivos() {
        let s = store()
        let original = s.objetivos.energiaKcal
        var perfil = s.perfil
        perfil.objetivo = .perderGrasa
        s.guardar(perfil)
        XCTAssertLessThan(s.objetivos.energiaKcal, original,
                          "Perder grasa debe pedir menos calorías que recomposición")
    }

    func testAceptarAjusteMueveElAcumuladoUnaSolaVezPorSemana() async {
        let almacen = almacenLimpio()
        var perfil = Perfil(sexo: .hombre, edad: 38, estaturaCm: 178, pesoKg: 92)
        perfil.ajusteAcumuladoKcal = 0
        almacen.guardar(perfil)

        let s = DiarioStore(salud: FuenteSaludDemo(), almacen: almacen)
        await s.cargar()

        if let pendiente = s.ajustePendiente {
            s.aceptarAjuste()
            XCTAssertEqual(s.perfil.ajusteAcumuladoKcal, Double(pendiente.kcal), accuracy: 0.001)
            XCTAssertNil(s.ajustePendiente)
        }

        // Ya se ajustó hoy: aunque se recargue, no debe volver a proponer.
        await s.cargar()
        XCTAssertNil(s.ajustePendiente)
    }

    func testLaInstantaneaQuedaGuardadaParaLaComplicacion() async {
        let almacen = almacenLimpio()
        let s = DiarioStore(salud: FuenteSaludDemo(), almacen: almacen)
        await s.cargar()
        let instantanea = almacen.leerInstantanea()
        XCTAssertNotNil(instantanea)
        XCTAssertEqual(instantanea?.objetivoKcal, s.objetivos.energiaKcal)
        XCTAssertEqual(instantanea?.kcalRestantes, s.kcalRestantes)
    }
}

private func XCTAssertEqual(_ a: Int, _ b: Int, accuracy: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(abs(a - b) <= accuracy, "\(a) contra \(b) fuera de \(accuracy)",
                  file: file, line: line)
}
