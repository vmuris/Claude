import SwiftUI
import RyRCore

/// Lista operativa. Arriba lo que pide acción, abajo el resto del día.
struct PedimentosView: View {
    @EnvironmentObject private var store: OperacionesStore
    @State private var soloPendientes = false

    private var visibles: [Pedimento] {
        soloPendientes ? store.pendientes : store.instantanea.pedimentos
    }

    var body: some View {
        List {
            Toggle(isOn: $soloPendientes) {
                Label("Solo pendientes", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.caption)
            }

            if visibles.isEmpty {
                AvisoVacio(simbolo: "tray", titulo: "Nada aquí",
                           detalle: soloPendientes ? "No hay pedimentos detenidos ni cruzados sin facturar."
                                                   : "Sin movimientos registrados.")
                    .listRowBackground(Color.clear)
            }

            ForEach(visibles) { pedimento in
                NavigationLink(value: pedimento) {
                    FilaPedimento(pedimento: pedimento)
                }
            }
        }
        .navigationTitle("Pedimentos")
        .navigationDestination(for: Pedimento.self) { PedimentoDetalleView(pedimento: $0) }
        .refreshable { await store.refrescar() }
    }
}

#Preview {
    NavigationStack { PedimentosView() }
        .environmentObject(OperacionesStore.previsualizacion())
}
