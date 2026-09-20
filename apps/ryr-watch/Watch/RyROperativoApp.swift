import SwiftUI
import WidgetKit
import RyRCore

@main
struct RyROperativoApp: App {
    @WKApplicationDelegateAdaptor(DelegadoApp.self) private var delegado
    @StateObject private var store = OperacionesStore()

    var body: some Scene {
        WindowGroup {
            RaizView()
                .environmentObject(store)
        }
    }
}

/// Navegación principal: cuatro páginas verticales, Digital Crown para moverse.
struct RaizView: View {
    @EnvironmentObject private var store: OperacionesStore
    @Environment(\.scenePhase) private var fase

    var body: some View {
        TabView {
            NavigationStack { HoyView() }
            NavigationStack { PedimentosView() }
            NavigationStack { CarteraView() }
            NavigationStack { AjustesView() }
        }
        .tabViewStyle(.verticalPage)
        .task { await store.refrescar() }
        .onChange(of: fase) { _, nueva in
            guard nueva == .active else { return }
            Task {
                await store.refrescar()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: PuenteConectividad.ajustesRecibidos)) { aviso in
            guard let ajustes = aviso.object as? Ajustes else { return }
            Task { await store.aplicar(ajustes: ajustes) }
        }
    }
}

#Preview {
    RaizView().environmentObject(OperacionesStore.previsualizacion())
}
