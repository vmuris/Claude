import XCTest
@testable import RyRCore

final class FormatoTests: XCTestCase {

    func testNumeroDePedimentoSeAgrupa() {
        XCTAssertEqual(Formato.numeroPedimento("264037215000123"), "26 40 3721 5000123")
        XCTAssertEqual(Formato.numeroPedimento("26 40 3721 5000123"), "26 40 3721 5000123")
    }

    func testNumeroIncompletoSeDevuelveTalCual() {
        XCTAssertEqual(Formato.numeroPedimento("12345"), "12345")
    }

    func testMontoCorto() {
        XCTAssertEqual(Formato.pesosCorto(1_842_300), "$1.84 M")
        XCTAssertEqual(Formato.pesosCorto(612_450), "$612 k")
        XCTAssertEqual(Formato.pesosCorto(940), "$940")
    }

    func testAntiguedad() {
        let ahora = Date()
        XCTAssertEqual(Formato.antiguedad(desde: ahora.addingTimeInterval(-30), hasta: ahora), "hace un momento")
        XCTAssertEqual(Formato.antiguedad(desde: ahora.addingTimeInterval(-180), hasta: ahora), "hace 3 min")
        XCTAssertEqual(Formato.antiguedad(desde: ahora.addingTimeInterval(-7200), hasta: ahora), "hace 2 h")
        XCTAssertEqual(Formato.antiguedad(desde: ahora.addingTimeInterval(-172_800), hasta: ahora), "hace 2 d")
    }
}
