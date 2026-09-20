# Atajos del proyecto. Xcode y el simulador solo existen en una Mac.

SIM_RELOJ ?= Apple Watch Series 10 (46mm)

.PHONY: proyecto prueba formulas simulador limpiar

## Genera Recomp.xcodeproj a partir de project.yml
proyecto:
	xcodegen generate

## Pruebas unitarias del núcleo
prueba:
	swift test --package-path Core

## Verifica la aritmética del plan contra la referencia en Python
formulas:
	python3 tools/verificar_formulas.py

## Regenera el banco de casos que comparten Swift y Python
formulas-generar:
	python3 tools/verificar_formulas.py --generar

## Compila la app del reloj para el simulador
simulador: proyecto
	xcodebuild -project Recomp.xcodeproj \
		-scheme RecompWatch \
		-destination 'platform=watchOS Simulator,name=$(SIM_RELOJ)' \
		build

limpiar:
	rm -rf Recomp.xcodeproj Core/.build build
