import SwiftUI
import RyRCore

extension EstatusPedimento {
    var color: Color {
        switch self {
        case .capturado: return .gray
        case .pagado: return .blue
        case .modulado: return .teal
        case .cruzado: return .green
        case .facturado: return .indigo
        case .detenido: return .red
        case .desconocido: return .secondary
        }
    }

    var simbolo: String {
        switch self {
        case .capturado: return "square.and.pencil"
        case .pagado: return "creditcard"
        case .modulado: return "checkmark.seal"
        case .cruzado: return "arrow.right.to.line"
        case .facturado: return "doc.text"
        case .detenido: return "exclamationmark.triangle.fill"
        case .desconocido: return "questionmark.circle"
        }
    }
}

extension Severidad {
    var color: Color {
        switch self {
        case .info: return .blue
        case .alta: return .orange
        case .critica: return .red
        }
    }
}

enum Tema {
    static let verdeRyR = Color(red: 0.05, green: 0.42, blue: 0.29)
}
