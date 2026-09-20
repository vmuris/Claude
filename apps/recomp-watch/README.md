# Recomp — app de Apple Watch para perder grasa y ganar músculo

App nativa de watchOS que junta las cuatro cosas que deciden la
recomposición corporal — comida, proteína, sueño y entrenamiento — y las
convierte en un solo número diario. Corre sola en el reloj y guarda todo en
Salud (HealthKit). Nada sale del dispositivo: no hay servidor ni cuenta.

> **Aviso.** Las fórmulas y rangos son de uso común en nutrición deportiva,
> no consejo médico. Si tienes cualquier condición de salud, o tomas
> medicamento, revísalo con tu médico antes de seguir el plan.

## Lo que el reloj sí mide y lo que no

| Dato | De dónde sale |
|---|---|
| Sueño | HealthKit, lo que detecta el reloj al dormir con él |
| Energía activa y basal | HealthKit, medido por el reloj |
| Entrenamientos y pulso | HealthKit; la app además inicia sesiones de entrenamiento en vivo |
| Peso | Lo registras tú (o tu báscula, si escribe en Salud) |
| **Calorías y proteína que comes** | **Las registras tú.** Ningún reloj las mide |

Esa última línea es la que hace fracasar a la mayoría de estas apps. Por eso
el registro está diseñado para dos toques: cuatro atajos de porción y una
corona para afinar.

**La segunda trampa:** la energía activa del Apple Watch sobreestima el gasto
en trabajo de fuerza. Un plan que confíe en ese número te deja comiendo de
más. Aquí el gasto del reloj se muestra como dato del día, pero **quien manda
sobre el plan es la tendencia de tu peso.**

## Las cinco pantallas

| Pantalla | Qué hace |
|---|---|
| **Hoy** | Anillos de calorías y proteína restantes, puntaje del día, sueño, energía activa y déficit real |
| **Comer** | Registro en dos toques: atajos de porción o corona para el monto exacto |
| **Entrenar** | Inicia fuerza, caminata, carrera, bici o intervalos; pulso y energía en vivo; guarda el entrenamiento en Salud |
| **Cuerpo** | Pesarte, tendencia en %/semana, adherencia, sesiones de fuerza y deuda de sueño |
| **Plan** | Objetivos calculados, el ajuste sugerido y el perfil |

Más una **complicación** para la esfera: calorías y proteína que te quedan.

## Cómo se calcula el plan

1. **TMB** por Mifflin-St Jeor (1990), la ecuación estándar.
2. **Gasto estimado** = TMB × factor de actividad (1.2 a 1.9).
3. **Objetivo de calorías** = gasto × ajuste según objetivo, más la corrección acumulada.
4. **Piso de seguridad** = el mayor entre TMB × 1.1 y 1500 kcal (hombre) / 1200 kcal (mujer). Nunca se baja de ahí.

| Objetivo | Ajuste de energía | Proteína | Cambio de peso deseado |
|---|---|---|---|
| Perder grasa | −20 % | 2.2 g/kg | −1.0 % a −0.5 % por semana |
| Recomposición | −12 % | 2.0 g/kg | −0.75 % a −0.25 % por semana |
| Ganar músculo | +10 % | 1.8 g/kg | +0.125 % a +0.5 % por semana |

Grasa fija en 0.8 g/kg; el resto de las calorías son carbohidratos.

### El puntaje del día (0 a 100)

| Componente | Puntos | Cómo se ganan |
|---|---|---|
| Calorías | 30 | Dentro de ±10 % del objetivo (15 puntos si ±20 %) |
| Proteína | 30 | 100 % del objetivo (20 si ≥90 %, 10 si ≥75 %) |
| Sueño | 25 | Llegar a tu meta (15 si te falta 1 h, 5 si faltan 2 h) |
| Movimiento | 15 | Llegar a tu meta de energía activa (8 si ≥60 %) |

### El ajuste semanal

Cada semana, la app compara tu tendencia de peso con el rango del objetivo:

- Cambias **menos** de lo debido → **−150 kcal**
- Cambias **más rápido** de lo debido → **+150 kcal** (proteger músculo)
- Dentro del rango → **no toca nada**

Con tres candados: mínimo 7 días de báscula, un solo ajuste por semana, y un
tope acumulado de ±500 kcal. El ajuste se **propone**; tú lo aplicas.

La tendencia promedia los tres primeros y los tres últimos pesos de la
ventana, porque media hora de sal mueve la báscula medio kilo y eso no debe
mover tu plan.

## Correrla

```bash
cd apps/recomp-watch
make proyecto        # requiere xcodegen: brew install xcodegen
open Recomp.xcodeproj
```

HealthKit necesita **reloj físico** para dar datos de verdad (el simulador no
tiene sueño ni pulso). En el simulador la app abre y navega, pero los números
llegan vacíos hasta que siembres datos en Salud.

## Pruebas

```bash
make formulas        # aritmética del plan contra la referencia en Python
make prueba          # pruebas unitarias del núcleo (swift test)
```

`tools/verificar_formulas.py` reimplementa las fórmulas por separado y las
compara contra el mismo banco de casos que consumen las pruebas de Swift
(`Core/Tests/RecompCoreTests/Recursos/casos_formulas.json`). Si Swift y la
referencia se separan en un solo gramo, las pruebas lo dicen.

## Estructura

```
Core/       paquete Swift: modelos, aritmética del plan, store y pruebas
Salud/      HealthKit: lectura, escritura y sesión de entrenamiento en vivo
Watch/      app de watchOS (SwiftUI)
Widget/     complicación
Recursos/   Info.plist, entitlements y catálogo, generados por XcodeGen
tools/      referencia en Python de la aritmética
```

## Estado de verificación

- **Medido aquí:** la aritmética. 13 anclas calculadas a mano (TMB, objetivo,
  proteína, grasa, carbohidratos para tres perfiles) y 15 casos del banco
  compartido, todos en verde con `python3 tools/verificar_formulas.py`.
- **No compilado aquí:** el código Swift. El entorno es Linux, sin Xcode ni
  toolchain de Swift, así que `make prueba` y `make simulador` faltan por
  correrse en una Mac.
