import SwiftUI
import RyRCore

/// Pantalla principal: los cuatro números del día y las alertas abiertas.
struct HoyView: View {
    @EnvironmentObject private var store: OperacionesStore

    private var resumen: ResumenDia { store.instantanea.resumen }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if store.estado == .cargando && !store.hayDatos {
                    ProgressView("Consultando…").padding(.vertical, 24)
                } else {
                    rejillaKPI
                    barraCartera
                    alertas
                    PieActualizacion(instantanea: store.instantanea, modoDemo: !store.ajustes.usaBackend)
                }

                if let mensaje = store.estado.mensaje {
                    Text(mensaje)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Hoy")
        .refreshable { await store.refrescar() }
    }

    private var rejillaKPI: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                CeldaKPI(valor: "\(resumen.pedimentosDelDia)", etiqueta: "Pedimentos",
                         simbolo: "doc.on.doc", color: .blue)
                CeldaKPI(valor: "\(resumen.crucesDoda)", etiqueta: "Cruces DODA",
                         simbolo: "arrow.right.to.line", color: .green)
            }
            HStack(spacing: 6) {
                CeldaKPI(valor: "\(resumen.pendientesFacturar)", etiqueta: "Sin facturar",
                         simbolo: "doc.text.magnifyingglass", color: .orange)
                CeldaKPI(valor: Formato.pesosCorto(resumen.carteraVencidaMXN), etiqueta: "Vencido",
                         simbolo: "banknote", color: .red)
            }
        }
    }

    private var barraCartera: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("Cartera").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(Formato.pesosCorto(resumen.carteraTotalMXN))
                    .font(.caption2.weight(.semibold))
            }
            ProgressView(value: resumen.proporcionVencida)
                .tint(resumen.proporcionVencida > 0.4 ? .red : .green)
            Text("\(Int(resumen.proporcionVencida * 100))% vencido")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private var alertas: some View {
        if resumen.alertas.isEmpty {
            AvisoVacio(simbolo: "checkmark.circle", titulo: "Sin alertas",
                       detalle: "Nada detenido y nada vencido hoy.")
        } else {
            VStack(spacing: 6) {
                ForEach(resumen.alertas) { alerta in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(alerta.severidad.color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(alerta.titulo).font(.caption.weight(.semibold))
                            Text(alerta.detalle).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .background(alerta.severidad.color.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

#Preview {
    NavigationStack { HoyView() }
        .environmentObject(OperacionesStore.previsualizacion())
}
