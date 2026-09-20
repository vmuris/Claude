import WidgetKit
import SwiftUI
import RecompCore

struct EntradaRecomp: TimelineEntry {
    let date: Date
    let dia: InstantaneaDia
}

/// Lee la instantánea que deja la app. Sin red y sin consultas a Salud: en la
/// esfera lo que importa es que el número aparezca siempre.
struct ProveedorRecomp: TimelineProvider {
    private var ejemplo: InstantaneaDia {
        InstantaneaDia(kcalRestantes: 620, proteinaRestanteG: 48, objetivoKcal: 2520,
                       objetivoProteinaG: 184, puntaje: 78, horasSueno: 7.1, actualizada: Date())
    }

    func placeholder(in context: Context) -> EntradaRecomp {
        EntradaRecomp(date: Date(), dia: ejemplo)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaRecomp) -> Void) {
        completion(EntradaRecomp(date: Date(), dia: AlmacenPerfil.shared.leerInstantanea() ?? ejemplo))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaRecomp>) -> Void) {
        let dia = AlmacenPerfil.shared.leerInstantanea() ?? .vacia
        let entrada = EntradaRecomp(date: Date(), dia: dia)
        completion(Timeline(entries: [entrada], policy: .after(Date().addingTimeInterval(20 * 60))))
    }
}

struct VistaComplicacion: View {
    @Environment(\.widgetFamily) private var familia
    let entrada: EntradaRecomp

    var body: some View {
        switch familia {
        case .accessoryInline:
            Text("\(entrada.dia.kcalRestantes) kcal · \(entrada.dia.proteinaRestanteG) g")
        case .accessoryRectangular:
            rectangular
        default:
            circular
        }
    }

    private var circular: some View {
        Gauge(value: entrada.dia.proporcionEnergia) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(entrada.dia.kcalRestantes)")
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entrada.dia.kcalRestantes < 0 ? .red : .orange)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Quedan \(entrada.dia.kcalRestantes) kcal")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            Text("Proteína: faltan \(entrada.dia.proteinaRestanteG) g")
                .font(.caption2)
            Text("Día \(entrada.dia.puntaje)/100")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct ComplicacionRecomp: Widget {
    let kind = "ComplicacionRecomp"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProveedorRecomp()) { entrada in
            VistaComplicacion(entrada: entrada)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Recomp")
        .description("Calorías y proteína que te quedan hoy.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    ComplicacionRecomp()
} timeline: {
    EntradaRecomp(date: .now,
                  dia: InstantaneaDia(kcalRestantes: 620, proteinaRestanteG: 48, objetivoKcal: 2520,
                                      objetivoProteinaG: 184, puntaje: 78, horasSueno: 7.1,
                                      actualizada: .now))
}
