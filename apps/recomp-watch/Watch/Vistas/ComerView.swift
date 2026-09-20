import SwiftUI
import WidgetKit
import RecompCore

/// Registro rápido. Teclear en el reloj es un castigo, así que se registra
/// con atajos y con la corona, en dos toques.
struct ComerView: View {
    @EnvironmentObject private var store: DiarioStore
    @State private var kcal: Double = 500
    @State private var proteina: Double = 35
    @State private var guardado = false

    /// Porciones típicas, no una base de datos de alimentos: el objetivo es
    /// registrar en cinco segundos, no contar gramos perfectos.
    private let atajos: [(nombre: String, simbolo: String, kcal: Double, proteina: Double)] = [
        ("Proteína", "fish.fill", 320, 45),
        ("Comida", "fork.knife", 700, 45),
        ("Snack", "takeoutbag.and.cup.and.straw.fill", 250, 12),
        ("Batido", "cup.and.saucer.fill", 180, 30)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                restante

                VStack(spacing: 6) {
                    ForEach(atajos, id: \.nombre) { atajo in
                        Button {
                            registrar(kcal: atajo.kcal, proteina: atajo.proteina)
                        } label: {
                            HStack {
                                Image(systemName: atajo.simbolo)
                                Text(atajo.nombre).font(.caption)
                                Spacer()
                                Text("\(Int(atajo.kcal)) · \(Int(atajo.proteina))g")
                                    .font(.system(size: 10).monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Divider()

                Stepper(value: $kcal, in: 50...1500, step: 50) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(Int(kcal)) kcal").font(.caption.monospacedDigit())
                        Text("A mano").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                Stepper(value: $proteina, in: 0...120, step: 5) {
                    Text("\(Int(proteina)) g proteína").font(.caption.monospacedDigit())
                }
                Button("Registrar") {
                    registrar(kcal: kcal, proteina: proteina)
                }
                .buttonStyle(.borderedProminent)
                .tint(Tono.energia)

                if guardado {
                    Label("Registrado", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Comer")
    }

    private var restante: some View {
        VStack(spacing: 2) {
            Text("\(abs(store.kcalRestantes))")
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(store.kcalRestantes < 0 ? .red : .primary)
            Text(store.kcalRestantes < 0 ? "kcal de más" : "kcal te quedan")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Faltan \(store.proteinaRestanteG) g de proteína")
                .font(.system(size: 10))
                .foregroundStyle(Tono.proteina)
        }
    }

    private func registrar(kcal: Double, proteina: Double) {
        Task {
            await store.registrarComida(kcal: kcal, proteinaG: proteina)
            WidgetCenter.shared.reloadAllTimelines()
            guardado = true
            try? await Task.sleep(for: .seconds(2))
            guardado = false
        }
    }
}

#Preview {
    NavigationStack { ComerView() }
        .environmentObject(DiarioStore.previsualizacion())
}
