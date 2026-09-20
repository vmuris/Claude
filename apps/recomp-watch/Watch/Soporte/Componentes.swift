import SwiftUI
import RecompCore

enum Tono {
    static let energia = Color.orange
    static let proteina = Color.blue
    static let sueno = Color.purple
    static let movimiento = Color.green
}

/// Anillo de progreso con el número al centro. Es el lenguaje del reloj.
struct Anillo: View {
    let valor: Double          // 0 a 1
    let color: Color
    var grosor: CGFloat = 8
    var excedido: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: grosor)
            Circle()
                .trim(from: 0, to: min(max(valor, 0), 1))
                .stroke(excedido ? Color.red : color,
                        style: StrokeStyle(lineWidth: grosor, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct AnilloConTexto: View {
    let valor: Double
    let color: Color
    let principal: String
    let etiqueta: String
    var excedido: Bool = false

    var body: some View {
        ZStack {
            Anillo(valor: valor, color: color, grosor: 9, excedido: excedido)
            VStack(spacing: 0) {
                Text(principal)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(etiqueta)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
        }
    }
}

struct Barrita: View {
    let etiqueta: String
    let valor: Double
    let texto: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(etiqueta).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(texto).font(.caption2.weight(.semibold).monospacedDigit())
            }
            ProgressView(value: min(max(valor, 0), 1))
                .tint(color)
        }
    }
}

struct FilaDato: View {
    let etiqueta: String
    let valor: String
    var color: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(etiqueta).font(.caption2).foregroundStyle(.secondary)
            Spacer(minLength: 6)
            Text(valor)
                .font(.caption.monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// Aviso fijo: esto es una herramienta de seguimiento, no un médico.
struct AvisoSalud: View {
    var body: some View {
        Text("Cálculos de referencia, no consejo médico. Consulta a tu médico antes de cambiar dieta o entrenamiento.")
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
    }
}

enum Fmt {
    static func kcal(_ valor: Double) -> String {
        String(format: "%.0f", valor)
    }

    static func gramos(_ valor: Double) -> String {
        String(format: "%.0f g", valor)
    }

    static func horas(_ valor: Double) -> String {
        let h = Int(valor)
        let m = Int((valor - Double(h)) * 60)
        return "\(h) h \(String(format: "%02d", m)) min"
    }

    static func kilos(_ valor: Double) -> String {
        String(format: "%.1f kg", valor)
    }

    static func porcentajeSemanal(_ valor: Double) -> String {
        String(format: "%+.2f %%/sem", valor)
    }
}
