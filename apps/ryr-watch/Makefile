# Atajos del proyecto. Todo esto corre en una Mac con Xcode 15 o superior.

SIM_RELOJ ?= Apple Watch Series 10 (46mm)

.PHONY: proyecto prueba mock verificar simulador limpiar

## Genera RyROperativo.xcodeproj a partir de project.yml
proyecto:
	xcodegen generate

## Pruebas unitarias del núcleo (no requiere Xcode abierto)
prueba:
	swift test --package-path Core

## Servidor de datos falso en http://localhost:8787
mock:
	node tools/mock-server/server.js

## Verifica que el JSON del servidor cuadre con los CodingKeys de Swift
verificar:
	python3 tools/verificar_contrato.py

## Compila la app del reloj para el simulador
simulador: proyecto
	xcodebuild -project RyROperativo.xcodeproj \
		-scheme RyROperativoWatch \
		-destination 'platform=watchOS Simulator,name=$(SIM_RELOJ)' \
		build

limpiar:
	rm -rf RyROperativo.xcodeproj Core/.build build
