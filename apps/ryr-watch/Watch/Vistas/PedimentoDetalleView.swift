import SwiftUI
import RyRCore

struct PedimentoDetalleView: View {
    let pedimento: Pedimento

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(Formato.numeroPedimento(pedimento.numero))
                    .font(.headline.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(pedimento.estatus.etiqueta, systemImage: pedimento.estatus.simbolo)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(pedimento.estatus.color)
                    Spacer()
                    Text(pedimento.clave)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.25), in: Capsule())
                }

                ProgressView(value: pedimento.estatus.avance)
                    .tint(pedimento.estatus.color)

                Divider()

                dato("Cliente", pedimento.cliente)
                dato("Patente / aduana", "\(pedimento.patente) · \(pedimento.aduana)")
                dato("Valor", Formato.dolares(pedimento.valorUSD))
                if let pago = pedimento.fechaPago {
                    dato("Pago", Formato.diaHora(pago))
                }
                if let modulado = pedimento.moduladoEn {
                    dato("Moduló", Formato.diaHora(modulado))
                }
                dato("DODA", pedimento.doda ?? "Sin emitir")
                dato("Factura", pedimento.facturado ? "Emitida" : "Pendiente")

                if pedimento.estatus.requiereAtencion {
                    Text("Detenido en reconocimiento. Llama al módulo antes de mover carga.")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Detalle")
    }

    private func dato(_ etiqueta: String, _ valor: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(etiqueta)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)
            Text(valor)
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

#Preview {
    NavigationStack {
        PedimentoDetalleView(pedimento: ClienteAPIDemo.datos.pedimentos[3])
    }
}
