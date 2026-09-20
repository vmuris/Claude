import SwiftUI
import RecompCore

/// Los datos que mueven los números. Se editan poco, así que van en una lista.
struct PerfilView: View {
    @EnvironmentObject private var store: DiarioStore
    @Environment(\.dismiss) private var cerrar
    @State private var borrador = Perfil()
    @State private var cargado = false

    var body: some View {
        List {
            Section("Tú") {
                Picker("Sexo", selection: $borrador.sexo) {
                    ForEach(Sexo.allCases, id: \.self) { Text($0.etiqueta).tag($0) }
                }
                Stepper("Edad \(borrador.edad)", value: $borrador.edad, in: 14...90)
                Stepper("Estatura \(Int(borrador.estaturaCm)) cm",
                        value: $borrador.estaturaCm, in: 130...220, step: 1)
                Stepper("Peso \(Fmt.kilos(borrador.pesoKg))",
                        value: $borrador.pesoKg, in: 35...220, step: 0.5)
            }

            Section("Plan") {
                Picker("Objetivo", selection: $borrador.objetivo) {
                    ForEach(Objetivo.allCases, id: \.self) { Text($0.etiqueta).tag($0) }
                }
                Picker("Actividad", selection: $borrador.nivel) {
                    ForEach(NivelActividad.allCases, id: \.self) { Text($0.etiqueta).tag($0) }
                }
                Stepper("Sueño \(String(format: "%.1f", borrador.horasSuenoObjetivo)) h",
                        value: $borrador.horasSuenoObjetivo, in: 5...10, step: 0.5)
                Stepper("Meta activa \(Int(borrador.metaEnergiaActiva)) kcal",
                        value: $borrador.metaEnergiaActiva, in: 200...1200, step: 50)
            }

            Section("Resultado") {
                let previa = Calculo.objetivos(borrador)
                FilaDato(etiqueta: "Calorías", valor: "\(previa.energiaKcal) kcal", color: Tono.energia)
                FilaDato(etiqueta: "Proteína", valor: "\(previa.proteinaG) g", color: Tono.proteina)
                Button("Guardar") {
                    store.guardar(borrador)
                    cerrar()
                }
                .buttonStyle(.borderedProminent)
            }

            Section { AvisoSalud() }
        }
        .navigationTitle("Perfil")
        .onAppear {
            guard !cargado else { return }
            borrador = store.perfil
            cargado = true
        }
    }
}

#Preview {
    NavigationStack { PerfilView() }
        .environmentObject(DiarioStore.previsualizacion())
}
