import Foundation
import WatchConnectivity
import RyRCore

/// Puente iPhone ↔︎ reloj. El token nunca se teclea en el reloj: se captura
/// en el iPhone y viaja por el canal cifrado de WatchConnectivity.
public final class PuenteConectividad: NSObject, ObservableObject {
    public static let shared = PuenteConectividad()

    /// Se dispara en el reloj cuando llegan ajustes nuevos.
    public static let ajustesRecibidos = Notification.Name("ryr.ajustesRecibidos")

    @Published public private(set) var alcanzable = false
    @Published public private(set) var ultimoEnvio: Date?

    private let almacen: AlmacenAjustes

    public init(almacen: AlmacenAjustes = .shared) {
        self.almacen = almacen
        super.init()
    }

    public func activar() {
        guard WCSession.isSupported() else { return }
        let sesion = WCSession.default
        sesion.delegate = self
        sesion.activate()
    }

    /// iPhone: publica los ajustes vigentes hacia el reloj.
    @discardableResult
    public func enviar(_ ajustes: Ajustes) -> Bool {
        guard WCSession.isSupported() else { return false }
        let sesion = WCSession.default
        guard sesion.activationState == .activated else { return false }
        do {
            try sesion.updateApplicationContext(Self.diccionario(de: ajustes))
            DispatchQueue.main.async { self.ultimoEnvio = Date() }
            return true
        } catch {
            return false
        }
    }

    static func diccionario(de ajustes: Ajustes) -> [String: Any] {
        [
            "urlBase": ajustes.urlBase,
            "token": ajustes.token,
            "modoDemo": ajustes.modoDemo,
            "minutosRefresco": ajustes.minutosRefresco
        ]
    }

    static func ajustes(desde contexto: [String: Any]) -> Ajustes? {
        guard let urlBase = contexto["urlBase"] as? String,
              let token = contexto["token"] as? String else { return nil }
        return Ajustes(urlBase: urlBase,
                       token: token,
                       modoDemo: contexto["modoDemo"] as? Bool ?? false,
                       minutosRefresco: contexto["minutosRefresco"] as? Int ?? 15)
    }

    private func aplicar(_ contexto: [String: Any]) {
        guard let ajustes = Self.ajustes(desde: contexto) else { return }
        almacen.guardar(ajustes)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.ajustesRecibidos, object: ajustes)
        }
    }
}

extension PuenteConectividad: WCSessionDelegate {
    public func session(_ session: WCSession,
                        activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        DispatchQueue.main.async { self.alcanzable = session.isReachable }
        if !session.receivedApplicationContext.isEmpty {
            aplicar(session.receivedApplicationContext)
        }
    }

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        aplicar(applicationContext)
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.alcanzable = session.isReachable }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
