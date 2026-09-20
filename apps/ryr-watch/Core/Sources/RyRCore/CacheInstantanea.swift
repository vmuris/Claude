import Foundation

/// Caché en disco dentro del grupo de aplicaciones. La app la escribe y la
/// complicación la lee, así la esfera muestra el último dato aunque el
/// reloj esté sin conexión.
public final class CacheInstantanea: @unchecked Sendable {
    public static let shared = CacheInstantanea()

    private let archivo: URL?
    private let cola = DispatchQueue(label: "ryr.cache")

    public init(archivo: URL? = nil) {
        if let archivo {
            self.archivo = archivo
        } else {
            let fm = FileManager.default
            let carpeta = fm.containerURL(forSecurityApplicationGroupIdentifier: AlmacenAjustes.grupoApp)
                ?? fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            self.archivo = carpeta?.appendingPathComponent("instantanea.json")
        }
    }

    public func leer() -> Instantanea? {
        cola.sync {
            guard let archivo, let datos = try? Data(contentsOf: archivo) else { return nil }
            return try? CodificadorRyR.decodificador.decode(Instantanea.self, from: datos)
        }
    }

    public func guardar(_ instantanea: Instantanea) {
        cola.sync {
            guard let archivo, let datos = try? CodificadorRyR.codificador.encode(instantanea) else { return }
            try? datos.write(to: archivo, options: .atomic)
        }
    }

    public func borrar() {
        cola.sync {
            guard let archivo else { return }
            try? FileManager.default.removeItem(at: archivo)
        }
    }
}
