import WidgetKit
import SwiftUI
import RyRCore

struct EntradaRyR: TimelineEntry {
    let date: Date
    let instantanea: Instantanea

    var resumen: ResumenDia { instantanea.resumen }
}

/// Lee la caché compartida que deja la app. No hace red: una complicación
/// que depende de la red se queda en blanco justo cuando se necesita.
struct ProveedorRyR: TimelineProvider {
    func placeholder(in context: Context) -> EntradaRyR {
        EntradaRyR(date: Date(), instantanea: ClienteAPIDemo.datos)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaRyR) -> Void) {
        completion(EntradaRyR(date: Date(),
                              instantanea: CacheInstantanea.shared.leer() ?? ClienteAPIDemo.datos))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaRyR>) -> Void) {
        let instantanea = CacheInstantanea.shared.leer() ?? .vacia
        let ahora = Date()
        let entrada = EntradaRyR(date: ahora, instantanea: instantanea)
        let siguiente = ahora.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entrada], policy: .after(siguiente)))
    }
}

struct VistaComplicacion: View {
    @Environment(\.widgetFamily) private var familia
    let entrada: EntradaRyR

    var body: some View {
        switch familia {
        case .accessoryCircular:
            circular
        case .accessoryInline:
            Text("Cruces \(entrada.resumen.crucesDoda) · Sin fact. \(entrada.resumen.pendientesFacturar)")
        case .accessoryCorner:
            circular
        default:
            rectangular
        }
    }

    private var circular: some View {
        Gauge(value: Double(entrada.resumen.crucesDoda),
              in: 0...Double(max(entrada.resumen.pedimentosDelDia, 1))) {
            Image(systemName: "arrow.right.to.line")
        } currentValueLabel: {
            Text("\(entrada.resumen.crucesDoda)")
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("RyR · Hoy")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            Text("\(entrada.resumen.crucesDoda) cruces · \(entrada.resumen.pedimentosDelDia) pedimentos")
                .font(.caption2)
            Text("Vencido \(Formato.pesosCorto(entrada.resumen.carteraVencidaMXN))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct ComplicacionRyR: Widget {
    let kind = "ComplicacionRyR"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProveedorRyR()) { entrada in
            VistaComplicacion(entrada: entrada)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("RyR Operativo")
        .description("Cruces DODA y cartera vencida del día.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    ComplicacionRyR()
} timeline: {
    EntradaRyR(date: .now, instantanea: ClienteAPIDemo.datos)
}
