import SwiftUI
import RecompCore

/// El plan y su única palanca: el ajuste por tendencia, que tú apruebas.
struct PlanView: View {
    @EnvironmentObject private var store: DiarioStore

    private var o: Objetivos { store.objetivos }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let ajuste = store.ajustePendiente {
                    propuesta(ajuste)
                }

                VStack(spacing: 4) {
                    FilaDato(etiqueta: "Objetivo", valor: store.perfil.objetivo.etiqueta)
                    FilaDato(etiqueta: "Calorías", valor: "\(o.energiaKcal) kcal", color: Tono.energia)
                    FilaDato(etiqueta: "Proteína", valor: "\(o.proteinaG) g", color: Tono.proteina)
                    FilaDato(etiqueta: "Grasa", valor: "\(o.grasaG) g")
                    FilaDato(etiqueta: "Carbohidratos", valor: "\(o.carbosG) g")
                }
                .padding(8)
                .background(Color.gray.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

                VStack(spacing: 4) {
                    FilaDato(etiqueta: "TMB", valor: "\(Int(o.tmb.rounded())) kcal")
                    FilaDato(etiqueta: "Gasto estimado", valor: "\(Int(o.gastoEstimado.rounded())) kcal")
                    FilaDato(etiqueta: "Ajuste acumulado",
                             valor: "\(Int(store.perfil.ajusteAcumuladoKcal)) kcal")
                    if o.enElPiso {
                        Text("Estás en el mínimo de seguridad (\(Int(o.piso.rounded())) kcal). No se baja más: toca subir actividad, no recortar comida.")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                NavigationLink("Editar perfil") { PerfilView() }
                    .font(.caption)

                AvisoSalud()
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Plan")
    }

    private func propuesta(_ ajuste: AjusteSugerido) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Ajuste sugerido", systemImage: "slider.horizontal.3")
                .font(.caption.weight(.semibold))
            Text("\(ajuste.kcal > 0 ? "+" : "")\(ajuste.kcal) kcal al día")
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(ajuste.razon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Button("Aplicar") { store.aceptarAjuste() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                Button("Ahora no") { store.descartarAjuste() }
                    .buttonStyle(.bordered)
            }
            .font(.caption2)
        }
        .padding(8)
        .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack { PlanView() }
        .environmentObject(DiarioStore.previsualizacion())
}
