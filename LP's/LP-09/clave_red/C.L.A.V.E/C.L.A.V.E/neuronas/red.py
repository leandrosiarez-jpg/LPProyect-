"""
CLAVE - Red Neuronal
El tejido completo de la mente de CLAVE.

Gestiona todas las neuronas, sus conexiones, y los procesos de:
- creación dinámica de neuronas desde el aprendizaje
- activación por resonancia
- olvido gradual (las neuronas que no se usan se debilitan)
- síntesis de respuesta desde activaciones
"""

import json
import time
import math
import os
import re
from typing import Optional
from .neurona import Neurona


class RedNeuronal:
    """
    La mente de CLAVE.
    
    No es una red neuronal de pesos matriciales — es una red de conceptos
    interconectados que crece con cada lectura y cada conversación.
    """

    ARCHIVO_MEMORIA = "memoria/red_neuronal.json"
    UMBRAL_ACTIVACION = 0.25
    UMBRAL_NUEVA_NEURONA = 0.4     # frecuencia mínima para crear neurona
    MAX_NEURONAS = 50_000

    def __init__(self):
        self.neuronas: dict[str, Neurona] = {}     # concepto -> Neurona
        self.neuronas_por_id: dict[str, Neurona] = {}  # id -> Neurona
        self.historial_activaciones: list[str] = []     # conceptos recientes
        self.palabras_candidatas: dict[str, int] = {}   # candidatas a neurona
        self._cargar()

    # ─── Acceso básico ────────────────────────────────────────────

    def obtener(self, concepto: str) -> Optional[Neurona]:
        return self.neuronas.get(concepto.lower().strip())

    def existe(self, concepto: str) -> bool:
        return concepto.lower().strip() in self.neuronas

    def total(self) -> int:
        return len(self.neuronas)

    # ─── Creación de neuronas ─────────────────────────────────────

    def crear_neurona(
        self,
        concepto: str,
        peso_inicial: float = 0.5,
        origen: str = "lectura",
        contexto: str = "",
        padre_concepto: Optional[str] = None
    ) -> Optional[Neurona]:
        """
        Crea una nueva neurona si no existe, o refuerza si ya existe.
        """
        c = concepto.lower().strip()
        if not c or len(c) < 2:
            return None

        if c in self.neuronas:
            n = self.neuronas[c]
            n.activar(0.3)
            if contexto:
                n.agregar_contexto(contexto)
            return n

        padre_id = None
        if padre_concepto:
            padre = self.neuronas.get(padre_concepto.lower())
            if padre:
                padre_id = padre.id

        n = Neurona(
            concepto=c,
            peso=peso_inicial,
            origen=origen,
            padre_id=padre_id
        )
        if contexto:
            n.agregar_contexto(contexto)

        self.neuronas[c] = n
        self.neuronas_por_id[n.id] = n

        # Auto-conectar con neuronas semánticamente cercanas
        self._conectar_por_similitud(n)

        return n

    def _conectar_por_similitud(self, nueva: Neurona):
        """
        Conecta la nueva neurona con las más relevantes existentes
        basándose en compartir caracteres/raíz (heurística simple sin NLP externo).
        """
        c = nueva.concepto
        candidatas = []

        for concepto_existente, n_existente in self.neuronas.items():
            if concepto_existente == c:
                continue
            # Similitud por prefijo compartido o subcadena
            sim = self._similitud(c, concepto_existente)
            if sim > 0.5:
                candidatas.append((sim, n_existente))

        # Conectar con las 5 más similares
        candidatas.sort(reverse=True)
        for sim, n_vec in candidatas[:5]:
            nueva.conectar(n_vec.id, sim * 0.7)
            n_vec.conectar(nueva.id, sim * 0.5)

    def _similitud(self, a: str, b: str) -> float:
        """Similitud simple entre dos cadenas (Jaccard sobre bigramas)."""
        def bigramas(s):
            return set(s[i:i+2] for i in range(len(s)-1))
        ba, bb = bigramas(a), bigramas(b)
        if not ba or not bb:
            return 0.0
        interseccion = len(ba & bb)
        union = len(ba | bb)
        return interseccion / union if union else 0.0

    # ─── Aprendizaje desde texto ──────────────────────────────────

    def aprender_texto(self, texto: str, origen: str = "lectura") -> int:
        """
        Procesa un texto y crea/refuerza neuronas a partir de él.
        Devuelve cuántas neuronas nuevas se crearon.
        """
        if len(self.neuronas) >= self.MAX_NEURONAS:
            return 0

        palabras = self._tokenizar(texto)
        nuevas = 0

        for i, palabra in enumerate(palabras):
            if not self._es_relevante(palabra):
                continue

            # Contexto: ventana de palabras alrededor
            inicio = max(0, i - 5)
            fin = min(len(palabras), i + 6)
            contexto = " ".join(palabras[inicio:fin])

            # Neurona candidata o directa según frecuencia
            if self.existe(palabra):
                self.neuronas[palabra].activar(0.2)
                self.neuronas[palabra].agregar_contexto(contexto)
            else:
                # Contar apariciones antes de crear neurona
                self.palabras_candidatas[palabra] = self.palabras_candidatas.get(palabra, 0) + 1
                if self.palabras_candidatas[palabra] >= 2:
                    self.crear_neurona(palabra, peso_inicial=0.35, origen=origen, contexto=contexto)
                    del self.palabras_candidatas[palabra]
                    nuevas += 1

        # Conectar palabras consecutivas relevantes (asociación por co-ocurrencia)
        relevantes = [p for p in palabras if self.existe(p)]
        for i in range(len(relevantes) - 1):
            n1 = self.neuronas.get(relevantes[i])
            n2 = self.neuronas.get(relevantes[i+1])
            if n1 and n2:
                n1.conectar(n2.id, 0.3)
                n2.conectar(n1.id, 0.2)

        return nuevas

    def _tokenizar(self, texto: str) -> list[str]:
        """Extrae palabras limpias del texto."""
        texto = texto.lower()
        texto = re.sub(r'[^\w\sáéíóúüñ]', ' ', texto)
        palabras = texto.split()
        return [p.strip() for p in palabras if p.strip()]

    _STOPWORDS = {
        'de', 'la', 'el', 'en', 'y', 'a', 'que', 'se', 'los', 'un', 'es',
        'por', 'con', 'una', 'para', 'del', 'las', 'lo', 'su', 'al', 'como',
        'más', 'o', 'pero', 'si', 'ya', 'no', 'le', 'me', 'te', 'nos', 'os',
        'ser', 'estar', 'ha', 'han', 'he', 'he', 'era', 'fue', 'son', 'tienen'
    }

    def _es_relevante(self, palabra: str) -> bool:
        """Filtra palabras vacías y muy cortas."""
        return (
            len(palabra) >= 3 and
            palabra not in self._STOPWORDS and
            not palabra.isdigit() and
            palabra.isalpha()
        )

    # ─── Activación por consulta ──────────────────────────────────

    def activar_por_entrada(self, texto: str) -> list[Neurona]:
        """
        Activa las neuronas relevantes para un texto dado.
        Devuelve las neuronas activadas ordenadas por relevancia.
        """
        palabras = self._tokenizar(texto)
        activadas: dict[str, float] = {}

        # Activación directa
        for palabra in palabras:
            if self.existe(palabra):
                n = self.neuronas[palabra]
                nivel = n.activar(0.8)
                activadas[n.id] = nivel
                self.historial_activaciones.append(palabra)

        # Propagación a vecinas conectadas (1 nivel)
        propagadas = {}
        for nid, nivel in activadas.items():
            neurona = self.neuronas_por_id.get(nid)
            if not neurona:
                continue
            for vecina_id, fuerza in neurona.conexiones.items():
                vecina = self.neuronas_por_id.get(vecina_id)
                if vecina and vecina_id not in activadas:
                    nivel_prop = nivel * fuerza * 0.5
                    if nivel_prop > self.UMBRAL_ACTIVACION:
                        vecina.activar(nivel_prop * 0.3)
                        propagadas[vecina_id] = nivel_prop

        # Mantener historial corto
        if len(self.historial_activaciones) > 100:
            self.historial_activaciones = self.historial_activaciones[-50:]

        # Juntar y ordenar por relevancia
        todos_ids = set(activadas.keys()) | set(propagadas.keys())
        resultado = [
            self.neuronas_por_id[nid]
            for nid in todos_ids
            if nid in self.neuronas_por_id
        ]
        resultado.sort(key=lambda n: n.relevancia(), reverse=True)
        return resultado[:20]

    def neuronas_relevantes(self, top: int = 15) -> list[Neurona]:
        """Neuronas más relevantes en este momento (por peso + recencia)."""
        activas = [n for n in self.neuronas.values() if n.esta_activa()]
        activas.sort(key=lambda n: n.relevancia(), reverse=True)
        return activas[:top]

    # ─── Olvido gradual ───────────────────────────────────────────

    def ciclo_olvido(self):
        """
        Debilita neuronas que no se han usado recientemente.
        No elimina neuronas — solo reduce su peso.
        Llamar periódicamente (e.g. al inicio de sesión).
        """
        ahora = time.time()
        hora = 3600

        for n in self.neuronas.values():
            if n.ultima_activacion == 0:
                continue
            tiempo_sin_uso = ahora - n.ultima_activacion
            # Olvido muy lento: pierde 5% por hora de inactividad, máx 40%
            decaimiento = min(0.4, (tiempo_sin_uso / hora) * 0.05)
            n.peso = max(0.05, n.peso - decaimiento)

    # ─── Introspección ────────────────────────────────────────────

    def conceptos_mas_fuertes(self, n: int = 10) -> list[tuple[str, float]]:
        """Los conceptos con mayor peso en la red."""
        ordenados = sorted(
            self.neuronas.items(),
            key=lambda item: item[1].peso,
            reverse=True
        )
        return [(c, neurona.peso) for c, neurona in ordenados[:n]]

    def estadisticas(self) -> dict:
        total = len(self.neuronas)
        activas = sum(1 for n in self.neuronas.values() if n.esta_activa())
        por_origen = {}
        for n in self.neuronas.values():
            por_origen[n.origen] = por_origen.get(n.origen, 0) + 1
        return {
            "total_neuronas": total,
            "neuronas_activas": activas,
            "por_origen": por_origen,
            "candidatas_pendientes": len(self.palabras_candidatas)
        }

    # ─── Persistencia ─────────────────────────────────────────────

    def guardar(self):
        os.makedirs("memoria", exist_ok=True)
        datos = {
            "version": "3.0",
            "timestamp": time.time(),
            "neuronas": {c: n.a_dict() for c, n in self.neuronas.items()},
            "palabras_candidatas": self.palabras_candidatas,
            "historial": self.historial_activaciones[-50:]
        }
        with open(self.ARCHIVO_MEMORIA, "w", encoding="utf-8") as f:
            json.dump(datos, f, ensure_ascii=False, indent=2)

    def _cargar(self):
        if not os.path.exists(self.ARCHIVO_MEMORIA):
            return
        try:
            with open(self.ARCHIVO_MEMORIA, "r", encoding="utf-8") as f:
                datos = json.load(f)
            for c, d in datos.get("neuronas", {}).items():
                n = Neurona.desde_dict(d)
                self.neuronas[c] = n
                self.neuronas_por_id[n.id] = n
            self.palabras_candidatas = datos.get("palabras_candidatas", {})
            self.historial_activaciones = datos.get("historial", [])
        except Exception:
            pass  # Si hay error, empieza desde cero
