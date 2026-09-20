import SwiftUI
import RyRCore

@main
struct AppiPhone: App {
    var body: some Scene {
        WindowGroup {
            ConfiguracionView()
        }
    }
}

/// Única función del iPhone: guardar el servidor y el token, y empujarlos
/// al reloj. Aquí sí se puede teclear.
struct ConfiguracionView: View {
    @StateObject private var puente = PuenteConectividad.shared
    @State private var ajustes = AlmacenAjustes.shared.leer()
    @State private var aviso: String?
    @State private var probando = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Servidor") {
                    Toggle("Modo demostración", isOn: $ajustes.modoDemo)
                    TextField("https://api.tu-servidor.mx", text: $ajustes.urlBase)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .disabled(ajustes.modoDemo)
                    SecureField("Token", text: $ajustes.token)
                        .disabled(ajustes.modoDemo)
                    Stepper("Refresco cada \(ajustes.minutosRefresco) min",
                            value: $ajustes.minutosRefresco, in: 5...60, step: 5)
                }

                Section("Reloj") {
                    LabeledContent("Estado") {
                        Text(puente.alcanzable ? "Conectado" : "En espera")
                            .foregroundStyle(puente.alcanzable ? .green : .secondary)
                    }
                    if let envio = puente.ultimoEnvio {
                        LabeledContent("Último envío") { Text(Formato.hora(envio)) }
                    }
                    Button("Enviar al reloj") { enviar() }
                }

                Section {
                    Button(probando ? "Probando…" : "Probar conexión") { probar() }
                        .disabled(probando || ajustes.modoDemo)
                    if let aviso {
                        Text(aviso).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("RyR Operativo")
            .onAppear { puente.activar() }
        }
    }

    private func enviar() {
        AlmacenAjustes.shared.guardar(ajustes)
        aviso = puente.enviar(ajustes)
            ? "Ajustes enviados al reloj."
            : "No se pudo enviar. Abre la app en el reloj e inténtalo de nuevo."
    }

    private func probar() {
        guard let cliente = ClienteAPIRest(ajustes: ajustes) else {
            aviso = "Falta servidor o token."
            return
        }
        probando = true
        Task {
            do {
                let resumen = try await cliente.resumen()
                aviso = "Respondió: \(resumen.pedimentosDelDia) pedimentos, \(resumen.crucesDoda) cruces."
            } catch {
                aviso = (error as? ErrorAPI)?.errorDescription ?? error.localizedDescription
            }
            probando = false
        }
    }
}

#Preview {
    ConfiguracionView()
}
