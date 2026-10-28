#!/bin/sh
# Chequeo rápido: compila todos los scripts y corre el juego unos segundos en modo headless.
# Uso: sh tools/check.sh [segundos_de_juego]
cd "$(dirname "$0")/.." || exit 1
GD="${GODOT:-godot}"   # ruta al ejecutable de Godot 4.7 (variable de entorno GODOT)
echo "== compilando scripts"
timeout 120 "$GD" --headless --path . -- --check 2>&1 | grep -E "ERROR|SCRIPT ERROR|Parse Error|parse error|CHECK DONE|at: res://|^\s+at:" | head -60
echo "== corriendo juego ${1:-5}s (autotest)"
timeout 120 "$GD" --headless --path . -- --autotest=${1:-5} 2>&1 | grep -E "ERROR|SCRIPT ERROR|Invalid|AUTOTEST|at: res://" | grep -v "falta el módulo" | head -60
if [ "$2" = "net" ]; then
	echo "== prueba de red (anfitrión + cliente en 127.0.0.1)"
	timeout 60 "$GD" --headless --path . -- --nettest=host > /tmp/gw_host.log 2>&1 &
	sleep 1
	timeout 60 "$GD" --headless --path . -- --nettest=client 2>&1 | grep -E "NETTEST client (t=13|DONE|state)|ERROR|at: res://"
	wait
	grep -E "NETTEST host (t=11|DONE)|ERROR|at: res://" /tmp/gw_host.log
fi
