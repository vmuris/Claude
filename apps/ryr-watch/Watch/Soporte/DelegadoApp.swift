import WatchKit
import WidgetKit
import RyRCore

/// Refresco en segundo plano: el reloj despierta cada N minutos, baja la
/// instantánea, la deja en caché y recarga la complicación.
final class DelegadoApp: NSObject, WKApplicationDelegate {

    func applicationDidFinishLaunching() {
        PuenteConectividad.shared.activar()
        programarRefresco()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for tarea in backgroundTasks {
            switch tarea {
            case let refresco as WKApplicationRefreshBackgroundTask:
                Task {
                    await actualizarEnSegundoPlano()
                    programarRefresco()
                    refresco.setTaskCompletedWithSnapshot(true)
                }
            case let instantanea as WKSnapshotRefreshBackgroundTask:
                instantanea.setTaskCompleted(restoredDefaultState: true,
                                             estimatedSnapshotExpiration: .distantFuture,
                                             userInfo: nil)
            default:
                tarea.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func actualizarEnSegundoPlano() async {
        let cliente = AlmacenAjustes.shared.clienteVigente()
        guard let nueva = try? await cliente.instantanea(limitePedimentos: 20) else { return }
        CacheInstantanea.shared.guardar(nueva)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func programarRefresco() {
        let minutos = max(5, AlmacenAjustes.shared.leer().minutosRefresco)
        let cuando = Date().addingTimeInterval(Double(minutos) * 60)
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: cuando,
                                                         userInfo: nil) { _ in }
    }
}
