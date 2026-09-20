import SwiftUI
import RecompCore

/// La báscula y la semana. Aquí se ve si el plan está funcionando de verdad.
struct CuerpoView: View {
    @EnvironmentObject private var store: DiarioStore
    @State private var peso: Double = 0
    @State private var registrando = false

    private var semana: ResumenSemana { store.resumenSemana }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                pesoActual
                tendencia
                semanal
                AvisoSalud()
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Cuerpo")
        .onAppear { if peso == 0 { peso = store.perfil.pesoKg } }
        .refreshable { await store.cargar() }
    }

    private var pesoActual: some View {
        VStack(spacing: 4) {
            Text(Fmt.kilos(peso))
                .font(.title2.weight(.semibold).monospacedDigit())
            Stepper(value: $peso, in: 35...220, step: 0.1) {
                Text("Pesarme").font(.caption2)
            }
            Button(registrando ? "Guardando…" : "Registrar peso") {
                registrando = true
                Task {
                    await store.registrarPeso(peso)
                    registrando = false
                }
            }
            .buttonStyle(.bordered)
            .disabled(registrando)
        }
        .padding(8)
        .background(Color.gray.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var tendencia: some View {
        if let t = store.tendencia {
            let cambio = t.cambioSemanalPorcentaje
            let rango = store.perfil.objetivo.cambioSemanalObjetivo
            let dentro = rango.contains(cambio)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Tendencia").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text(Fmt.porcentajeSemanal(cambio))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(dentro ? .green : .orange)
                }
                Text(dentro ? "Dentro del rango. No cambies nada."
                            : "Fuera del rango de \(Fmt.porcentajeSemanal(rango.lowerBound)) a \(Fmt.porcentajeSemanal(rango.upperBound)).")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                FilaDato(etiqueta: "Ventana", valor: "\(t.dias) días")
            }
            .padding(8)
            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        } else {
            Text("Pésate varios días para que haya tendencia.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var semanal: some View {
        VStack(spacing: 6) {
            Barrita(etiqueta: "Adherencia",
                    valor: Double(semana.puntajePromedio) / 100,
                    texto: "\(semana.puntajePromedio)/100",
                    color: .teal)
            FilaDato(etiqueta: "Fuerza", valor: "\(semana.sesionesFuerza) de 3+",
                     color: semana.sesionesFuerza >= 3 ? .green : .orange)
            FilaDato(etiqueta: "Deuda de sueño",
                     valor: Fmt.horas(semana.deudaSuenoHoras),
                     color: semana.deudaSuenoHoras > 5 ? .orange : .green)
            FilaDato(etiqueta: "Balance 7 d",
                     valor: "\(Fmt.kcal(semana.balanceAcumulado)) kcal")
            FilaDato(etiqueta: "Equivale a",
                     valor: String(format: "%.2f kg", semana.kilosEquivalentes))
            FilaDato(etiqueta: "Días registrados",
                     valor: "\(semana.diasRegistrados) de \(semana.dias)",
                     color: semana.diasRegistrados >= 6 ? .green : .orange)
        }
        .padding(8)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack { CuerpoView() }
        .environmentObject(DiarioStore.previsualizacion())
}
