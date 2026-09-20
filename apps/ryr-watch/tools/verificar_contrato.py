#!/usr/bin/env python3
"""Compara las llaves JSON que sirve el mock contra los CodingKeys de Swift.

Un campo que el backend renombra y Swift ya no encuentra es el error más caro
de esta app: la pantalla se queda vacía sin decir por qué. Esto lo detecta
antes de abrir Xcode.
"""
import json
import os
import re
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELOS = os.path.join(RAIZ, "Core/Sources/RyRCore/Modelos.swift")
SERVIDOR = os.path.join(RAIZ, "tools/mock-server/server.js")
PUERTO = int(os.environ.get("PUERTO", "8799"))
TOKEN = "demo-token"


def llaves_swift(fuente: str) -> dict:
    """Devuelve {NombreStruct: set(llaves json)} leyendo los CodingKeys."""
    resultado = {}
    actual = None
    dentro = False
    for linea in fuente.splitlines():
        tipo = re.match(r"\s*public struct (\w+)", linea)
        if tipo:
            actual = tipo.group(1)
            resultado.setdefault(actual, set())
        if re.match(r"\s*enum CodingKeys", linea):
            dentro = True
            continue
        if dentro:
            if linea.strip() == "}":
                dentro = False
                continue
            con_alias = re.match(r"\s*case (\w+) = \"([^\"]+)\"", linea)
            simple = re.match(r"\s*case (\w+)\s*$", linea)
            if con_alias:
                resultado[actual].add(con_alias.group(2))
            elif simple:
                resultado[actual].add(simple.group(1))
    return {k: v for k, v in resultado.items() if v}


def llaves_sin_codingkeys(fuente: str, nombre: str) -> set:
    """Para structs sin CodingKeys, las llaves son los nombres de propiedad."""
    bloque = re.search(r"public struct " + nombre + r"[^{]*\{(.*?)\n\}", fuente, re.S)
    if not bloque:
        return set()
    return set(re.findall(r"public let (\w+):", bloque.group(1)))


def pedir(ruta: str):
    peticion = urllib.request.Request(
        f"http://127.0.0.1:{PUERTO}{ruta}", headers={"Authorization": f"Bearer {TOKEN}"}
    )
    with urllib.request.urlopen(peticion, timeout=5) as r:
        return json.load(r)


def main() -> int:
    fuente = open(MODELOS, encoding="utf-8").read()
    esperadas = llaves_swift(fuente)
    esperadas["Alerta"] = llaves_sin_codingkeys(fuente, "Alerta")

    servidor = subprocess.Popen(
        ["node", SERVIDOR],
        env={**os.environ, "PUERTO": str(PUERTO), "TOKEN": TOKEN},
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT,
    )
    try:
        for _ in range(50):
            try:
                pedir("/v1/salud")
                break
            except (urllib.error.URLError, ConnectionError):
                time.sleep(0.1)
        else:
            print("FALLA: el mock no levantó")
            return 1

        casos = [
            ("ResumenDia", pedir("/v1/resumen")),
            ("Alerta", pedir("/v1/resumen")["alertas"][0]),
            ("Pedimento", pedir("/v1/pedimentos?limite=40")[0]),
            ("ClienteCartera", pedir("/v1/cartera")[0]),
        ]

        fallas = 0
        for tipo, objeto in casos:
            servidas = set(objeto.keys())
            quiere = esperadas.get(tipo, set())
            faltantes = quiere - servidas
            sobrantes = servidas - quiere
            estado = "OK  " if not faltantes else "FALLA"
            print(f"{estado} {tipo}: {len(quiere)} llaves esperadas, {len(servidas)} servidas")
            if faltantes:
                print(f"      faltan en el servidor: {sorted(faltantes)}")
                fallas += 1
            if sobrantes:
                print(f"      extra (Swift las ignora): {sorted(sobrantes)}")

        # El 401 también es parte del contrato: la app lo traduce a "token rechazado".
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{PUERTO}/v1/cartera", timeout=5)
            print("FALLA: sin token debió responder 401")
            fallas += 1
        except urllib.error.HTTPError as e:
            estado = "OK  " if e.code == 401 else "FALLA"
            print(f"{estado} sin token responde {e.code}")
            if e.code != 401:
                fallas += 1

        print("\nContrato verificado." if not fallas else f"\n{fallas} diferencia(s).")
        return 0 if not fallas else 1
    finally:
        servidor.send_signal(signal.SIGTERM)
        servidor.wait(timeout=5)


if __name__ == "__main__":
    sys.exit(main())
