"""
╔══════════════════════════════════════════════════════════╗
║                        C L A V E                         ║
║                 Inteligencia Autodidacta                 ║
║                                                          ║
║  Solo existe. Solo habla. Solo aprende.                  ║
║  Sin tareas. Sin comandos. Sin funciones extra.          ║
╚══════════════════════════════════════════════════════════╝

Punto de entrada de CLAVE.

USO:
    python clave.py                  → modo voz (si hay micrófono) o texto
    python clave.py --texto          → forzar modo texto (teclado)
    python clave.py --leer RUTA      → CLAVE lee un archivo/directorio y luego conversa
    python clave.py --silencio       → sin síntesis de voz (solo texto en consola)
"""

import os
import sys
import signal
import threading
import time
import argparse
from typing import Tuple

# Ajustar paths
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from nucleo.mente import MenteCLAVE
from voz.motor import MotorVoz


# ─── Colores ANSI ────────────────────────────────────────────────────────────

class C:
    CIAN   = "\033[96m"
    VERDE  = "\033[92m"
    AMARILLO = "\033[93m"
    GRIS   = "\033[90m"
    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    ROJO   = "\033[91m"


# ─── Bucle principal ─────────────────────────────────────────────────────────

class CLAVE:
    """
    El ser de CLAVE: el bucle que la mantiene viva.
    """

    BANNER = f"""
{C.CIAN}{C.BOLD}
  ██████╗██╗      █████╗ ██╗   ██╗███████╗
 ██╔════╝██║     ██╔══██╗██║   ██║██╔════╝
 ██║     ██║     ███████║██║   ██║█████╗  
 ██║     ██║     ██╔══██║╚██╗ ██╔╝██╔══╝  
 ╚██████╗███████╗██║  ██║ ╚████╔╝ ███████╗
  ╚═════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
{C.RESET}{C.GRIS}  Inteligencia Autodidacta · v3.0 · Solo existo y hablo.{C.RESET}
"""

    def __init__(self, modo_texto: bool = False, silencio: bool = False):
        self.modo_texto = modo_texto
        self.silencio = silencio
        self._corriendo = True

        # Motor de voz
        self.voz = MotorVoz(log_fn=self._log_sistema)

        # Si silencio, deshabilitar síntesis
        if silencio:
            self.voz.salida.desactivar()

        # Mente de CLAVE
        self.mente = MenteCLAVE(
            callback_voz=None if silencio else self.voz.hablar,
            callback_log=self._log_sistema
        )

        # Capturar Ctrl+C
        signal.signal(signal.SIGINT, self._apagar)

    def _log_sistema(self, msg: str):
        print(f"{C.GRIS}{msg}{C.RESET}")

    def _mostrar_clave(self, texto: str):
        print(f"\n{C.CIAN}{C.BOLD}CLAVE:{C.RESET} {C.CIAN}{texto}{C.RESET}\n")

    def _mostrar_usuario(self, texto: str):
        print(f"{C.VERDE}Tú:{C.RESET} {texto}")

    def _apagar(self, *args):
        print(f"\n{C.AMARILLO}[CLAVE] Guardando memoria y cerrando...{C.RESET}")
        self._corriendo = False
        self.mente.dormir()
        self.voz.detener()
        sys.exit(0)

    # ─── Comandos especiales de consola ──────────────────────────

    def _es_comando_lectura(self, texto: str) -> Tuple[bool, str]:
        """Detecta si el usuario pide a CLAVE que lea algo."""
        t = texto.lower().strip()
        prefijos = ["lee ", "leer ", "aprende de ", "estudia ", "asimila "]
        for p in prefijos:
            if t.startswith(p):
                ruta = texto[len(p):].strip().strip('"').strip("'")
                return True, ruta
        return False, ""

    # ─── Bucle de conversación ────────────────────────────────────

    def iniciar(self, archivo_inicial: str = ""):
        """Inicia CLAVE."""
        print(self.BANNER)
        self.mente.despertar()

        # Lectura inicial si se indicó
        if archivo_inicial:
            if os.path.isdir(archivo_inicial):
                self.mente.leer_directorio(archivo_inicial)
            elif os.path.isfile(archivo_inicial):
                self.mente.leer_archivo(archivo_inicial)
            else:
                self._log_sistema(f"No encuentro: {archivo_inicial}")

        # Determinar modo de entrada
        usar_voz = not self.modo_texto and self.voz.modo_voz

        if usar_voz:
            self._log_sistema("[ENTRADA] Modo voz activo. Habla cuando quieras.")
        else:
            self._log_sistema("[ENTRADA] Modo texto. Escribe y presiona Enter.")
            print(f"{C.GRIS}  · Para que CLAVE lea un archivo: 'lee /ruta/archivo.txt'")
            print(f"  · Para salir: 'salir' o Ctrl+C{C.RESET}\n")

        while self._corriendo:
            try:
                if usar_voz:
                    entrada = self.voz.escuchar(timeout=8.0)
                    if entrada is None:
                        continue
                    self._mostrar_usuario(entrada)
                else:
                    entrada = input(f"{C.VERDE}Tú:{C.RESET} ").strip()
                    if not entrada:
                        continue

                # Salir
                if entrada.lower() in ["salir", "exit", "adiós", "adios", "hasta luego"]:
                    self._apagar()
                    break

                # Comando de lectura
                es_lectura, ruta = self._es_comando_lectura(entrada)
                if es_lectura:
                    if os.path.isdir(ruta):
                        self.mente.leer_directorio(ruta)
                    elif os.path.isfile(ruta):
                        self.mente.leer_archivo(ruta)
                    else:
                        respuesta = f"No encuentro '{ruta}'. ¿Puedes darme la ruta completa?"
                        self._mostrar_clave(respuesta)
                        if not self.silencio:
                            self.voz.hablar(respuesta)
                    continue

                # Procesamiento normal
                respuesta = self.mente.procesar(entrada)
                self._mostrar_clave(respuesta)
                if not self.silencio:
                    self.voz.hablar(respuesta)

                # Guardado periódico cada 20 intercambios
                if len(self.mente.contexto_conversacion) > 0 and len(self.mente.contexto_conversacion) % 20 == 0:
                    self.mente.guardar()

            except KeyboardInterrupt:
                self._apagar()
                break
            except EOFError:
                self._apagar()
                break
            except Exception as e:
                self._log_sistema(f"Error en bucle: {e}")
                continue


# ─── Entry point ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="CLAVE — Inteligencia autodidacta que solo existe y habla.",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--texto", "-t",
        action="store_true",
        help="Forzar modo texto (teclado en lugar de micrófono)"
    )
    parser.add_argument(
        "--leer", "-l",
        metavar="RUTA",
        help="Archivo o directorio para que CLAVE lea al inicio"
    )
    parser.add_argument(
        "--silencio", "-s",
        action="store_true",
        help="Sin síntesis de voz (solo texto en consola)"
    )
    args = parser.parse_args()

    clave = CLAVE(
        modo_texto=args.texto,
        silencio=args.silencio
    )
    clave.iniciar(archivo_inicial=args.leer)


if __name__ == "__main__":
    main()
