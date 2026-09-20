import XCTest
@testable import RyRCore

final class ModelosTests: XCTestCase {

    func testDecodificaResumenConFechasISO() throws {
        let json = """
        {
          "fecha": "2026-09-20T14:30:00Z",
          "pedimentos_del_dia": 12,
          "cruces_doda": 7,
          "pendientes_facturar": 4,
          "cartera_total_mxn": 2743520.0,
          "cartera_vencida_mxn": 1069000.0,
          "alertas": [
            {"id": "a1", "titulo": "Detenido", "detalle": "22 h", "severidad": "critica"}
          ]
        }
        """.data(using: .utf8)!

        let resumen = try CodificadorRyR.decodificador.decode(ResumenDia.self, from: json)
        XCTAssertEqual(resumen.pedimentosDelDia, 12)
        XCTAssertEqual(resumen.crucesDoda, 7)
        XCTAssertEqual(resumen.alertas.first?.severidad, .critica)
        XCTAssertEqual(resumen.proporcionVencida, 1069000.0 / 2743520.0, accuracy: 0.0001)
    }

    func testEstatusDesconocidoNoRompeLaDecodificacion() throws {
        let json = """
        [{
          "id": "1", "numero": "264037215000123", "patente": "3721", "aduana": "400",
          "clave": "A1", "cliente": "X", "cliente_id": 1, "estatus": "en_tramite_raro",
          "valor_usd": 100.0, "fecha_pago": null, "modulado_en": null,
          "doda": null, "facturado": false
        }]
        """.data(using: .utf8)!

        let pedimentos = try CodificadorRyR.decodificador.decode([Pedimento].self, from: json)
        XCTAssertEqual(pedimentos.first?.estatus, .desconocido)
        XCTAssertFalse(pedimentos[0].cruzo)
    }

    func testFechaSoloDiaTambienDecodifica() throws {
        let json = #"{"fecha":"2026-09-20","pedimentos_del_dia":0,"cruces_doda":0,"pendientes_facturar":0,"cartera_total_mxn":0,"cartera_vencida_mxn":0,"alertas":[]}"#
        let resumen = try CodificadorRyR.decodificador.decode(ResumenDia.self, from: Data(json.utf8))
        XCTAssertEqual(resumen.proporcionVencida, 0)
    }

    func testRiesgoDeCarteraPorAntiguedad() {
        func cliente(_ dias: Int) -> ClienteCartera {
            ClienteCartera(id: 1, cliente: "X", saldoMXN: 1, vencidoMXN: 0, documentos: 1, diasPromedio: dias)
        }
        XCTAssertEqual(cliente(10).riesgo, .info)
        XCTAssertEqual(cliente(45).riesgo, .alta)
        XCTAssertEqual(cliente(90).riesgo, .critica)
    }

    func testIdaYVueltaDeInstantanea() throws {
        let original = ClienteAPIDemo.datos
        let datos = try CodificadorRyR.codificador.encode(original)
        let copia = try CodificadorRyR.decodificador.decode(Instantanea.self, from: datos)
        XCTAssertEqual(copia.pedimentos.count, original.pedimentos.count)
        XCTAssertEqual(copia.cartera.first?.cliente, original.cartera.first?.cliente)
    }
}
