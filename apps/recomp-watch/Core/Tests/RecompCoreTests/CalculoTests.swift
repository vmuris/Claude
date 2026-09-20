import XCTest
@testable import RecompCore

final class CalculoTests: XCTestCase {

    func testElPisoDeSeguridadNuncaSeCruza() {
        // Mujer pequeña, sedentaria, con un ajuste acumulado agresivo.
        var perfil = Perfil(sexo: .mujer, edad: 45, estaturaCm: 155, pesoKg: 52,
                            nivel: .sedentario, objetivo: .perderGrasa)
        perfil.ajusteAcumuladoKcal = -500
        let objetivos = Calculo.objetivos(perfil)
        XCTAssertGreaterThanOrEqual(Double(objetivos.energiaKcal), objetivos.piso - 0.5)
        XCTAssertTrue(objetivos.enElPiso)
        XCTAssertGreaterThanOrEqual(objetivos.energiaKcal, 1200)
    }

    func testLosMacrosSumanElObjetivoDeEnergia() {
        let perfil = Perfil(sexo: .hombre, edad: 38, estaturaCm: 178, pesoKg: 92)
        let o = Calculo.objetivos(perfil)
        let kcalDeMacros = o.proteinaG * 4 + o.grasaG * 9 + o.carbosG * 4
        // Redondeo de gramos: hasta 4 kcal de diferencia es aceptable.
        XCTAssertEqual(Double(kcalDeMacros), Double(o.energiaKcal), accuracy: 4)
    }

    func testBalanceUsaLaBasalMedidaCuandoExiste() {
        let perfil = Perfil()
        let tmb = Calculo.tmb(perfil)
        let conMedida = ResumenDia(fecha: Date(), energiaConsumida: 2000,
                                   energiaActiva: 500, energiaBasalMedida: 1700)
        XCTAssertEqual(Calculo.balance(conMedida, tmb: tmb), 2000 - 2200, accuracy: 0.001)

        let sinMedida = ResumenDia(fecha: Date(), energiaConsumida: 2000, energiaActiva: 500)
        XCTAssertEqual(Calculo.balance(sinMedida, tmb: tmb), 2000 - (tmb + 500), accuracy: 0.001)
    }

    func testMasDeficitNoEsMejor() {
        // Bajar demasiado rápido debe empujar las calorías hacia ARRIBA.
        let perfil = Perfil(sexo: .hombre, edad: 38, estaturaCm: 178, pesoKg: 92,
                            objetivo: .perderGrasa)
        let rapido = TendenciaPeso(pesoInicialKg: 92, pesoFinalKg: 90.4, dias: 7)
        let sugerido = Calculo.ajuste(perfil: perfil, tendencia: rapido)
        XCTAssertGreaterThan(sugerido.kcal, 0)
    }

    func testSinDiasSuficientesNoSeAjustaNada() {
        let perfil = Perfil()
        let corta = TendenciaPeso(pesoInicialKg: 92, pesoFinalKg: 90, dias: 4)
        XCTAssertEqual(Calculo.ajuste(perfil: perfil, tendencia: corta).kcal, 0)
    }

    func testElAjusteAcumuladoRespetaElTope() {
        var perfil = Perfil()
        perfil.ajusteAcumuladoKcal = -450
        let estancado = TendenciaPeso(pesoInicialKg: 92, pesoFinalKg: 92.2, dias: 14)
        let sugerido = Calculo.ajuste(perfil: perfil, tendencia: estancado)
        XCTAssertEqual(sugerido.kcal, -50, "Debe recortarse para no pasar de -500")

        let nuevo = Calculo.aplicar(sugerido, a: perfil)
        XCTAssertEqual(nuevo.ajusteAcumuladoKcal, -500, accuracy: 0.001)

        // Un segundo intento ya no puede bajar más.
        XCTAssertEqual(Calculo.ajuste(perfil: nuevo, tendencia: estancado).kcal, 0)
    }

    func testSemanaResumeAdherenciaYDeudaDeSueno() {
        let perfil = Perfil(sexo: .hombre, edad: 38, estaturaCm: 178, pesoKg: 92)
        let objetivos = Calculo.objetivos(perfil)
        let base = Date()
        let dias = (0..<7).map { i in
            ResumenDia(fecha: base.addingTimeInterval(Double(-i) * 86_400),
                       energiaConsumida: Double(objetivos.energiaKcal),
                       proteinaConsumida: Double(objetivos.proteinaG),
                       energiaActiva: 600,
                       horasSueno: 6.5,
                       minutosFuerza: i % 2 == 0 ? 45 : 0)
        }
        let semana = ResumenSemana.calcular(dias: dias, perfil: perfil, objetivos: objetivos)
        XCTAssertEqual(semana.dias, 7)
        XCTAssertEqual(semana.diasRegistrados, 7)
        XCTAssertEqual(semana.sesionesFuerza, 4)
        XCTAssertEqual(semana.deudaSuenoHoras, 7 * 1.0, accuracy: 0.001)
        XCTAssertEqual(semana.puntajePromedio, 30 + 30 + 15 + 15)
    }

    func testSemanaVaciaNoTruena() {
        let perfil = Perfil()
        let semana = ResumenSemana.calcular(dias: [], perfil: perfil,
                                            objetivos: Calculo.objetivos(perfil))
        XCTAssertEqual(semana.dias, 0)
        XCTAssertEqual(semana.puntajePromedio, 0)
        XCTAssertEqual(semana.kilosEquivalentes, 0, accuracy: 0.0001)
    }
}
