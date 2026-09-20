import Foundation

/// Toda la aritmética del plan vive aquí, sin dependencias de interfaz ni de
/// HealthKit, para que se pueda probar sola.
///
/// Aviso: son fórmulas y rangos de uso común en nutrición deportiva, no
/// consejo médico. Nadie con una condición de salud debería seguirlas sin
/// revisarlas con su médico.
public enum Calculo {

    public static let pasoAjusteKcal: Double = 150
    public static let topeAjusteAcumuladoKcal: Double = 500
    public static let diasMinimosParaAjustar = 7

    /// Tasa metabólica basal, ecuación de Mifflin-St Jeor (1990).
    public static func tmb(_ perfil: Perfil) -> Double {
        let base = 10 * perfil.pesoKg + 6.25 * perfil.estaturaCm - 5 * Double(perfil.edad)
        return perfil.sexo == .hombre ? base + 5 : base - 161
    }

    public static func gastoEstimado(_ perfil: Perfil) -> Double {
        tmb(perfil) * perfil.nivel.factor
    }

    /// Mínimo de seguridad. Por debajo de esto no se baja el objetivo por más
    /// que la tendencia lo pida.
    public static func piso(_ perfil: Perfil) -> Double {
        max(tmb(perfil) * 1.1, perfil.sexo == .hombre ? 1500 : 1200)
    }

    public static func objetivos(_ perfil: Perfil) -> Objetivos {
        let tmbValor = tmb(perfil)
        let gasto = tmbValor * perfil.nivel.factor
        let pisoValor = max(tmbValor * 1.1, perfil.sexo == .hombre ? 1500 : 1200)
        let bruto = gasto * (1 + perfil.objetivo.ajusteEnergia) + perfil.ajusteAcumuladoKcal
        let energia = Int((max(bruto, pisoValor)).rounded())
        let proteina = Int((perfil.pesoKg * perfil.objetivo.proteinaPorKg).rounded())
        let grasa = Int((perfil.pesoKg * 0.8).rounded())
        let restante = Double(energia) - Double(proteina) * 4 - Double(grasa) * 9
        let carbos = max(0, Int((restante / 4).rounded()))
        return Objetivos(tmb: tmbValor, gastoEstimado: gasto, energiaKcal: energia,
                         proteinaG: proteina, grasaG: grasa, carbosG: carbos, piso: pisoValor)
    }

    /// Gasto real del día: basal (medido si el reloj lo dio, si no la TMB)
    /// más la energía activa que midió el reloj.
    public static func gastoMedido(_ dia: ResumenDia, tmb: Double) -> Double {
        let basal = dia.energiaBasalMedida > 0 ? dia.energiaBasalMedida : tmb
        return basal + dia.energiaActiva
    }

    /// Balance del día. Negativo es déficit.
    public static func balance(_ dia: ResumenDia, tmb: Double) -> Double {
        dia.energiaConsumida - gastoMedido(dia, tmb: tmb)
    }

    public static func puntaje(dia: ResumenDia, objetivos: Objetivos, perfil: Perfil) -> Puntaje {
        Puntaje(energia: puntosEnergia(dia.energiaConsumida, objetivo: Double(objetivos.energiaKcal)),
                proteina: puntosProteina(dia.proteinaConsumida, objetivo: Double(objetivos.proteinaG)),
                sueno: puntosSueno(dia.horasSueno, meta: perfil.horasSuenoObjetivo),
                movimiento: puntosMovimiento(dia.energiaActiva, meta: perfil.metaEnergiaActiva))
    }

    static func puntosEnergia(_ consumida: Double, objetivo: Double) -> Int {
        guard consumida > 0, objetivo > 0 else { return 0 }
        let desvio = abs(consumida - objetivo) / objetivo
        if desvio <= 0.10 { return 30 }
        if desvio <= 0.20 { return 15 }
        return 0
    }

    static func puntosProteina(_ consumida: Double, objetivo: Double) -> Int {
        guard objetivo > 0 else { return 0 }
        let razon = consumida / objetivo
        if razon >= 1.0 { return 30 }
        if razon >= 0.9 { return 20 }
        if razon >= 0.75 { return 10 }
        return 0
    }

    static func puntosSueno(_ horas: Double, meta: Double) -> Int {
        if horas >= meta { return 25 }
        if horas >= meta - 1 { return 15 }
        if horas >= meta - 2 { return 5 }
        return 0
    }

    static func puntosMovimiento(_ activa: Double, meta: Double) -> Int {
        guard meta > 0 else { return 0 }
        let razon = activa / meta
        if razon >= 1.0 { return 15 }
        if razon >= 0.6 { return 8 }
        return 0
    }

    /// El corazón del plan: la báscula manda, no la estimación del reloj.
    public static func ajuste(perfil: Perfil, tendencia: TendenciaPeso) -> AjusteSugerido {
        guard tendencia.dias >= diasMinimosParaAjustar else {
            return AjusteSugerido(kcal: 0, razon: "Faltan días de peso para decidir.")
        }
        let cambio = tendencia.cambioSemanalPorcentaje
        let rango = perfil.objetivo.cambioSemanalObjetivo
        let texto = String(format: "%.2f%%/sem", cambio)

        var propuesta: Double = 0
        var razon: String

        if cambio > rango.upperBound {
            propuesta = -pasoAjusteKcal
            razon = perfil.objetivo == .ganarMusculo
                ? "Subes \(texto): demasiado rápido, baja calorías."
                : "Cambio \(texto): el déficit no está sirviendo, baja calorías."
        } else if cambio < rango.lowerBound {
            propuesta = pasoAjusteKcal
            razon = perfil.objetivo == .ganarMusculo
                ? "Subes \(texto): muy lento, sube calorías."
                : "Bajas \(texto): demasiado rápido, sube calorías para cuidar músculo."
        } else {
            return AjusteSugerido(kcal: 0, razon: "Cambio \(texto): dentro del rango, no toques nada.")
        }

        // El ajuste acumulado tiene tope: si se pasa, se recorta.
        let acumulado = perfil.ajusteAcumuladoKcal + propuesta
        if abs(acumulado) > topeAjusteAcumuladoKcal {
            let permitido = (acumulado > 0 ? topeAjusteAcumuladoKcal : -topeAjusteAcumuladoKcal)
                - perfil.ajusteAcumuladoKcal
            if abs(permitido) < 1 {
                return AjusteSugerido(kcal: 0, razon: "Tope de ajuste alcanzado: revisa el perfil.")
            }
            propuesta = permitido
            razon += " Recortado por el tope."
        }

        return AjusteSugerido(kcal: Int(propuesta.rounded()), razon: razon)
    }

    public static func aplicar(_ ajuste: AjusteSugerido, a perfil: Perfil) -> Perfil {
        var copia = perfil
        let nuevo = perfil.ajusteAcumuladoKcal + Double(ajuste.kcal)
        copia.ajusteAcumuladoKcal = min(max(nuevo, -topeAjusteAcumuladoKcal), topeAjusteAcumuladoKcal)
        return copia
    }
}

/// Cierre de la semana: lo que hay que mirar el domingo.
public struct ResumenSemana: Equatable, Sendable {
    public let dias: Int
    public let puntajePromedio: Int
    public let deudaSuenoHoras: Double
    public let sesionesFuerza: Int
    public let balanceAcumulado: Double
    public let diasRegistrados: Int

    public init(dias: Int, puntajePromedio: Int, deudaSuenoHoras: Double,
                sesionesFuerza: Int, balanceAcumulado: Double, diasRegistrados: Int) {
        self.dias = dias
        self.puntajePromedio = puntajePromedio
        self.deudaSuenoHoras = deudaSuenoHoras
        self.sesionesFuerza = sesionesFuerza
        self.balanceAcumulado = balanceAcumulado
        self.diasRegistrados = diasRegistrados
    }

    /// Grasa perdida o ganada que explica el balance, a 7700 kcal por kilo.
    public var kilosEquivalentes: Double {
        balanceAcumulado / 7700
    }

    public static func calcular(dias: [ResumenDia], perfil: Perfil, objetivos: Objetivos) -> ResumenSemana {
        guard !dias.isEmpty else {
            return ResumenSemana(dias: 0, puntajePromedio: 0, deudaSuenoHoras: 0,
                                 sesionesFuerza: 0, balanceAcumulado: 0, diasRegistrados: 0)
        }
        let puntajes = dias.map { Calculo.puntaje(dia: $0, objetivos: objetivos, perfil: perfil).total }
        let deuda = dias.reduce(0.0) { $0 + max(0, perfil.horasSuenoObjetivo - $1.horasSueno) }
        let fuerza = dias.filter { $0.minutosFuerza >= 20 }.count
        let balance = dias.reduce(0.0) { $0 + Calculo.balance($1, tmb: objetivos.tmb) }
        let registrados = dias.filter { $0.energiaConsumida > 0 }.count
        return ResumenSemana(dias: dias.count,
                             puntajePromedio: Int((Double(puntajes.reduce(0, +)) / Double(dias.count)).rounded()),
                             deudaSuenoHoras: deuda,
                             sesionesFuerza: fuerza,
                             balanceAcumulado: balance,
                             diasRegistrados: registrados)
    }
}
