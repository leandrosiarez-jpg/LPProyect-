"""
CLAVE - Aprendizaje desde Archivos

CLAVE aprende leyendo. Este módulo lee archivos de texto, PDF, o directorios
enteros y alimenta la red neuronal con ese conocimiento.

No hace resúmenes — hace asimilación:
extrae, filtra, tokeniza, y deja que la red construya sus propias conexiones.
"""

import os
import re
import time
from pathlib import Path
from typing import Callable, Optional


# Extensiones que CLAVE puede leer
EXTENSIONES_SOPORTADAS = {
    ".txt", ".md", ".py", ".json", ".csv",
    ".html", ".htm", ".rst", ".log", ".ini",
    ".cfg", ".yaml", ".yml", ".xml", ".tex"
}

# Intentar soporte PDF
try:
    import pdfplumber
    TIENE_PDF = True
except ImportError:
    TIENE_PDF = False


class LectorAprendizaje:
    """
    Lee archivos y alimenta la red neuronal de CLAVE.
    """

    def __init__(self, red_neuronal, callback_progreso: Optional[Callable] = None):
        self.red = red_neuronal
        self.callback = callback_progreso   # fn(mensaje: str)
        self.archivos_leidos: list[str] = []
        self.total_neuronas_creadas = 0

    def _log(self, msg: str):
        if self.callback:
            self.callback(msg)

    # ─── Lectura de archivo individual ───────────────────────────

    def leer_archivo(self, ruta: str) -> int:
        """
        Lee un archivo y retorna el número de neuronas creadas.
        """
        ruta = Path(ruta)
        if not ruta.exists():
            self._log(f"No encuentro el archivo: {ruta}")
            return 0

        ext = ruta.suffix.lower()

        if ext == ".pdf" and TIENE_PDF:
            texto = self._leer_pdf(ruta)
        elif ext in EXTENSIONES_SOPORTADAS or ext == "":
            texto = self._leer_texto(ruta)
        else:
            self._log(f"Formato no soportado: {ext}")
            return 0

        if not texto.strip():
            self._log(f"El archivo está vacío: {ruta.name}")
            return 0

        self._log(f"Leyendo '{ruta.name}'...")
        nuevas = self._procesar_texto(texto, str(ruta))
        self.archivos_leidos.append(str(ruta))
        self.total_neuronas_creadas += nuevas
        self._log(f"'{ruta.name}' asimilado. Neuronas nuevas: {nuevas}")
        return nuevas

    def _leer_texto(self, ruta: Path) -> str:
        """Lee archivo de texto con detección de encoding."""
        for enc in ["utf-8", "latin-1", "cp1252"]:
            try:
                with open(ruta, "r", encoding=enc, errors="replace") as f:
                    return f.read()
            except Exception:
                continue
        return ""

    def _leer_pdf(self, ruta: Path) -> str:
        """Extrae texto de PDF página a página."""
        try:
            import pdfplumber
            partes = []
            with pdfplumber.open(ruta) as pdf:
                for pagina in pdf.pages:
                    t = pagina.extract_text()
                    if t:
                        partes.append(t)
            return "\n".join(partes)
        except Exception as e:
            self._log(f"Error leyendo PDF: {e}")
            return ""

    # ─── Procesamiento de texto ───────────────────────────────────

    def _procesar_texto(self, texto: str, fuente: str = "") -> int:
        """
        Divide el texto en segmentos y los pasa a la red neuronal.
        Devuelve total de neuronas nuevas creadas.
        """
        # Limpiar texto
        texto = self._limpiar(texto)

        # Dividir en oraciones/párrafos (máx ~500 chars cada segmento)
        segmentos = self._segmentar(texto)

        total_nuevas = 0
        for segmento in segmentos:
            if len(segmento.strip()) < 10:
                continue
            nuevas = self.red.aprender_texto(segmento, origen="lectura")
            total_nuevas += nuevas

        return total_nuevas

    def _limpiar(self, texto: str) -> str:
        """Normaliza el texto eliminando ruido."""
        # Colapsar espacios y saltos de línea múltiples
        texto = re.sub(r'\r\n', '\n', texto)
        texto = re.sub(r'\n{3,}', '\n\n', texto)
        texto = re.sub(r'[ \t]{2,}', ' ', texto)
        # Eliminar caracteres de control raros
        texto = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', texto)
        return texto.strip()

    def _segmentar(self, texto: str, max_chars: int = 500) -> list[str]:
        """Divide el texto en segmentos procesables."""
        # Dividir por párrafos primero
        parrafos = re.split(r'\n\n+', texto)
        segmentos = []

        for p in parrafos:
            p = p.strip()
            if not p:
                continue
            if len(p) <= max_chars:
                segmentos.append(p)
            else:
                # Dividir párrafos largos por oraciones
                oraciones = re.split(r'[.!?]+\s+', p)
                bloque = ""
                for o in oraciones:
                    if len(bloque) + len(o) < max_chars:
                        bloque += o + ". "
                    else:
                        if bloque:
                            segmentos.append(bloque.strip())
                        bloque = o + ". "
                if bloque:
                    segmentos.append(bloque.strip())

        return segmentos

    # ─── Lectura de directorio ────────────────────────────────────

    def leer_directorio(self, ruta: str, recursivo: bool = True) -> int:
        """
        Lee todos los archivos de un directorio.
        """
        ruta = Path(ruta)
        if not ruta.is_dir():
            self._log(f"No es un directorio: {ruta}")
            return 0

        patron = "**/*" if recursivo else "*"
        archivos = [
            f for f in ruta.glob(patron)
            if f.is_file() and f.suffix.lower() in EXTENSIONES_SOPORTADAS
        ]

        if not archivos:
            self._log("No encontré archivos legibles en ese directorio.")
            return 0

        self._log(f"Encontré {len(archivos)} archivos para leer.")
        total = 0
        for archivo in archivos:
            total += self.leer_archivo(str(archivo))
            time.sleep(0.05)  # evitar saturación

        self._log(f"Directorio asimilado. Total neuronas nuevas: {total}")
        return total

    # ─── Estado ───────────────────────────────────────────────────

    def resumen(self) -> str:
        return (
            f"Archivos leídos: {len(self.archivos_leidos)} | "
            f"Neuronas creadas en esta sesión: {self.total_neuronas_creadas}"
        )
