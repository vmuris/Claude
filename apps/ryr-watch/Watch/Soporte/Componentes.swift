import SwiftUI
import RyRCore

/// Celda de KPI: número grande arriba, etiqueta corta abajo.
struct CeldaKPI: View {
    let valor: String
    let etiqueta: String
    let simbolo: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: simbolo)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(etiqueta)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(valor)
                .font(.title3.weight(.semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FilaPedimento: View {
    let pedimento: Pedimento

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: pedimento.estatus.simbolo)
                .foregroundStyle(pedimento.estatus.color)
                .font(.body)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(Formato.numeroPedimento(pedimento.numero))
                    .font(.caption.monospacedDigit())
                    .lineLimit(1)
                Text(pedimento.cliente)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            Text(pedimento.clave)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(pedimento.estatus.color.opacity(0.25), in: Capsule())
        }
    }
}

struct AvisoVacio: View {
    let simbolo: String
    let titulo: String
    let detalle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: simbolo)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(titulo).font(.headline).multilineTextAlignment(.center)
            Text(detalle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
}

/// Pie con la hora del último dato y el modo en uso.
struct PieActualizacion: View {
    let instantanea: Instantanea
    let modoDemo: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: modoDemo ? "flask" : "antenna.radiowaves.left.and.right")
            Text(modoDemo ? "Datos de demostración" : Formato.antiguedad(desde: instantanea.actualizada))
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}
