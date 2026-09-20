#!/usr/bin/env python3
"""Referencia independiente de la aritmética del plan.

Reimplementa las fórmulas de Core/Sources/RecompCore/Calculo.swift y las
compara contra el banco de casos que también consumen las pruebas de Swift.
Así los números quedan verificados aunque no haya compilador de Swift a mano.

  python3 tools/verificar_formulas.py             # verifica
  python3 tools/verificar_formulas.py --generar   # reescribe el banco de casos
"""
import json
import math
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANCO = os.path.join(RAIZ, "Core/Tests/RecompCoreTests/Recursos/casos_formulas.json")

FACTOR = {"sedentario": 1.2, "ligero": 1.375, "moderado": 1.55, "alto": 1.725, "muyAlto": 1.9}
AJUSTE = {"perderGrasa": -0.20, "recomposicion": -0.12, "ganarMusculo": 0.10}
PROTEINA_KG = {"perderGrasa": 2.2, "recomposicion": 2.0, "ganarMusculo": 1.8}
RANGO = {"perderGrasa": (-1.0, -0.5), "recomposicion": (-0.75, -0.25), "ganarMusculo": (0.125, 0.5)}
PASO = 150.0
TOPE = 500.0


def redondear(x):
    """Swift usa .rounded(): medio hacia arriba en magnitud, no banquero."""
    return int(math.floor(x + 0.5)) if x >= 0 else int(math.ceil(x - 0.5))


def tmb(p):
    base = 10 * p["pesoKg"] + 6.25 * p["estaturaCm"] - 5 * p["edad"]
    return base + 5 if p["sexo"] == "hombre" else base - 161


def objetivos(p):
    t = tmb(p)
    gasto = t * FACTOR[p["nivel"]]
    piso = max(t * 1.1, 1500 if p["sexo"] == "hombre" else 1200)
    bruto = gasto * (1 + AJUSTE[p["objetivo"]]) + p.get("ajusteAcumuladoKcal", 0)
    energia = redondear(max(bruto, piso))
    proteina = redondear(p["pesoKg"] * PROTEINA_KG[p["objetivo"]])
    grasa = redondear(p["pesoKg"] * 0.8)
    carbos = max(0, redondear((energia - proteina * 4 - grasa * 9) / 4))
    return {
        "tmb": round(t, 4),
        "gastoEstimado": round(gasto, 4),
        "piso": round(piso, 4),
        "energiaKcal": energia,
        "proteinaG": proteina,
        "grasaG": grasa,
        "carbosG": carbos,
    }


def puntaje(dia, obj, p):
    e = 0
    if dia["energiaConsumida"] > 0 and obj["energiaKcal"] > 0:
        d = abs(dia["energiaConsumida"] - obj["energiaKcal"]) / obj["energiaKcal"]
        e = 30 if d <= 0.10 else (15 if d <= 0.20 else 0)

    r = dia["proteinaConsumida"] / obj["proteinaG"] if obj["proteinaG"] > 0 else 0
    pr = 30 if r >= 1.0 else (20 if r >= 0.9 else (10 if r >= 0.75 else 0))

    h, meta = dia["horasSueno"], p["horasSuenoObjetivo"]
    s = 25 if h >= meta else (15 if h >= meta - 1 else (5 if h >= meta - 2 else 0))

    a = dia["energiaActiva"] / p["metaEnergiaActiva"] if p["metaEnergiaActiva"] > 0 else 0
    m = 15 if a >= 1.0 else (8 if a >= 0.6 else 0)

    return {"energia": e, "proteina": pr, "sueno": s, "movimiento": m, "total": e + pr + s + m}


def cambio_semanal(t):
    if t["dias"] <= 0 or t["pesoInicialKg"] <= 0:
        return 0.0
    return (t["pesoFinalKg"] - t["pesoInicialKg"]) / t["pesoInicialKg"] * 100 * (7.0 / t["dias"])


def ajuste(p, t):
    if t["dias"] < 7:
        return 0
    cambio = cambio_semanal(t)
    bajo, alto = RANGO[p["objetivo"]]
    if cambio > alto:
        propuesta = -PASO
    elif cambio < bajo:
        propuesta = PASO
    else:
        return 0
    acumulado = p.get("ajusteAcumuladoKcal", 0) + propuesta
    if abs(acumulado) > TOPE:
        permitido = (TOPE if acumulado > 0 else -TOPE) - p.get("ajusteAcumuladoKcal", 0)
        if abs(permitido) < 1:
            return 0
        propuesta = permitido
    return redondear(propuesta)


def perfil(**kw):
    base = {
        "sexo": "hombre", "edad": 35, "estaturaCm": 175, "pesoKg": 80,
        "nivel": "moderado", "objetivo": "recomposicion",
        "horasSuenoObjetivo": 7.5, "metaEnergiaActiva": 500, "ajusteAcumuladoKcal": 0,
    }
    base.update(kw)
    return base


def dia(**kw):
    base = {
        "energiaConsumida": 0, "proteinaConsumida": 0, "energiaActiva": 0,
        "energiaBasalMedida": 0, "horasSueno": 0,
    }
    base.update(kw)
    return base


# --- Anclas calculadas a mano. Si estas fallan, la fórmula está mal. ---
ANCLAS = [
    # Mifflin hombre: 10*92 + 6.25*178 - 5*38 + 5 = 1847.5
    # TDEE: 1847.5 * 1.55 = 2863.625 ; objetivo: *0.88 = 2519.99 -> 2520
    # proteína: 92*2.0 = 184 ; grasa: 92*0.8 = 73.6 -> 74
    # carbos: (2520 - 736 - 666)/4 = 279.5 -> 280
    (perfil(sexo="hombre", edad=38, estaturaCm=178, pesoKg=92, nivel="moderado",
            objetivo="recomposicion"),
     {"tmb": 1847.5, "energiaKcal": 2520, "proteinaG": 184, "grasaG": 74, "carbosG": 280}),
    # Mifflin mujer: 700 + 1031.25 - 150 - 161 = 1420.25
    # TDEE: *1.375 = 1952.84375 ; objetivo bruto: *0.80 = 1562.275
    # piso: 1420.25*1.1 = 1562.275 -> el piso manda (empate exacto) -> 1562
    (perfil(sexo="mujer", edad=30, estaturaCm=165, pesoKg=70, nivel="ligero",
            objetivo="perderGrasa"),
     {"tmb": 1420.25, "energiaKcal": 1562, "proteinaG": 154, "grasaG": 56}),
    # Mifflin hombre: 10*70 + 6.25*180 - 5*25 + 5 = 700 + 1125 - 125 + 5 = 1705
    # TDEE: 1705 * 1.725 = 2941.125 ; objetivo: *1.10 = 3235.2375 -> 3235
    (perfil(sexo="hombre", edad=25, estaturaCm=180, pesoKg=70, nivel="alto",
            objetivo="ganarMusculo"),
     {"tmb": 1705.0, "energiaKcal": 3235, "proteinaG": 126, "grasaG": 56}),
]


def construir_casos():
    casos = {"objetivos": [], "puntajes": [], "ajustes": []}

    perfiles = [
        ("hombre-recomp", perfil(sexo="hombre", edad=38, estaturaCm=178, pesoKg=92)),
        ("mujer-perder", perfil(sexo="mujer", edad=30, estaturaCm=165, pesoKg=70,
                                nivel="ligero", objetivo="perderGrasa")),
        ("hombre-ganar", perfil(sexo="hombre", edad=25, estaturaCm=180, pesoKg=70,
                                nivel="alto", objetivo="ganarMusculo")),
        ("mujer-sedentaria-piso", perfil(sexo="mujer", edad=45, estaturaCm=155, pesoKg=52,
                                         nivel="sedentario", objetivo="perderGrasa")),
        ("hombre-con-ajuste", perfil(sexo="hombre", edad=40, estaturaCm=170, pesoKg=85,
                                     ajusteAcumuladoKcal=-300)),
    ]
    for nombre, p in perfiles:
        casos["objetivos"].append({"nombre": nombre, "perfil": p, "esperado": objetivos(p)})

    p = perfil(sexo="hombre", edad=38, estaturaCm=178, pesoKg=92)
    obj = objetivos(p)
    dias = [
        ("dia-perfecto", dia(energiaConsumida=obj["energiaKcal"], proteinaConsumida=obj["proteinaG"],
                             energiaActiva=620, horasSueno=8.0)),
        ("dia-sin-registro", dia(horasSueno=6.9, energiaActiva=300)),
        ("dia-pasado-20", dia(energiaConsumida=obj["energiaKcal"] * 1.18,
                              proteinaConsumida=obj["proteinaG"] * 0.92,
                              energiaActiva=320, horasSueno=6.6)),
        ("dia-sin-dormir", dia(energiaConsumida=obj["energiaKcal"] * 0.95,
                               proteinaConsumida=obj["proteinaG"] * 0.8,
                               energiaActiva=120, horasSueno=4.0)),
    ]
    for nombre, d in dias:
        casos["puntajes"].append({"nombre": nombre, "perfil": p, "dia": d,
                                  "esperado": puntaje(d, obj, p)})

    tendencias = [
        ("pocos-dias", perfil(), {"pesoInicialKg": 92.0, "pesoFinalKg": 91.0, "dias": 3}),
        ("estancado", perfil(), {"pesoInicialKg": 92.0, "pesoFinalKg": 92.0, "dias": 14}),
        ("en-rango", perfil(), {"pesoInicialKg": 92.0, "pesoFinalKg": 91.54, "dias": 7}),
        ("muy-rapido", perfil(), {"pesoInicialKg": 92.0, "pesoFinalKg": 90.8, "dias": 7}),
        ("tope-alcanzado", perfil(ajusteAcumuladoKcal=-450),
         {"pesoInicialKg": 92.0, "pesoFinalKg": 92.2, "dias": 14}),
        ("ganar-lento", perfil(objetivo="ganarMusculo"),
         {"pesoInicialKg": 70.0, "pesoFinalKg": 70.02, "dias": 7}),
    ]
    for nombre, p2, t in tendencias:
        casos["ajustes"].append({
            "nombre": nombre, "perfil": p2, "tendencia": t,
            "cambioSemanalPorcentaje": round(cambio_semanal(t), 6),
            "esperado": ajuste(p2, t),
        })
    return casos


def main():
    generar = "--generar" in sys.argv
    fallas = 0

    print("Anclas calculadas a mano:")
    for p, esperado in ANCLAS:
        obtenido = objetivos(p)
        for llave, valor in esperado.items():
            ok = abs(obtenido[llave] - valor) < 0.001
            print(f"  {'OK  ' if ok else 'FALLA'} {p['sexo']}/{p['objetivo']} {llave}: "
                  f"{obtenido[llave]} (esperado {valor})")
            if not ok:
                fallas += 1

    casos = construir_casos()
    if generar:
        os.makedirs(os.path.dirname(BANCO), exist_ok=True)
        with open(BANCO, "w", encoding="utf-8") as f:
            json.dump(casos, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"\nBanco escrito: {os.path.relpath(BANCO, RAIZ)} "
              f"({sum(len(v) for v in casos.values())} casos)")
        return 1 if fallas else 0

    if not os.path.exists(BANCO):
        print("\nFALLA: no existe el banco de casos. Corre con --generar.")
        return 1

    with open(BANCO, encoding="utf-8") as f:
        guardado = json.load(f)

    print("\nBanco de casos contra la referencia:")
    for grupo in ("objetivos", "puntajes", "ajustes"):
        for guardado_caso, recalculado in zip(guardado[grupo], casos[grupo]):
            ok = guardado_caso == recalculado
            print(f"  {'OK  ' if ok else 'FALLA'} {grupo}/{guardado_caso['nombre']}")
            if not ok:
                fallas += 1
                print(f"        guardado:    {guardado_caso['esperado']}")
                print(f"        recalculado: {recalculado['esperado']}")
        if len(guardado[grupo]) != len(casos[grupo]):
            print(f"  FALLA {grupo}: el banco tiene {len(guardado[grupo])} casos "
                  f"y la referencia {len(casos[grupo])}")
            fallas += 1

    print("\nAritmética verificada." if not fallas else f"\n{fallas} diferencia(s).")
    return 1 if fallas else 0


if __name__ == "__main__":
    sys.exit(main())
