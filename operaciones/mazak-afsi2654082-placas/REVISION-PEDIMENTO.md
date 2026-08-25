# Revisión (glosa previa) — Pedimento 6000025 · A1 · 1941 · MAZAK placas de aluminio
**26 40 1941 6000025 · Ref. AFSI2654082 · corresponsalía AFS Agencia Aduanal · 25-ago-2026**

Semáforo: 🔴 bloquea validación · 🟠 corregir antes de pagar · 🟡 verificar/documentar

> **Alcance reducido (25-ago-2026).** De las 4 placas del embarque sólo se importan **2** —
> una por factura. De la factura de la partida 1, que ampara 3 piezas, sólo entra la del
> **lote 706332C4**; las 2 *fixture plates* quedan pendientes. Esto vuelve al conflicto de
> lotes el problema central del pedimento: ver hallazgo 2.

---

## 🔴 Bloqueantes

**1. Las dos facturas traen el mismo folio y una fecha incoherente.**
F1 y F2 declaran ambas `INVOICE # CDS TEST` con fecha impresa **4/19/2024**, mientras el
packing list dice **08/17/26**. Dos COVE distintos no pueden compartir folio de factura,
y una factura de 2024 para mercancía arribada en agosto de 2026 es una inconsistencia que
la autoridad puede observar (art. 36-A fr. I LA). Peor todavía: el pedimento **BA 6000024** del
herramental ya declaró en su relación de facturas ese mismo folio `CDS TEST` (20-08-2026, USD
41,826.00), así que el mismo folio quedaría en tres declaraciones distintas del mismo importador y
proveedor. **Pedir a AFS/Mazak facturas con folios distintos (p. ej. `CDS TEST-1` y `CDS TEST-2`)
y fecha 17-ago-2026** antes de transmitir COVE.

**2. Las dos únicas piezas del pedimento declaran el mismo lote 706332C4.**
Con el alcance reducido, el pedimento queda con dos partidas de una pieza cada una y **las dos
dicen lote 706332C4**. El aviso 1931AL26073388 desglosa las 4 placas así: 1 pza lote **657231B7**
(colada 558), 2 pzas lote **660681B8** (colada 714), 1 pza lote **706332C4** (colada 714) — o sea
que del lote 706332C4 **sólo existe una placa**. Tal como está, el pedimento declararía dos veces
la misma pieza. Una de las dos líneas debe decir **657231B7**, o bien confirmarse cuál de las dos
placas es la que realmente sale. Antes esto era una inconsistencia documental; ahora es el
problema central. **Sin resolverlo no se puede transmitir COVE.**

**3. Encargo conferido para la patente 1941.**
AFS informó el 13-ago-2026 que "se solicitó dar de alta unas patentes de respaldo y
estamos en espera de recibir cartas". **Verificar en VUCEM que MAZAK MÉXICO tenga
aceptado y vigente el encargo conferido a la patente 1941** (art. 59 fr. III LA / regla
1.2.2 RGCE) antes de validar. Sin él, el pedimento no procede.

---

## 🟠 Corregir antes de pagar

**4. No se ha pedido la certificación de origen T-MEC.**
Proveedor y mercancía son de Estados Unidos (el aviso declara país de origen, exportador
y de vertido = USA). Sin certificación de origen se paga **IGI 30 % = MXN 7,098.76**;
con ella el IGI es 0 y el total de la línea de captura baja de **12,769.92 a 4,535.36 MXN**
(**ahorro MXN 8,234.56**). Para la operación hermana del transformador (AFSI2654105) AFS
confirmó que no había T-MEC, pero **en esta nunca se preguntó**. Solicitarla a Mazak
Corporation; la certificación puede ir en la propia factura (Anexo 5-A T-MEC).
Ojo: el principal país de fundición es **Canadá** — también T-MEC, así que el origen
regional es defendible, pero quien certifica es el exportador.

**5. Los dos avisos se traslapan — no descargar ambos por la misma mercancía.**
1931AL26073388 ya ampara las **4** placas (81.64 kg / USD 1,400). El 1931AL26077729 se
tramitó el 21-ago para "la última placa" y vuelve a amparar el lote 706332C4.
Si se descargan los dos completos se declararía más permiso que mercancía.
**Solución adoptada en la hoja de captura:** dos partidas —
partida 1 descarga 61.23 kg / USD 1,050 contra 1931AL26073388 y partida 2 descarga
20.41 kg / USD 350 contra 1931AL26077729. Total descargado 81.64 kg = total importado.
El aviso 1931AL26073388 queda con saldo de 20.41 kg / USD 350 (vigente hasta 18-dic-2026).

**6. Las 2 *fixture plates* quedan fuera — y cuando entren necesitarán aviso.**
AFS planteó el 21-ago que 2 placas no necesitaban aviso automático. Pero las dos facturas
declaran HTSUSA 7606.12.3030 para todas las líneas, AFS clasificó todo en **7606.12.99**
y el propio aviso 1931AL26073388 se tramitó **por las cuatro placas**. Las "fixture plates
for ISO Circle Diamond Square Test" son placas de la misma aleación 6061-T651, no artículos
manufacturados. Ya no entran en este pedimento, pero **cuando se importen necesitarán aviso**: el 1931AL26073388
queda con saldo de 61.23 kg / USD 1,050, suficiente para las tres piezas restantes y vigente
hasta el 18-dic-2026. Si alguien sostiene una clasificación distinta para las fixture plates,
debe emitirse dictamen arancelario por escrito antes de validar.

**7. Vinculación proveedor–importador.**
MAZAK CORPORATION y MAZAK MÉXICO son empresas hermanas (confirmado por AFS el 18-ago-2026).
El campo **VINCULACIÓN del pedimento debe ir en "SÍ"**, y la **manifestación de valor**
debe sustentar que la vinculación no influyó en el precio (arts. 67 y 68 LA).
El precio de USD 17.148/kg es congruente con mercado para 6061-T651, lo que ayuda,
pero hay que dejarlo documentado en la hoja de cálculo.

---

## 🟡 Verificar / documentar

**8. Tasa de IGI de la 7606.12.99.** La hoja de captura usa **30 %**, que es la tasa que
AFS comunicó el 14-ago-2026. Confirmar contra la TIGIE vigente (hubo modificaciones por
decreto del 29-dic-2025 y del 23-abr-2026) y contra el validador antes de pagar.

**9. Cuota mínima del DTA — resuelto.** 8 al millar sobre 23,663 da **189.30**, por debajo de
la cuota mínima. La cuota es **462.00**, verificada contra Darwin: todos los pedimentos A1 de
2026 con valor en aduana por debajo del umbral (~57,750 MXN) pagan 462.00, y el 6000001 de
Mazak, con 76,610, sí paga 8 al millar (613). El pedimento declara 462.00.

**10. Tipo de cambio.** Se usó **16.9018** (DOF publicado 24-ago-2026), aplicable si el
pago se hace el **25-ago-2026** (art. 20 CFF). Corrobora el precedente: el BA 6000024, pagado
el 24-ago, usó 16.9583, que es el publicado el 21-ago. Si el pago se recorre, recalcular todo.

**11. Padrón de importadores de sectores específicos.** Verificar que MAZAK MÉXICO esté
inscrito en el sector aplicable a productos de aluminio (Anexo 10 RGCE) además del padrón
general.

**12. Tax ID del proveedor — resuelto.** MAZAK CORPORATION tiene Tax ID **11-2161864**, ya
declarado en los pedimentos 6000001 (A1, transformador) y 6000024 (BA, herramental) de la misma
patente. Reutilizarlo; no hace falta pedirlo otra vez.

**13. Bultos y peso bruto — recalcular tras la separación.** El pedimento declara 2 bultos y
**45.36 kg brutos**, cifra provisional: se tomó la caja de una sola placa (50 lb) como unidad,
porque la caja grande traía las 3 piezas de la factura 1 y ahora sólo sale una. Cuadrar con Baja
Forwarding cuando separen físicamente el embarque. El peso neto sí está firme:
2 × 20.41 = **40.82 kg**.

**19. Factura de la partida 1 subdividida.** La factura ampara 3 piezas por USD 1,050 y el
pedimento declara 1 pieza por USD 350 (marcada `Subdividida=1` en Darwin). Pedir a AFS la
factura reexpedida por lo que efectivamente se importa; junto con el folio duplicado del
hallazgo 1, es la misma petición.

**14. Separación del herramental.** Correcto que las placas vayan en A1 definitivo: son
consumibles ("perishable items"), no retornan en el mismo estado y por eso no caben en el
BA (art. 106 LA), como quedó asentado el 5-ago-2026. El herramental sigue su propio
pedimento BA con los escritos del art. 106 fr. II inciso a) y el aviso en Ventanilla Digital
(regla 4.2.2 RGCE).

**15. Manifestación de valor y transporte.** Integrar manifestación de valor + hoja de
cálculo (art. 59 fr. III LA, regla 1.5.1) y el documento de transporte del tramo mexicano
(transportista, caja/placas) para la DODA.

**16. Número de pedimento y pool de números.** Se asigna **6000025**, primer libre del pool
`vt_numerospedi` de la patente 1941 / aduana 400 / 2026 (fila ID 125184). Ojo: el **6000024 sigue
en el pool** (fila ID 136168) pese a estar ya consumido por el BA del herramental — la baja manual
quedó pendiente desde el 24-ago. Dar de baja las dos filas por la interfaz para que nadie reutilice
un número.

**17. Coherencia con el BA 6000024.** El pedimento del herramental ya dejó asentado en observaciones
que *"las placas de aluminio 6061-T651 sin trabajar no van en este pedimento: se despachan en
definitivo por separado (aviso automático 1931AL26073388)"*. Este pedimento cierra esa referencia
cruzada, y sus observaciones lo dicen en sentido inverso. Ambos comparten referencia AFS
**AFSI2654082**, así que conviene distinguirlos por clave (A1 vs BA) en cualquier reporte.

**18. Fracciones en el catálogo del cliente.** En el BA quedó anotado que las fracciones no estaban
dadas de alta en el catálogo del cliente 1104. Verificar que **7606.12.99 NICO 00** esté dada de alta
antes de capturar las partidas.

---

## Cuadre final

| Concepto | Facturas | Avisos | Pedimento |
|---|---|---|---|
| Piezas | 4 | 4 (aviso 1) + 1 (aviso 2, traslapado) | 4 |
| Kilogramos | 81.64 | 81.64 + 20.41 | **81.64** |
| Valor USD | 1,400.00 | 1,400.00 + 350.00 | **1,400.00** |
| Descargo de permisos | — | — | 61.23 kg + 20.41 kg = **81.64 kg** ✔ |
