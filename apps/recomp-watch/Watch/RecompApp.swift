import SwiftUI
import WidgetKit
import RecompCore

@main
struct RecompApp: App {
    @WKApplicationDelegateAdaptor(DelegadoApp.self) private var delegado
    @StateObject private var store = DiarioStore(salud: SaludHealthKit())

    var body: some Scene {
        WindowGroup {
            RaizView()
                .environmentObject(store)
        }
    }
}

struct RaizView: View {
    @EnvironmentObject private var store: DiarioStore
    @Environment(\.scenePhase) private var fase
    @State private var mostrarPerfil = false

    var body: some View {
        TabView {
            NavigationStack { HoyView() }
            NavigationStack { ComerView() }
            NavigationStack { EntrenarView() }
            NavigationStack { CuerpoView() }
            NavigationStack { PlanView() }
        }
        .tabViewStyle(.verticalPage)
        .task {
            await store.pedirPermisos()
            if !store.configurado { mostrarPerfil = true }
        }
        .onChange(of: fase) { _, nueva in
            guard nueva == .active else { return }
            Task {
                await store.cargar()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .sheet(isPresented: $mostrarPerfil) {
            NavigationStack { PerfilView() }
        }
    }
}

#Preview {
    RaizView().environmentObject(DiarioStore.previsualizacion())
}
