import Foundation

/// Configuración de conexión. El reloj no la captura: la recibe del iPhone
/// por WatchConnectivity y la guarda en el grupo de aplicaciones.
public struct Ajustes: Codable, Equatable, Sendable {
    public var urlBase: String
    public var token: String
    public var modoDemo: Bool
    public var minutosRefresco: Int

    public init(urlBase: String = "", token: String = "", modoDemo: Bool = true, minutosRefresco: Int = 15) {
        self.urlBase = urlBase
        self.token = token
        self.modoDemo = modoDemo
        self.minutosRefresco = max(5, minutosRefresco)
    }

    public static let demo = Ajustes()

    /// Hay backend configurado y el usuario no pidió demo.
    public var usaBackend: Bool {
        !modoDemo && !urlBase.isEmpty && !token.isEmpty
    }
}

/// Almacén de ajustes compartido entre app, complicación y iPhone.
public final class AlmacenAjustes: @unchecked Sendable {
    public static let grupoApp = "group.ai.compliancehub.ryr.operativo"
    public static let shared = AlmacenAjustes()

    private let defaults: UserDefaults
    private let clave = "ajustes.v1"
    private let cola = DispatchQueue(label: "ryr.ajustes")

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: AlmacenAjustes.grupoApp) ?? .standard
    }

    public func leer() -> Ajustes {
        cola.sync {
            guard let datos = defaults.data(forKey: clave),
                  let ajustes = try? JSONDecoder().decode(Ajustes.self, from: datos) else {
                return Ajustes()
            }
            return ajustes
        }
    }

    public func guardar(_ ajustes: Ajustes) {
        cola.sync {
            guard let datos = try? JSONEncoder().encode(ajustes) else { return }
            defaults.set(datos, forKey: clave)
        }
    }

    /// Construye el cliente que corresponde a los ajustes vigentes.
    public func clienteVigente() -> ClienteAPI {
        let ajustes = leer()
        guard ajustes.usaBackend, let rest = ClienteAPIRest(ajustes: ajustes) else {
            return ClienteAPIDemo()
        }
        return rest
    }
}
