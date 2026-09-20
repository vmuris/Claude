import Foundation
import Combine

/// Estado de carga que consume la interfaz.
public enum EstadoCarga: Equatable, Sendable {
    case inicial
    case cargando
    case listo
    case error(String)

    public var esError: Bool {
        if case .error = self { return true }
        return false
    }

    public var mensaje: String? {
        if case .error(let m) = self { return m }
        return nil
    }
}

/// Fuente única de verdad de la app. Arranca con lo que haya en caché para
/// que la pantalla nunca aparezca vacía, y luego refresca contra el backend.
@MainActor
public final class OperacionesStore: ObservableObject {
    @Published public private(set) var instantanea: Instantanea
    @Published public private(set) var estado: EstadoCarga = .inicial
    @Published public private(set) var ajustes: Ajustes

    private let cache: CacheInstantanea
    private let almacen: AlmacenAjustes
    private var fabricaCliente: (Ajustes) -> ClienteAPI

    public init(cache: CacheInstantanea = .shared,
                almacen: AlmacenAjustes = .shared,
                fabricaCliente: ((Ajustes) -> ClienteAPI)? = nil) {
        self.cache = cache
        self.almacen = almacen
        self.ajustes = almacen.leer()
        self.instantanea = cache.leer() ?? .vacia
        self.fabricaCliente = fabricaCliente ?? { ajustes in
            guard ajustes.usaBackend, let rest = ClienteAPIRest(ajustes: ajustes) else {
                return ClienteAPIDemo()
            }
            return rest
        }
        if self.instantanea.actualizada > Date(timeIntervalSince1970: 0) {
            self.estado = .listo
        }
    }

    public var hayDatos: Bool {
        instantanea.actualizada > Date(timeIntervalSince1970: 0)
    }

    /// Pedimentos que piden acción: detenidos primero, luego cruzados sin facturar.
    public var pendientes: [Pedimento] {
        instantanea.pedimentos
            .filter { $0.estatus.requiereAtencion || ($0.cruzo && !$0.facturado) }
            .sorted { izq, der in
                if izq.estatus.requiereAtencion != der.estatus.requiereAtencion {
                    return izq.estatus.requiereAtencion
                }
                return izq.valorUSD > der.valorUSD
            }
    }

    public func aplicar(ajustes nuevos: Ajustes) async {
        ajustes = nuevos
        almacen.guardar(nuevos)
        await refrescar()
    }

    public func refrescar() async {
        if !hayDatos { estado = .cargando }
        let cliente = fabricaCliente(ajustes)
        do {
            let nueva = try await cliente.instantanea()
            instantanea = nueva
            cache.guardar(nueva)
            estado = .listo
        } catch let error as ErrorAPI {
            estado = .error(error.errorDescription ?? "Error desconocido")
        } catch {
            estado = .error(error.localizedDescription)
        }
    }
}

public extension OperacionesStore {
    /// Store aislado, ya cargado con los datos de demostración. Lo usan las
    /// vistas previas de Xcode y las pruebas de interfaz.
    static func previsualizacion() -> OperacionesStore {
        let archivo = FileManager.default.temporaryDirectory
            .appendingPathComponent("previa-\(UUID().uuidString).json")
        let cache = CacheInstantanea(archivo: archivo)
        cache.guardar(ClienteAPIDemo.datos)
        let defaults = UserDefaults(suiteName: "previa.\(UUID().uuidString)") ?? .standard
        return OperacionesStore(cache: cache, almacen: AlmacenAjustes(defaults: defaults)) { _ in
            ClienteAPIDemo(retardo: .zero)
        }
    }
}
