import Foundation

public enum FormatoFecha {
    public static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public static let isoFraccion: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    public static let soloDia: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Tijuana")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

public enum Formato {
    private static let moneda: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "es_MX")
        f.currencyCode = "MXN"
        f.maximumFractionDigits = 2
        return f
    }()

    private static let formatoHora: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let formatoDiaHora: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d MMM HH:mm"
        return f
    }()

    public static func pesos(_ monto: Double) -> String {
        moneda.string(from: NSNumber(value: monto)) ?? "$0.00"
    }

    /// Monto compacto para la pantalla del reloj: 1.84 M, 612 k.
    public static func pesosCorto(_ monto: Double) -> String {
        let absoluto = abs(monto)
        switch absoluto {
        case 1_000_000...:
            return String(format: "$%.2f M", monto / 1_000_000)
        case 1_000...:
            return String(format: "$%.0f k", monto / 1_000)
        default:
            return String(format: "$%.0f", monto)
        }
    }

    public static func dolares(_ monto: Double) -> String {
        String(format: "USD %@", NumberFormatter.localizedString(from: NSNumber(value: monto),
                                                                number: .decimal))
    }

    public static func hora(_ fecha: Date) -> String {
        formatoHora.string(from: fecha)
    }

    public static func diaHora(_ fecha: Date) -> String {
        formatoDiaHora.string(from: fecha)
    }

    /// Antigüedad legible para el pie de pantalla: "hace 3 min".
    public static func antiguedad(desde fecha: Date, hasta ahora: Date = Date()) -> String {
        let segundos = max(0, ahora.timeIntervalSince(fecha))
        switch segundos {
        case ..<60: return "hace un momento"
        case ..<3600: return "hace \(Int(segundos / 60)) min"
        case ..<86_400: return "hace \(Int(segundos / 3600)) h"
        default: return "hace \(Int(segundos / 86_400)) d"
        }
    }

    /// Agrupa el número de pedimento en bloques legibles: 26 40 3721 5000123.
    public static func numeroPedimento(_ crudo: String) -> String {
        let limpio = crudo.filter { $0.isNumber }
        guard limpio.count == 15 else { return crudo }
        let c = Array(limpio)
        return "\(String(c[0...1])) \(String(c[2...3])) \(String(c[4...7])) \(String(c[8...14]))"
    }
}
