import Foundation
import Combine

public enum EstadoCarga: Equatable, Sendable {
    case inicial
    case cargando
    case listo
    case error(String)

    public var mensaje: String? {
        if case .error(let m) = self { return m }
        return nil
    }
}

/// Fuente única de verdad de la app: perfil, objetivos, día de hoy, semana y
/// el ajuste pendiente de aprobar.
@MainActor
public final class DiarioStore: ObservableObject {
    @Published public private(set) var perfil: Perfil
    @Published public private(set) var objetivos: Objetivos
    @Published public private(set) var hoy: ResumenDia
    @Published public private(set) var semana: [ResumenDia] = []
    @Published public private(set) var tendencia: TendenciaPeso?
    @Published public private(set) var ajustePendiente: AjusteSugerido?
    @Published public private(set) var estado: EstadoCarga = .inicial
    @Published public var permisosConcedidos = false

    private let salud: FuenteSalud
    private let almacen: AlmacenPerfil

    public init(salud: FuenteSalud, almacen: AlmacenPerfil = .shared) {
        self.salud = salud
        self.almacen = almacen
        let perfilGuardado = almacen.leerPerfil()
        self.perfil = perfilGuardado
        self.objetivos = Calculo.objetivos(perfilGuardado)
        self.hoy = ResumenDia(fecha: Calendar.current.startOfDay(for: Date()))
    }

    public var configurado: Bool { almacen.configurado }

    public var puntajeHoy: Puntaje {
        Calculo.puntaje(dia: hoy, objetivos: objetivos, perfil: perfil)
    }

    public var kcalRestantes: Int {
        objetivos.energiaKcal - Int(hoy.energiaConsumida.rounded())
    }

    public var proteinaRestanteG: Int {
        max(0, objetivos.proteinaG - Int(hoy.proteinaConsumida.rounded()))
    }

    /// Déficit o superávit real del día, contra el gasto que midió el reloj.
    public var balanceHoy: Double {
        Calculo.balance(hoy, tmb: objetivos.tmb)
    }

    public var resumenSemana: ResumenSemana {
        ResumenSemana.calcular(dias: semana, perfil: perfil, objetivos: objetivos)
    }

    public func pedirPermisos() async {
        do {
            try await salud.pedirPermisos()
            permisosConcedidos = true
            await cargar()
        } catch {
            estado = .error((error as? ErrorSalud)?.errorDescription ?? error.localizedDescription)
        }
    }

    public func cargar() async {
        if semana.isEmpty { estado = .cargando }
        do {
            let dias = try await salud.ultimosDias(14)
            semana = Array(dias.prefix(7))
            hoy = dias.first ?? ResumenDia(fecha: Calendar.current.startOfDay(for: Date()))
            tendencia = try await salud.tendenciaPeso(dias: 14)
            revisarAjuste()
            guardarInstantanea()
            estado = .listo
        } catch {
            estado = .error((error as? ErrorSalud)?.errorDescription ?? error.localizedDescription)
        }
    }

    public func registrarComida(kcal: Double, proteinaG: Double) async {
        do {
            try await salud.registrarComida(kcal: kcal, proteinaG: proteinaG, fecha: Date())
            // Reflejo inmediato para que la pantalla no espere a Salud.
            hoy.energiaConsumida += kcal
            hoy.proteinaConsumida += proteinaG
            guardarInstantanea()
            await cargar()
        } catch {
            estado = .error((error as? ErrorSalud)?.errorDescription ?? error.localizedDescription)
        }
    }

    public func registrarPeso(_ kg: Double) async {
        do {
            try await salud.registrarPeso(kg, fecha: Date())
            var copia = perfil
            copia.pesoKg = kg
            guardar(copia)
            await cargar()
        } catch {
            estado = .error((error as? ErrorSalud)?.errorDescription ?? error.localizedDescription)
        }
    }

    public func guardar(_ nuevo: Perfil) {
        perfil = nuevo
        objetivos = Calculo.objetivos(nuevo)
        almacen.guardar(nuevo)
        guardarInstantanea()
    }

    /// El ajuste no se aplica solo: lo propone y tú decides.
    public func aceptarAjuste() {
        guard let ajuste = ajustePendiente, ajuste.hayCambio else { return }
        guardar(Calculo.aplicar(ajuste, a: perfil))
        almacen.registrarAjuste()
        ajustePendiente = nil
    }

    public func descartarAjuste() {
        almacen.registrarAjuste()
        ajustePendiente = nil
    }

    private func revisarAjuste() {
        guard let tendencia else {
            ajustePendiente = nil
            return
        }
        // Como mucho un ajuste por semana: el peso necesita tiempo para hablar.
        if let ultimo = almacen.fechaUltimoAjuste(),
           Date().timeIntervalSince(ultimo) < 7 * 86_400 {
            ajustePendiente = nil
            return
        }
        let sugerido = Calculo.ajuste(perfil: perfil, tendencia: tendencia)
        ajustePendiente = sugerido.hayCambio ? sugerido : nil
    }

    private func guardarInstantanea() {
        almacen.guardar(InstantaneaDia(
            kcalRestantes: kcalRestantes,
            proteinaRestanteG: proteinaRestanteG,
            objetivoKcal: objetivos.energiaKcal,
            objetivoProteinaG: objetivos.proteinaG,
            puntaje: puntajeHoy.total,
            horasSueno: hoy.horasSueno,
            actualizada: Date()
        ))
    }
}

public extension DiarioStore {
    /// Store de demostración ya cargado, para vistas previas.
    static func previsualizacion() -> DiarioStore {
        let defaults = UserDefaults(suiteName: "previa.\(UUID().uuidString)") ?? .standard
        let almacen = AlmacenPerfil(defaults: defaults)
        almacen.guardar(Perfil(sexo: .hombre, edad: 38, estaturaCm: 178, pesoKg: 92,
                               nivel: .moderado, objetivo: .recomposicion))
        return DiarioStore(salud: FuenteSaludDemo(), almacen: almacen)
    }
}
