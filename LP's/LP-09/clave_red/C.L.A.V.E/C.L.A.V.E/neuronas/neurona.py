"""
CLAVE - Neurona Base
Unidad fundamental de la mente de CLAVE.
Cada neurona puede activarse, conectarse, y generar nuevas neuronas.
"""

import uuid
import time
import math
from typing import Optional


class Neurona:
    """
    Una neurona en la mente de CLAVE.
    
    No simula biología al pie de la letra — modela la idea esencial:
    una unidad que activa o inhibe otras según lo que aprendió,
    y que puede nacer de la experiencia.
    """

    def __init__(
        self,
        concepto: str,
        peso: float = 0.5,
        origen: str = "lectura",
        padre_id: Optional[str] = None
    ):
        self.id = str(uuid.uuid4())[:8]
        self.concepto = concepto.lower().strip()
        self.peso = max(0.0, min(1.0, peso))       # 0.0 = dormida, 1.0 = muy activa
        self.origen = origen                         # "lectura", "conversacion", "inferencia"
        self.padre_id = padre_id                     # neurona que la generó
        self.conexiones: dict[str, float] = {}       # {neurona_id: fuerza_conexion}
        self.activaciones = 0
        self.nacimiento = time.time()
        self.ultima_activacion = 0.0
        self.contextos: list[str] = []              # fragmentos donde fue aprendida

    # ─── Activación ───────────────────────────────────────────────

    def activar(self, fuerza: float = 1.0) -> float:
        """
        Activa la neurona. La fuerza se atenúa con el peso existente.
        Devuelve el nivel de activación resultante.
        """
        self.activaciones += 1
        self.ultima_activacion = time.time()

        # Refuerzo hebbiano: las neuronas que se activan mucho se fortalecen
        delta = fuerza * (1.0 - self.peso) * 0.1
        self.peso = min(1.0, self.peso + delta)

        return self.peso * fuerza

    def inhibir(self, fuerza: float = 0.3):
        """Debilita la neurona (para conceptos contradictorios o errores)."""
        self.peso = max(0.0, self.peso - fuerza * 0.05)

    # ─── Conexiones ───────────────────────────────────────────────

    def conectar(self, otra_id: str, fuerza: float = 0.5):
        """Conecta esta neurona con otra. Si ya existe, refuerza el enlace."""
        if otra_id in self.conexiones:
            self.conexiones[otra_id] = min(1.0, self.conexiones[otra_id] + 0.1)
        else:
            self.conexiones[otra_id] = max(0.0, min(1.0, fuerza))

    def desconectar(self, otra_id: str):
        self.conexiones.pop(otra_id, None)

    def conexiones_fuertes(self, umbral: float = 0.6) -> list[str]:
        """Devuelve IDs de neuronas con conexión fuerte."""
        return [nid for nid, f in self.conexiones.items() if f >= umbral]

    # ─── Generación de hijas ──────────────────────────────────────

    def generar_hija(self, nuevo_concepto: str, contexto: str = "") -> "Neurona":
        """
        Crea una nueva neurona a partir de esta.
        La hija nace con un peso menor y recuerda su origen.
        """
        hija = Neurona(
            concepto=nuevo_concepto,
            peso=self.peso * 0.6,
            origen="inferencia",
            padre_id=self.id
        )
        if contexto:
            hija.contextos.append(contexto[:200])
        # Conexión bidireccional débil
        self.conectar(hija.id, 0.4)
        return hija

    # ─── Estado ───────────────────────────────────────────────────

    def esta_activa(self) -> bool:
        """Neurona activa si su peso supera el umbral de consciencia."""
        return self.peso > 0.3

    def edad_segundos(self) -> float:
        return time.time() - self.nacimiento

    def relevancia(self) -> float:
        """
        Calcula relevancia combinando peso, recencia y frecuencia de activación.
        """
        recencia = math.exp(-max(0, time.time() - self.ultima_activacion) / 3600)
        frecuencia = math.log1p(self.activaciones) / 10
        return self.peso * 0.5 + recencia * 0.3 + frecuencia * 0.2

    def agregar_contexto(self, texto: str):
        """Guarda el fragmento textual donde se aprendió este concepto."""
        fragmento = texto[:200].strip()
        if fragmento and fragmento not in self.contextos:
            self.contextos.append(fragmento)
            if len(self.contextos) > 5:
                self.contextos.pop(0)  # mantener solo los últimos 5

    # ─── Serialización ────────────────────────────────────────────

    def a_dict(self) -> dict:
        return {
            "id": self.id,
            "concepto": self.concepto,
            "peso": round(self.peso, 4),
            "origen": self.origen,
            "padre_id": self.padre_id,
            "conexiones": self.conexiones,
            "activaciones": self.activaciones,
            "nacimiento": self.nacimiento,
            "ultima_activacion": self.ultima_activacion,
            "contextos": self.contextos
        }

    @classmethod
    def desde_dict(cls, d: dict) -> "Neurona":
        n = cls(
            concepto=d["concepto"],
            peso=d["peso"],
            origen=d.get("origen", "lectura"),
            padre_id=d.get("padre_id")
        )
        n.id = d["id"]
        n.conexiones = d.get("conexiones", {})
        n.activaciones = d.get("activaciones", 0)
        n.nacimiento = d.get("nacimiento", time.time())
        n.ultima_activacion = d.get("ultima_activacion", 0.0)
        n.contextos = d.get("contextos", [])
        return n

    def __repr__(self):
        return f"Neurona('{self.concepto}' peso={self.peso:.2f} act={self.activaciones})"
