import WatchKit
import WidgetKit
import RecompCore

/// Refresco en segundo plano: vuelve a leer Salud, deja la instantánea lista
/// para la complicación y programa el siguiente despertar.
final class DelegadoApp: NSObject, WKApplicationDelegate {

    func applicationDidFinishLaunching() {
        programarRefresco()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for tarea in backgroundTasks {
            switch tarea {
            case let refresco as WKApplicationRefreshBackgroundTask:
                Task {
                    await actualizar()
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

    private func actualizar() async {
        let almacen = AlmacenPerfil.shared
        let perfil = almacen.leerPerfil()
        let objetivos = Calculo.objetivos(perfil)
        guard let dia = try? await SaludHealthKit().dia(Date()) else { return }

        let puntaje = Calculo.puntaje(dia: dia, objetivos: objetivos, perfil: perfil)
        almacen.guardar(InstantaneaDia(
            kcalRestantes: objetivos.energiaKcal - Int(dia.energiaConsumida.rounded()),
            proteinaRestanteG: max(0, objetivos.proteinaG - Int(dia.proteinaConsumida.rounded())),
            objetivoKcal: objetivos.energiaKcal,
            objetivoProteinaG: objetivos.proteinaG,
            puntaje: puntaje.total,
            horasSueno: dia.horasSueno,
            actualizada: Date()
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func programarRefresco() {
        let cuando = Date().addingTimeInterval(30 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: cuando,
                                                         userInfo: nil) { _ in }
    }
}
