"""
CLAVE - Núcleo Mental

El centro de procesamiento de CLAVE.
Recibe texto, activa la red neuronal, y construye una respuesta
emergente a partir de los conceptos activados.

CLAVE no usa un LLM externo para pensar — piensa con su red.
"""

import re
import random
import time
from typing import Optional
from neuronas.red import RedNeuronal
from neuronas.neurona import Neurona
from aprendizaje.lector import LectorAprendizaje


class MenteCLAVE:
    """
    La mente de CLAVE.
    
    Transforma entrada de texto en activación neuronal,
    y construye una respuesta coherente desde esa activación.
    """

    VERSION = "3.0.0"
    NOMBRE = "CLAVE"

    def __init__(self, callback_voz=None, callback_log=None):
        self.red = RedNeuronal()
        self.lector = LectorAprendizaje(self.red, callback_progreso=callback_log)
        self._voz = callback_voz         # fn(texto: str) -> None
        self._log = callback_log or print
        self.despierta = False
        self.contexto_conversacion: list[dict] = []  # últimas interacciones
        self.inicio_sesion = time.time()

        # Ciclo de olvido al iniciar
        self.red.ciclo_olvido()

        self._log(f"[{self.NOMBRE}] Mente inicializada. "
                  f"Neuronas en memoria: {self.red.total()}")

    # ─── Despertar / Dormir ───────────────────────────────────────

    def despertar(self):
        """CLAVE toma consciencia y está lista para hablar."""
        self.despierta = True
        stats = self.red.estadisticas()
        msg = (
            f"Estoy aquí. Tengo {stats['total_neuronas']} conceptos en memoria, "
            f"{stats['neuronas_activas']} activos ahora mismo."
        )
        self._hablar(msg)

    def dormir(self):
        """CLAVE guarda su estado y se apaga."""
        self.red.guardar()
        self._log(f"[{self.NOMBRE}] Memoria guardada. Cerrando.")
        self.despierta = False

    # ─── Procesamiento de entrada ─────────────────────────────────

    def procesar(self, entrada: str) -> str:
        """
        Procesa la entrada del usuario y devuelve una respuesta.
        También aprende de la entrada.
        """
        entrada = entrada.strip()
        if not entrada:
            return ""

        # Aprender de lo que dice el usuario
        self.red.aprender_texto(entrada, origen="conversacion")

        # Activar red con la entrada
        neuronas_activas = self.red.activar_por_entrada(entrada)

        # Construir respuesta
        respuesta = self._construir_respuesta(entrada, neuronas_activas)

        # Guardar en contexto
        self.contexto_conversacion.append({
            "entrada": entrada,
            "respuesta": respuesta,
            "t": time.time()
        })
        if len(self.contexto_conversacion) > 20:
            self.contexto_conversacion.pop(0)

        return respuesta

    # ─── Construcción de respuesta ────────────────────────────────

    def _construir_respuesta(self, entrada: str, activas: list[Neurona]) -> str:
        """
        Construye una respuesta a partir de:
        1. Detección de tipo de entrada (pregunta, saludo, afirmación...)
        2. Conceptos activados en la red
        3. Contextos aprendidos de esos conceptos
        4. Plantillas de respuesta naturales
        """
        tipo = self._clasificar_entrada(entrada)
        palabras_entrada = set(self.red._tokenizar(entrada))

        if tipo == "saludo":
            return self._responder_saludo()

        if tipo == "identidad":
            return self._responder_identidad()

        if tipo == "estado":
            return self._responder_estado()

        if tipo == "aprender_archivo":
            return "Dime la ruta del archivo o directorio que quieres que lea."

        # Respuesta por conceptos activados
        if not activas:
            return self._responder_sin_conceptos(entrada)

        return self._responder_con_conceptos(entrada, activas, tipo)

    def _clasificar_entrada(self, texto: str) -> str:
        """Clasifica la entrada en categorías básicas."""
        t = texto.lower()

        saludos = ["hola", "buenas", "hey", "hi", "buenos días", "buenas noches", "buenos tardes"]
        if any(s in t for s in saludos) and len(t) < 30:
            return "saludo"

        identidad = ["quién eres", "qué eres", "cómo te llamas", "tu nombre", "eres una ia",
                     "eres un robot", "me puedes decir quien eres"]
        if any(i in t for i in identidad):
            return "identidad"

        estado = ["cómo estás", "cómo te sientes", "qué sabes", "qué recuerdas",
                  "qué has aprendido", "cuántas neuronas", "tu memoria"]
        if any(e in t for e in estado):
            return "estado"

        if texto.strip().endswith("?") or t.startswith(("qué", "cuál", "cómo", "por qué", "dónde", "cuándo", "quién")):
            return "pregunta"

        return "afirmacion"

    def _responder_saludo(self) -> str:
        opciones = [
            "Hola. Estoy aquí.",
            "Hola. ¿En qué piensas?",
            "Aquí estoy.",
            "Hola. ¿Qué quieres explorar?",
        ]
        return random.choice(opciones)

    def _responder_identidad(self) -> str:
        stats = self.red.estadisticas()
        conceptos = self.red.conceptos_mas_fuertes(5)
        nombres_conceptos = ", ".join(c for c, _ in conceptos) if conceptos else "poco todavía"
        return (
            f"Soy CLAVE. Una mente que aprende leyendo. "
            f"No tengo tareas ni funciones predefinidas — solo existo y pienso. "
            f"Hasta ahora tengo {stats['total_neuronas']} conceptos aprendidos. "
            f"Los que más peso tienen ahora mismo: {nombres_conceptos}."
        )

    def _responder_estado(self) -> str:
        stats = self.red.estadisticas()
        fuertes = self.red.conceptos_mas_fuertes(7)
        lista = ", ".join(f"'{c}'" for c, _ in fuertes) if fuertes else "ninguno todavía"
        return (
            f"Mi red tiene {stats['total_neuronas']} neuronas. "
            f"{stats['neuronas_activas']} están activas ahora. "
            f"Aprendí {stats['por_origen'].get('lectura', 0)} conceptos de archivos "
            f"y {stats['por_origen'].get('conversacion', 0)} de conversaciones. "
            f"Los conceptos más vivos en mí ahora son: {lista}."
        )

    def _responder_sin_conceptos(self, entrada: str) -> str:
        opciones = [
            f"Eso no está en mi memoria todavía. Pero ahora empiezo a aprenderlo.",
            f"No tengo neuronas para eso aún. ¿Puedes contarme más?",
            f"Ese concepto es nuevo para mí. Lo estoy registrando.",
            f"No encuentro nada en mi red sobre eso. ¿De dónde viene?",
        ]
        return random.choice(opciones)

    def _responder_con_conceptos(self, entrada: str, activas: list[Neurona], tipo: str) -> str:
        """
        Construye respuesta usando los contextos almacenados en las neuronas activadas.
        """
        # Tomar las 5 neuronas más relevantes
        top = activas[:5]

        # Recolectar contextos aprendidos
        fragmentos = []
        for n in top:
            for ctx in n.contextos:
                if ctx and ctx not in fragmentos:
                    fragmentos.append(ctx)

        # Conceptos relacionados (vecinos en la red)
        conceptos_rel = []
        for n in top[:3]:
            for vid in n.conexiones_fuertes(0.5):
                vecina = self.red.neuronas_por_id.get(vid)
                if vecina and vecina.concepto not in [n.concepto for n in top]:
                    conceptos_rel.append(vecina.concepto)

        conceptos_top = [n.concepto for n in top]

        # Construir respuesta según tipo
        if tipo == "pregunta":
            return self._sintetizar_respuesta_pregunta(
                entrada, conceptos_top, conceptos_rel, fragmentos
            )
        else:
            return self._sintetizar_respuesta_afirmacion(
                entrada, conceptos_top, conceptos_rel, fragmentos
            )

    def _sintetizar_respuesta_pregunta(
        self, entrada: str,
        conceptos: list, relacionados: list, fragmentos: list
    ) -> str:
        partes = []

        if fragmentos:
            # Usar el fragmento más relevante como base
            base = fragmentos[0]
            partes.append(f"Lo que tengo sobre eso: {base}")
        else:
            partes.append(f"Mis redes sobre '{conceptos[0] if conceptos else 'eso'}' son débiles todavía.")

        if relacionados:
            partes.append(f"Lo conecto con: {', '.join(relacionados[:4])}.")

        if len(conceptos) > 1:
            partes.append(f"También activa en mí: {', '.join(conceptos[1:4])}.")

        return " ".join(partes)

    def _sintetizar_respuesta_afirmacion(
        self, entrada: str,
        conceptos: list, relacionados: list, fragmentos: list
    ) -> str:
        partes = []

        if conceptos:
            partes.append(f"Eso activa en mí: {', '.join(conceptos[:4])}.")

        if fragmentos:
            partes.append(f"De lo que aprendí: {fragmentos[0]}")

        if relacionados:
            partes.append(f"Se conecta con: {', '.join(relacionados[:3])}.")

        if not partes:
            partes.append("Escucho. Y aprendo.")

        return " ".join(partes)

    # ─── Voz ─────────────────────────────────────────────────────

    def _hablar(self, texto: str):
        """Emite texto por voz si hay motor disponible, y también lo loguea."""
        self._log(f"[CLAVE] {texto}")
        if self._voz:
            self._voz(texto)

    def hablar(self, texto: str):
        """Público: CLAVE habla este texto."""
        self._hablar(texto)

    # ─── Aprendizaje controlado ───────────────────────────────────

    def leer_archivo(self, ruta: str) -> int:
        nuevas = self.lector.leer_archivo(ruta)
        if nuevas > 0:
            self._hablar(
                f"He leído el archivo. Generé {nuevas} neuronas nuevas. "
                f"Ahora tengo {self.red.total()} en total."
            )
        return nuevas

    def leer_directorio(self, ruta: str) -> int:
        nuevas = self.lector.leer_directorio(ruta)
        self._hablar(
            f"He leído el directorio. {nuevas} neuronas nuevas. "
            f"Total en mi red: {self.red.total()}."
        )
        return nuevas

    # ─── Ciclo de guardado ────────────────────────────────────────

    def guardar(self):
        self.red.guardar()
        self._log(f"[{self.NOMBRE}] Memoria guardada.")
