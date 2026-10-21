---
name: captura-exportacion-darwin
description: Reglas obligatorias para capturar, consolidar y auditar pedimentos de exportación A1 en Darwin (patentes 3721 y 1941). Úsala al recibir el primer aviso de un cliente con intención de exportar, al precapturar o revisar pedimentos de exportación, y al auditar lo que capturó el usuario AGENTE contra lo que despachó Karina Alarcón (alarcon85).
---

# Captura de pedimentos de exportación en Darwin

Reglas aprendidas del caso del 20-oct-2026. El usuario `AGENTE` abrió pedimentos separados para
CFDI adicionales o sustitutos del mismo exportador:
- 6013205 (Rasave): CFDI sustituto en lugar de actualizar la base 6013199.
- 6013207 (Magoni): segunda factura en lugar de agregarla a la base 6013202.

Karina Alarcón (`alarcon85`) despachó cada exportador en un solo pedimento con todas sus facturas.
Ejemplo: 6012121 de Bodegas Magoni lleva 3 UUID en 11 partidas. Ese es el criterio correcto.

## Regla 1. Un exportador, un pedimento

1. Si un mismo exportador (mismo RFC emisor del CFDI) manda más de una factura para exportar,
   todas van en **el mismo pedimento**. No se abre un pedimento por factura.
2. Antes de crear un pedimento, busca en Darwin si ya hay una base abierta del mismo cliente:
   - que no tenga firma (`FirmaPedimento` nulo o vacío) ni `FechaValidacion`;
   - con la misma clave (A1), la misma aduana y la misma patente.
   Si existe, agrega ahí las partidas del nuevo CFDI, con su UUID en `vt_partidas.Factura`.
3. **CFDI sustituto** (el cliente cancela y reexpide): reemplaza el UUID y las partidas del
   CFDI cancelado en el mismo pedimento. Nunca abras otro pedimento por el sustituto.
4. Cada partida debe llevar el UUID de su CFDI. Una partida con `Factura` vacía es un pendiente
   que se resuelve antes de validar.
5. Si ya existe un duplicado, repórtalo para cancelarlo; no lo borres tú.
   Duplicado: otro pedimento sin firma del mismo cliente y con el mismo CFDI.
6. Supuesto: la consolidación aplica a facturas del mismo despacho, con la misma aduana, clave
   y cruce. Si el cliente indica cruces distintos, se pregunta antes de consolidar.

Query para buscar la base abierta del cliente (formato WAF-safe; ver skill `darwin-query-assistant`):

```sql
SELECT p.ID, p.Pedimento, p.Clave, p.Usuario, p.FechaPedimento, p.Referencia,
       p.ValorDolares, p.Bultos, cli.Nombre AS Cliente
FROM vt_pedimentos p
LEFT JOIN vt_clientes cli ON cli.ID=p.Cliente AND cli.Oficina=p.Oficina
WHERE p.Oficina=0x52595231 AND p.Tipo=2 AND p.Cliente=<ID>
  AND p.FechaValidacion IS NULL AND p.ID > <ID de hace 30 días>
ORDER BY p.ID DESC
```

## Regla 2. Validaciones en el primer aviso del cliente

Cuando el cliente manda el primer aviso de intención de exportar, **antes de capturar**,
revisa estos cuatro puntos y deja constancia del resultado:

| # | Revisión | Fuente | Si no cumple |
|---|---|---|---|
| 1 | Cada CFDI está **vigente** en el SAT. Un CFDI cancelado se rechaza. | Verificación de CFDI del SAT: UUID, RFC emisor, RFC receptor y total | No se captura; se pide el CFDI sustituto |
| 2 | El CFDI es de exportación: `Exportacion=02` y complemento de comercio exterior. El RFC emisor es el del exportador del pedimento. | XML del CFDI | Se regresa al cliente para corrección |
| 3 | **Opinión de cumplimiento** (art. 32-D CFF) en sentido **positivo** y emitida dentro de la vigencia que marca la RMF. | PDF que manda el cliente o consulta con su e.firma | No se despacha; se avisa al cliente y al responsable de la cuenta |
| 4 | **Padrón de Exportadores Sectorial** activo en el sector que corresponde a la fracción que se exporta. Ver Anexo 10, fracción II, RGCE vigente. | Darwin `vt_clientesectores` (Tipo=2) más la constancia o consulta en el SAT | No se despacha la mercancía del sector |

Sectores frecuentes en la cartera:
- **Sector 4**, bebidas alcohólicas fermentadas (vinos): incluye 2204.10.02, 2204.21.04, 2204.29.99 y 2204.30.91.
- **Sector 9**, oro, plata y cobre (por ejemplo, Nacional de Cobre).

Verifica la fracción exacta contra el Anexo 10 publicado en el DOF del año en curso.

El registro en `vt_clientesectores` es un dato de Darwin, no la situación vigente en el SAT. Una
suspensión del padrón no se ve ahí. Márcalo como **inferido** hasta confirmarlo con la constancia o
con la consulta en el SAT.

Query del padrón sectorial que registra Darwin:

```sql
SELECT cli.ID, cli.Nombre, cli.RFC, GROUP_CONCAT(DISTINCT s.Sector) AS Sectores
FROM vt_clientes cli
LEFT JOIN vt_clientesectores s ON s.Cliente=cli.ID AND s.Oficina=cli.Oficina AND s.Tipo=2
WHERE cli.Oficina=0x52595231 AND cli.ID IN (<IDs>)
GROUP BY cli.ID, cli.Nombre, cli.RFC
```

## Regla 3. Auditoría diaria: AGENTE contra el despacho de Karina

1. Universo: los pedimentos `Tipo=2` validados o creados en el día (bitácora `VT_Pedimentos`).
2. Por cada pedimento, identifica la base 6013xxx de la que se copió (`EsCopia=1`). La base y la
   copia coinciden en valor, bultos y partidas.
3. Mide:
   - las partidas que Karina insertó a mano (`vt_bitacora`, `Archivo='VT_Partidas'`, `Accion=1`,
     `Procedimiento='RegistrarPartidas'`, `Usuario='alarcon85'`);
   - las filas que escribió `AGENTE` (`BRW15.UpdateViewRecord`).
4. Clasifica cada pedimento:
   - ✅ Agente: Karina capturó 0 partidas.
   - 🟡 Parcial: los dos capturaron partidas.
   - ❌ Sin agente: no hay base del agente, o Karina capturó todo.
5. Compara partida por partida los pedimentos sueltos que abrió AGENTE contra el despacho final.
   Fracción, cantidad, valor y UUID deben coincidir. Una diferencia en un pedimento ya validado
   es un hallazgo 🔴 y puede requerir rectificación.

## Formato de entrega

Tabla por pedimento con:
- cliente, USD y número de partidas;
- base del agente;
- partidas que capturó Karina;
- resultado;
- revisión del CFDI vigente, la opinión 32-D y el padrón sectorial.

Los totales se recalculan desde las partidas. Cada dato se marca como medido o inferido.
