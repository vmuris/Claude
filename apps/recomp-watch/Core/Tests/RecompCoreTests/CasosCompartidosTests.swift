import XCTest
@testable import RecompCore

/// Las mismas cuentas que verifica tools/verificar_formulas.py, corridas
/// contra la implementación de Swift. Si Swift y la referencia en Python se
/// separan, estas pruebas lo dicen.
final class CasosCompartidosTests: XCTestCase {

    struct Banco: Decodable {
        let objetivos: [CasoObjetivos]
        let puntajes: [CasoPuntaje]
        let ajustes: [CasoAjuste]
    }

    struct CasoObjetivos: Decodable {
        let nombre: String
        let perfil: Perfil
        let esperado: ObjetivosEsperados
    }

    struct ObjetivosEsperados: Decodable {
        let tmb: Double
        let gastoEstimado: Double
        let piso: Double
        let energiaKcal: Int
        let proteinaG: Int
        let grasaG: Int
        let carbosG: Int
    }

    struct DiaCaso: Decodable {
        let energiaConsumida: Double
        let proteinaConsumida: Double
        let energiaActiva: Double
        let energiaBasalMedida: Double
        let horasSueno: Double

        var resumen: ResumenDia {
            ResumenDia(fecha: Date(timeIntervalSince1970: 0),
                       energiaConsumida: energiaConsumida,
                       proteinaConsumida: proteinaConsumida,
                       energiaActiva: energiaActiva,
                       energiaBasalMedida: energiaBasalMedida,
                       horasSueno: horasSueno)
        }
    }

    struct CasoPuntaje: Decodable {
        let nombre: String
        let perfil: Perfil
        let dia: DiaCaso
        let esperado: PuntajeEsperado
    }

    struct PuntajeEsperado: Decodable {
        let energia: Int
        let proteina: Int
        let sueno: Int
        let movimiento: Int
        let total: Int
    }

    struct CasoAjuste: Decodable {
        let nombre: String
        let perfil: Perfil
        let tendencia: TendenciaPeso
        let cambioSemanalPorcentaje: Double
        let esperado: Int
    }

    private func banco() throws -> Banco {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "casos_formulas", withExtension: "json"),
                                "Falta el banco de casos en los recursos de prueba")
        return try JSONDecoder().decode(Banco.self, from: Data(contentsOf: url))
    }

    func testObjetivosCoincidenConLaReferencia() throws {
        for caso in try banco().objetivos {
            let obtenido = Calculo.objetivos(caso.perfil)
            XCTAssertEqual(obtenido.tmb, caso.esperado.tmb, accuracy: 0.01, caso.nombre)
            XCTAssertEqual(obtenido.gastoEstimado, caso.esperado.gastoEstimado, accuracy: 0.01, caso.nombre)
            XCTAssertEqual(obtenido.piso, caso.esperado.piso, accuracy: 0.01, caso.nombre)
            XCTAssertEqual(obtenido.energiaKcal, caso.esperado.energiaKcal, caso.nombre)
            XCTAssertEqual(obtenido.proteinaG, caso.esperado.proteinaG, caso.nombre)
            XCTAssertEqual(obtenido.grasaG, caso.esperado.grasaG, caso.nombre)
            XCTAssertEqual(obtenido.carbosG, caso.esperado.carbosG, caso.nombre)
        }
    }

    func testPuntajesCoincidenConLaReferencia() throws {
        for caso in try banco().puntajes {
            let objetivos = Calculo.objetivos(caso.perfil)
            let obtenido = Calculo.puntaje(dia: caso.dia.resumen, objetivos: objetivos, perfil: caso.perfil)
            XCTAssertEqual(obtenido.energia, caso.esperado.energia, caso.nombre)
            XCTAssertEqual(obtenido.proteina, caso.esperado.proteina, caso.nombre)
            XCTAssertEqual(obtenido.sueno, caso.esperado.sueno, caso.nombre)
            XCTAssertEqual(obtenido.movimiento, caso.esperado.movimiento, caso.nombre)
            XCTAssertEqual(obtenido.total, caso.esperado.total, caso.nombre)
        }
    }

    func testAjustesCoincidenConLaReferencia() throws {
        for caso in try banco().ajustes {
            XCTAssertEqual(caso.tendencia.cambioSemanalPorcentaje,
                           caso.cambioSemanalPorcentaje, accuracy: 0.0001, caso.nombre)
            let obtenido = Calculo.ajuste(perfil: caso.perfil, tendencia: caso.tendencia)
            XCTAssertEqual(obtenido.kcal, caso.esperado, caso.nombre)
            XCTAssertFalse(obtenido.razon.isEmpty, caso.nombre)
        }
    }
}
