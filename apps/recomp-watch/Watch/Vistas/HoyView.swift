import SwiftUI
import RecompCore

/// La pantalla que se ve al levantar la muñeca: cuánto te queda por comer,
/// cuánta proteína falta y si el día va a contar o no.
struct HoyView: View {
    @EnvironmentObject private var store: DiarioStore

    private var restantes: Int { store.kcalRestantes }
    private var objetivo: Int { store.objetivos.energiaKcal }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                anillos
                puntaje
                balance
                if let ajuste = store.ajustePendiente {
                    avisoAjuste(ajuste)
                }
                if let mensaje = store.estado.mensaje {
                    Text(mensaje)
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Hoy")
        .refreshable { await store.cargar() }
    }

    private var anillos: some View {
        HStack(spacing: 6) {
            AnilloConTexto(valor: proporcionEnergia,
                           color: Tono.energia,
                           principal: "\(abs(restantes))",
                           etiqueta: restantes >= 0 ? "kcal" : "de más",
                           excedido: restantes < 0)
            AnilloConTexto(valor: proporcionProteina,
                           color: Tono.proteina,
                           principal: "\(store.proteinaRestanteG)",
                           etiqueta: "g prot")
        }
        .frame(height: 78)
    }

    private var proporcionEnergia: Double {
        guard objetivo > 0 else { return 0 }
        return store.hoy.energiaConsumida / Double(objetivo)
    }

    private var proporcionProteina: Double {
        guard store.objetivos.proteinaG > 0 else { return 0 }
        return store.hoy.proteinaConsumida / Double(store.objetivos.proteinaG)
    }

    private var puntaje: some View {
        let p = store.puntajeHoy
        return VStack(spacing: 4) {
            HStack {
                Text(p.veredicto).font(.caption.weight(.semibold))
                Spacer()
                Text("\(p.total)/100")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 3) {
                segmento(p.energia, de: 30, color: Tono.energia)
                segmento(p.proteina, de: 30, color: Tono.proteina)
                segmento(p.sueno, de: 25, color: Tono.sueno)
                segmento(p.movimiento, de: 15, color: Tono.movimiento)
            }
            .frame(height: 6)
        }
        .padding(8)
        .background(Color.gray.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
    }

    private func segmento(_ obtenido: Int, de total: Int, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.22))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * (Double(obtenido) / Double(total)))
            }
        }
    }

    private var balance: some View {
        VStack(spacing: 4) {
            FilaDato(etiqueta: "Sueño",
                     valor: Fmt.horas(store.hoy.horasSueno),
                     color: store.hoy.horasSueno >= store.perfil.horasSuenoObjetivo ? .green : .orange)
            FilaDato(etiqueta: "Activa", valor: "\(Fmt.kcal(store.hoy.energiaActiva)) kcal")
            FilaDato(etiqueta: store.balanceHoy < 0 ? "Déficit real" : "Superávit real",
                     valor: "\(Fmt.kcal(abs(store.balanceHoy))) kcal",
                     color: store.balanceHoy < 0 ? .green : .orange)
            if store.hoy.minutosFuerza > 0 {
                FilaDato(etiqueta: "Fuerza", valor: "\(Int(store.hoy.minutosFuerza)) min", color: .green)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private func avisoAjuste(_ ajuste: AjusteSugerido) -> some View {
        NavigationLink {
            PlanView()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ajuste sugerido").font(.caption.weight(.semibold))
                    Text("\(ajuste.kcal > 0 ? "+" : "")\(ajuste.kcal) kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .tint(.yellow)
    }
}

#Preview {
    NavigationStack { HoyView() }
        .environmentObject(DiarioStore.previsualizacion())
}
