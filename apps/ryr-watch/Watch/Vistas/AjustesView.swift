import SwiftUI
import WidgetKit
import RyRCore

/// El reloj no captura credenciales: solo muestra cómo está conectado y
/// permite forzar un refresco.
struct AjustesView: View {
    @EnvironmentObject private var store: OperacionesStore
    @State private var refrescando = false

    var body: some View {
        List {
            Section("Conexión") {
                LabeledContent("Modo") {
                    Text(store.ajustes.usaBackend ? "Darwin" : "Demostración")
                        .foregroundStyle(store.ajustes.usaBackend ? .green : .orange)
                }
                if store.ajustes.usaBackend {
                    LabeledContent("Servidor") {
                        Text(servidorCorto).font(.caption2).lineLimit(1)
                    }
                }
                LabeledContent("Refresco") {
                    Text("\(store.ajustes.minutosRefresco) min")
                }
            }

            Section("Datos") {
                LabeledContent("Actualizado") {
                    Text(store.hayDatos ? Formato.antiguedad(desde: store.instantanea.actualizada) : "Nunca")
                        .font(.caption2)
                }
                Button {
                    Task {
                        refrescando = true
                        await store.refrescar()
                        WidgetCenter.shared.reloadAllTimelines()
                        refrescando = false
                    }
                } label: {
                    Label(refrescando ? "Actualizando…" : "Actualizar ahora",
                          systemImage: "arrow.clockwise")
                }
                .disabled(refrescando)
            }

            Section {
                Text("El servidor y el token se configuran en la app del iPhone.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
    }

    private var servidorCorto: String {
        URL(string: store.ajustes.urlBase)?.host ?? store.ajustes.urlBase
    }
}

#Preview {
    NavigationStack { AjustesView() }
        .environmentObject(OperacionesStore.previsualizacion())
}
