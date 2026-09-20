import Foundation

/// Perfil y estado del plan, compartidos entre la app y la complicación.
public final class AlmacenPerfil: @unchecked Sendable {
    public static let grupoApp = "group.ai.compliancehub.recomp"
    public static let shared = AlmacenPerfil()

    private let defaults: UserDefaults
    private let clavePerfil = "perfil.v1"
    private let claveInstantanea = "instantanea.v1"
    private let claveUltimoAjuste = "ultimoAjuste.v1"
    private let cola = DispatchQueue(label: "recomp.almacen")

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: AlmacenPerfil.grupoApp) ?? .standard
    }

    public var configurado: Bool {
        cola.sync { defaults.data(forKey: clavePerfil) != nil }
    }

    public func leerPerfil() -> Perfil {
        cola.sync {
            guard let datos = defaults.data(forKey: clavePerfil),
                  let perfil = try? JSONDecoder().decode(Perfil.self, from: datos) else {
                return Perfil()
            }
            return perfil
        }
    }

    public func guardar(_ perfil: Perfil) {
        cola.sync {
            guard let datos = try? JSONEncoder().encode(perfil) else { return }
            defaults.set(datos, forKey: clavePerfil)
        }
    }

    /// Foto mínima del día para que la complicación no tenga que tocar Salud.
    public func leerInstantanea() -> InstantaneaDia? {
        cola.sync {
            guard let datos = defaults.data(forKey: claveInstantanea) else { return nil }
            return try? JSONDecoder().decode(InstantaneaDia.self, from: datos)
        }
    }

    public func guardar(_ instantanea: InstantaneaDia) {
        cola.sync {
            guard let datos = try? JSONEncoder().encode(instantanea) else { return }
            defaults.set(datos, forKey: claveInstantanea)
        }
    }

    public func fechaUltimoAjuste() -> Date? {
        cola.sync { defaults.object(forKey: claveUltimoAjuste) as? Date }
    }

    public func registrarAjuste(_ fecha: Date = Date()) {
        cola.sync { defaults.set(fecha, forKey: claveUltimoAjuste) }
    }
}

public struct InstantaneaDia: Codable, Equatable, Sendable {
    public let kcalRestantes: Int
    public let proteinaRestanteG: Int
    public let objetivoKcal: Int
    public let objetivoProteinaG: Int
    public let puntaje: Int
    public let horasSueno: Double
    public let actualizada: Date

    public init(kcalRestantes: Int, proteinaRestanteG: Int, objetivoKcal: Int,
                objetivoProteinaG: Int, puntaje: Int, horasSueno: Double, actualizada: Date) {
        self.kcalRestantes = kcalRestantes
        self.proteinaRestanteG = proteinaRestanteG
        self.objetivoKcal = objetivoKcal
        self.objetivoProteinaG = objetivoProteinaG
        self.puntaje = puntaje
        self.horasSueno = horasSueno
        self.actualizada = actualizada
    }

    public var proporcionEnergia: Double {
        guard objetivoKcal > 0 else { return 0 }
        let consumido = Double(objetivoKcal - kcalRestantes)
        return min(max(consumido / Double(objetivoKcal), 0), 1)
    }

    public static let vacia = InstantaneaDia(kcalRestantes: 0, proteinaRestanteG: 0,
                                             objetivoKcal: 0, objetivoProteinaG: 0,
                                             puntaje: 0, horasSueno: 0,
                                             actualizada: Date(timeIntervalSince1970: 0))
}
