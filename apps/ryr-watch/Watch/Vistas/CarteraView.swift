import SwiftUI
import RyRCore

/// Cobranza: quién debe, cuánto y con qué antigüedad.
struct CarteraView: View {
    @EnvironmentObject private var store: OperacionesStore

    var body: some View {
        List {
            if store.instantanea.cartera.isEmpty {
                AvisoVacio(simbolo: "checkmark.seal", titulo: "Cartera limpia",
                           detalle: "Sin saldos abiertos.")
                    .listRowBackground(Color.clear)
            }

            ForEach(store.instantanea.cartera) { cliente in
                VStack(alignment: .leading, spacing: 3) {
                    Text(cliente.cliente)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                    HStack {
                        Text(Formato.pesosCorto(cliente.saldoMXN))
                            .font(.caption2.monospacedDigit())
                        Spacer()
                        Text("\(cliente.diasPromedio) d")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(cliente.riesgo.color)
                    }
                    if cliente.vencidoMXN > 0 {
                        Text("Vencido \(Formato.pesosCorto(cliente.vencidoMXN)) · \(cliente.documentos) docs")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(cliente.documentos) docs al corriente")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("Cartera")
        .refreshable { await store.refrescar() }
    }
}

#Preview {
    NavigationStack { CarteraView() }
        .environmentObject(OperacionesStore.previsualizacion())
}
