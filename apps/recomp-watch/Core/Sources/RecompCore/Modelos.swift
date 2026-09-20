import Foundation

public enum Sexo: String, Codable, CaseIterable, Sendable {
    case hombre
    case mujer

    public var etiqueta: String {
        self == .hombre ? "Hombre" : "Mujer"
    }
}

public enum NivelActividad: String, Codable, CaseIterable, Sendable {
    case sedentario
    case ligero
    case moderado
    case alto
    case muyAlto

    /// Factores clásicos de Harris-Benedict sobre la TMB.
    public var factor: Double {
        switch self {
        case .sedentario: return 1.2
        case .ligero: return 1.375
        case .moderado: return 1.55
        case .alto: return 1.725
        case .muyAlto: return 1.9
        }
    }

    public var etiqueta: String {
        switch self {
        case .sedentario: return "Sedentario"
        case .ligero: return "Ligero"
        case .moderado: return "Moderado"
        case .alto: return "Alto"
        case .muyAlto: return "Muy alto"
        }
    }
}

public enum Objetivo: String, Codable, CaseIterable, Sendable {
    case perderGrasa
    case recomposicion
    case ganarMusculo

    public var etiqueta: String {
        switch self {
        case .perderGrasa: return "Perder grasa"
        case .recomposicion: return "Recomposición"
        case .ganarMusculo: return "Ganar músculo"
        }
    }

    /// Ajuste sobre el gasto estimado: negativo es déficit.
    public var ajusteEnergia: Double {
        switch self {
        case .perderGrasa: return -0.20
        case .recomposicion: return -0.12
        case .ganarMusculo: return 0.10
        }
    }

    /// Gramos de proteína por kilo de peso corporal.
    public var proteinaPorKg: Double {
        switch self {
        case .perderGrasa: return 2.2
        case .recomposicion: return 2.0
        case .ganarMusculo: return 1.8
        }
    }

    /// Cambio de peso semanal deseado, en porcentaje del peso corporal.
    /// Fuera de este rango se pierde músculo o se gana grasa de más.
    public var cambioSemanalObjetivo: ClosedRange<Double> {
        switch self {
        case .perderGrasa: return -1.0...(-0.5)
        case .recomposicion: return -0.75...(-0.25)
        case .ganarMusculo: return 0.125...0.5
        }
    }
}

public struct Perfil: Codable, Equatable, Sendable {
    public var sexo: Sexo
    public var edad: Int
    public var estaturaCm: Double
    public var pesoKg: Double
    public var nivel: NivelActividad
    public var objetivo: Objetivo
    public var horasSuenoObjetivo: Double
    public var metaEnergiaActiva: Double
    /// Corrección acumulada que aplica el ajuste semanal por tendencia.
    public var ajusteAcumuladoKcal: Double

    public init(sexo: Sexo = .hombre,
                edad: Int = 35,
                estaturaCm: Double = 175,
                pesoKg: Double = 80,
                nivel: NivelActividad = .moderado,
                objetivo: Objetivo = .recomposicion,
                horasSuenoObjetivo: Double = 7.5,
                metaEnergiaActiva: Double = 500,
                ajusteAcumuladoKcal: Double = 0) {
        self.sexo = sexo
        self.edad = edad
        self.estaturaCm = estaturaCm
        self.pesoKg = pesoKg
        self.nivel = nivel
        self.objetivo = objetivo
        self.horasSuenoObjetivo = horasSuenoObjetivo
        self.metaEnergiaActiva = metaEnergiaActiva
        self.ajusteAcumuladoKcal = ajusteAcumuladoKcal
    }
}

/// Objetivos del día, ya calculados.
public struct Objetivos: Codable, Equatable, Sendable {
    public let tmb: Double
    public let gastoEstimado: Double
    public let energiaKcal: Int
    public let proteinaG: Int
    public let grasaG: Int
    public let carbosG: Int
    public let piso: Double

    public init(tmb: Double, gastoEstimado: Double, energiaKcal: Int,
                proteinaG: Int, grasaG: Int, carbosG: Int, piso: Double) {
        self.tmb = tmb
        self.gastoEstimado = gastoEstimado
        self.energiaKcal = energiaKcal
        self.proteinaG = proteinaG
        self.grasaG = grasaG
        self.carbosG = carbosG
        self.piso = piso
    }

    /// El objetivo topó con el mínimo de seguridad: no se puede bajar más.
    public var enElPiso: Bool {
        Double(energiaKcal) <= piso + 0.5
    }
}

/// Lo que de verdad pasó hoy: lo que registraste y lo que midió el reloj.
public struct ResumenDia: Codable, Equatable, Sendable, Identifiable {
    public var fecha: Date
    public var energiaConsumida: Double
    public var proteinaConsumida: Double
    public var energiaActiva: Double
    public var energiaBasalMedida: Double
    public var horasSueno: Double
    public var minutosFuerza: Double
    public var minutosCardio: Double
    public var pesoKg: Double?

    public var id: Date { fecha }

    public init(fecha: Date,
                energiaConsumida: Double = 0,
                proteinaConsumida: Double = 0,
                energiaActiva: Double = 0,
                energiaBasalMedida: Double = 0,
                horasSueno: Double = 0,
                minutosFuerza: Double = 0,
                minutosCardio: Double = 0,
                pesoKg: Double? = nil) {
        self.fecha = fecha
        self.energiaConsumida = energiaConsumida
        self.proteinaConsumida = proteinaConsumida
        self.energiaActiva = energiaActiva
        self.energiaBasalMedida = energiaBasalMedida
        self.horasSueno = horasSueno
        self.minutosFuerza = minutosFuerza
        self.minutosCardio = minutosCardio
        self.pesoKg = pesoKg
    }

    public var entreno: Bool {
        minutosFuerza + minutosCardio >= 15
    }
}

public struct Puntaje: Codable, Equatable, Sendable {
    public let energia: Int
    public let proteina: Int
    public let sueno: Int
    public let movimiento: Int

    public init(energia: Int, proteina: Int, sueno: Int, movimiento: Int) {
        self.energia = energia
        self.proteina = proteina
        self.sueno = sueno
        self.movimiento = movimiento
    }

    public var total: Int { energia + proteina + sueno + movimiento }

    public var veredicto: String {
        switch total {
        case 85...: return "Día redondo"
        case 65..<85: return "Vas bien"
        case 40..<65: return "A medias"
        default: return "Día perdido"
        }
    }
}

public struct TendenciaPeso: Codable, Equatable, Sendable {
    public let pesoInicialKg: Double
    public let pesoFinalKg: Double
    public let dias: Int

    public init(pesoInicialKg: Double, pesoFinalKg: Double, dias: Int) {
        self.pesoInicialKg = pesoInicialKg
        self.pesoFinalKg = pesoFinalKg
        self.dias = dias
    }

    /// Cambio en porcentaje del peso corporal, llevado a semana.
    public var cambioSemanalPorcentaje: Double {
        guard dias > 0, pesoInicialKg > 0 else { return 0 }
        let cambio = (pesoFinalKg - pesoInicialKg) / pesoInicialKg * 100
        return cambio * (7.0 / Double(dias))
    }
}

public struct AjusteSugerido: Codable, Equatable, Sendable {
    public let kcal: Int
    public let razon: String

    public init(kcal: Int, razon: String) {
        self.kcal = kcal
        self.razon = razon
    }

    public var hayCambio: Bool { kcal != 0 }
}
