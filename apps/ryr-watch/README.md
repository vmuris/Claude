# RyR Operativo — app para Apple Watch

App nativa de watchOS que pone en la muñeca los cuatro números de la operación
aduanal del día: pedimentos, cruces DODA, pendientes de facturar y cartera
vencida. Corre sola en el reloj (no depende del iPhone para funcionar), guarda
la última foto en caché y alimenta una complicación en la esfera.

## Qué trae

| Pieza | Qué hace |
|---|---|
| Pantalla **Hoy** | KPIs del día, barra de cartera vencida y alertas abiertas |
| Pantalla **Pedimentos** | Lista con semáforo por estatus; filtro "solo pendientes"; detalle por pedimento |
| Pantalla **Cartera** | Saldo, vencido y antigüedad por cliente, con semáforo a 45 y 90 días |
| Pantalla **Ajustes** | Modo en uso, antigüedad del dato y refresco manual |
| **Complicación** | Circular, esquina, en línea y rectangular; lee la caché, no la red |
| **Refresco en segundo plano** | Cada N minutos baja la instantánea y recarga la esfera |
| **App de iPhone** | Único lugar donde se teclea servidor y token; los manda al reloj por WatchConnectivity |

La app es de solo lectura. Ningún camino escribe en Darwin desde el reloj.

## Requisitos

- Mac con Xcode 15 o superior (watchOS 10 / iOS 17)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Node 18+ solo si quieres el servidor de datos falso

## Correrla

```bash
cd apps/ryr-watch
make proyecto        # genera RyROperativo.xcodeproj
open RyROperativo.xcodeproj
```

Elige el esquema **RyROperativoWatch**, un simulador de Apple Watch y corre.
Arranca en modo demostración: se ve la interfaz completa con datos de muestra,
sin backend.

Para verla contra datos vivos:

```bash
make mock            # http://localhost:8787, token: demo-token
```

Luego corre el esquema **RyROperativoiPhone**, apaga "Modo demostración",
captura `http://localhost:8787` y el token, prueba la conexión y pulsa
"Enviar al reloj".

## Pruebas

```bash
make prueba          # pruebas unitarias del núcleo (swift test)
make verificar       # el JSON del servidor contra los CodingKeys de Swift
```

`make verificar` levanta el mock, pide cada endpoint y compara llave por llave
contra los `CodingKeys` de `Modelos.swift`. Si el backend renombra un campo,
esto lo marca antes de que la pantalla aparezca vacía en el reloj.

## Contrato del API

Todas las rutas piden `Authorization: Bearer <token>` y responden JSON.
Las fechas van en ISO 8601 (`2026-09-20T14:30:00Z`); también se acepta
`2026-09-20`.

| Método | Ruta | Devuelve |
|---|---|---|
| GET | `/v1/salud` | `{ ok, version }` — no pide token |
| GET | `/v1/resumen` | `ResumenDia` |
| GET | `/v1/pedimentos?limite=40` | `[Pedimento]` |
| GET | `/v1/pedimentos/{id}` | `Pedimento` |
| GET | `/v1/cartera` | `[ClienteCartera]` |

```jsonc
// ResumenDia
{
  "fecha": "2026-09-20T14:30:00Z",
  "pedimentos_del_dia": 12,
  "cruces_doda": 7,
  "pendientes_facturar": 4,
  "cartera_total_mxn": 2743520.00,
  "cartera_vencida_mxn": 1069000.00,
  "alertas": [{ "id": "a1", "titulo": "...", "detalle": "...", "severidad": "critica" }]
}

// Pedimento
{
  "id": "5000123",
  "numero": "264037215000123",
  "patente": "3721", "aduana": "400", "clave": "A1",
  "cliente": "POCHTECA MATERIAS PRIMAS", "cliente_id": 29,
  "estatus": "cruzado",            // capturado|pagado|modulado|cruzado|facturado|detenido
  "valor_usd": 184320.55,
  "fecha_pago": "2026-09-20T14:45:09Z",
  "modulado_en": "2026-09-20T19:45:09Z",
  "doda": "DODA-8821-4417",
  "facturado": false
}

// ClienteCartera
{ "id": 883, "cliente": "UNIVAR SOLUTIONS MEXICO", "saldo_mxn": 1842300.00,
  "vencido_mxn": 940100.00, "documentos": 14, "dias_promedio": 96 }
```

Un `estatus` que el backend invente y Swift no conozca se decodifica como
`desconocido`: no tumba la lista completa.

## Para conectarla a Darwin

El reloj no habla con SQL Server. Falta un servicio que exponga las cinco rutas
de arriba leyendo Darwin; `tools/mock-server/server.js` sirve de plantilla del
contrato. Ese servicio es el único punto que necesita credenciales de base de
datos.

## Estructura

```
Core/            paquete Swift: modelos, cliente REST, cliente demo, caché, store y pruebas
Watch/           app de watchOS (SwiftUI)
Widget/          complicación (WidgetKit)
iOS/             app de iPhone para configurar servidor y token
Compartido/      puente WatchConnectivity
Recursos/        Info.plist, entitlements y catálogo de recursos generados por XcodeGen
tools/           servidor de datos falso y verificador del contrato
```

## Estado de verificación

- **Medido aquí:** el servidor mock levanta y sirve las cinco rutas; el
  verificador de contrato pasa las cinco comprobaciones (4 tipos + el 401).
- **No compilado aquí:** el código Swift. Este entorno es Linux, sin Xcode ni
  toolchain de Swift, así que `make prueba` y `make simulador` están pendientes
  de correrse en una Mac.
