import SwiftUI
import RecompCore

/// Entrenamiento en vivo: elige tipo y el reloj mide pulso y energía.
struct EntrenarView: View {
    @EnvironmentObject private var store: DiarioStore
    @StateObject private var sesion = SesionEntrenamiento()

    var body: some View {
        Group {
            if sesion.activa {
                enCurso
            } else {
                seleccion
            }
        }
        .navigationTitle(sesion.activa ? "En curso" : "Entrenar")
    }

    private var seleccion: some View {
        ScrollView {
            VStack(spacing: 6) {
                if store.hoy.minutosFuerza > 0 || store.hoy.minutosCardio > 0 {
                    HStack(spacing: 8) {
                        if store.hoy.minutosFuerza > 0 {
                            Label("\(Int(store.hoy.minutosFuerza)) min fuerza", systemImage: "dumbbell.fill")
                        }
                        if store.hoy.minutosCardio > 0 {
                            Label("\(Int(store.hoy.minutosCardio)) min cardio", systemImage: "figure.run")
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }

                ForEach(SesionEntrenamiento.Tipo.allCases) { tipo in
                    Button {
                        sesion.iniciar(tipo)
                    } label: {
                        HStack {
                            Image(systemName: tipo.simbolo)
                            Text(tipo.etiqueta).font(.caption)
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(tipo == .fuerza ? .green : .blue)
                }

                Text("La fuerza es lo que protege el músculo en déficit. Tres sesiones por semana es el piso.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if let error = sesion.error {
                    Text(error).font(.system(size: 10)).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var enCurso: some View {
        VStack(spacing: 8) {
            Text(sesion.duracionTexto)
                .font(.system(size: 38, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(sesion.enPausa ? .secondary : .primary)

            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text("\(Int(sesion.pulso))")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.red)
                    Text("ppm").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                VStack(spacing: 0) {
                    Text("\(Int(sesion.kcal))")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(Tono.energia)
                    Text("kcal").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Button {
                    sesion.enPausa ? sesion.reanudar() : sesion.pausar()
                } label: {
                    Image(systemName: sesion.enPausa ? "play.fill" : "pause.fill")
                }
                .tint(.yellow)

                Button {
                    sesion.terminar()
                    Task { await store.cargar() }
                } label: {
                    Image(systemName: "stop.fill")
                }
                .tint(.red)
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    NavigationStack { EntrenarView() }
        .environmentObject(DiarioStore.previsualizacion())
}
