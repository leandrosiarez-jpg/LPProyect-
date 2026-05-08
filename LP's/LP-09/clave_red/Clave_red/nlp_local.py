# nlp_local.py - Procesamiento de lenguaje natural sin APIs ni librerías externas
#
# CONCEPTOS QUE VAS A APRENDER ACÁ:
#
# 1. TOKENIZACIÓN: partir el texto en palabras individuales ("tokens")
#    "escaneá la red" → ["escanea", "la", "red"]
#
# 2. NORMALIZACIÓN: llevar todo a una forma estándar
#    "Escaneá" → "escanea" (minúsculas, sin tildes)
#    Esto es crucial: "escaneá" y "escanea" deben tratarse igual
#
# 3. BAG OF WORDS (BoW): representar texto como un vector numérico
#    Vocabulario: ["red","scan","ping","puertos","intrusos"]
#    "escaneá la red" → [1, 1, 0, 0, 0]  ← hay "red" y "scan"
#    "ping al router"  → [0, 0, 1, 0, 0]
#    El "orden" de las palabras no importa, solo su presencia
#
# 4. SIMILITUD COSENO: medir qué tan parecidos son dos vectores
#    Es como medir el ángulo entre dos flechas en el espacio
#    Si apuntan en la misma dirección → similitud alta (cerca de 1.0)
#    Si apuntan en direcciones opuestas → similitud baja (cerca de 0.0)
#    Fórmula: cos(θ) = (A · B) / (|A| × |B|)

import re
import math
from collections import Counter


# ─────────────────────────────────────────────
#  NORMALIZADOR
#  Convierte texto sucio en tokens limpios
# ─────────────────────────────────────────────

# Mapa de tildes y variantes → forma base
_TILDES = str.maketrans(
    "áéíóúàèìòùâêîôûäëïöüãõñÁÉÍÓÚÀÈÌÒÙÑ",
    "aeiouaeiouaeiouaeiouaonaeiouaeioun"
)

_STOPWORDS = {
    "el", "la", "los", "las", "un", "una", "unos", "unas",
    "de", "del", "al", "a", "en", "con", "por", "para",
    "que", "me", "te", "se", "le", "yo", "tu", "el",
    "y", "o", "pero", "si", "no", "mi", "su"
}

def normalizar(texto: str) -> list:
    """
    Convierte texto libre en lista de tokens limpios.
    
    Pasos:
      1. Minúsculas
      2. Eliminar tildes y caracteres especiales
      3. Separar en palabras (split por espacios y puntuación)
      4. Filtrar stopwords (palabras vacías sin significado)
      5. Filtrar tokens muy cortos
    
    Ejemplo:
      "¡Escaneá TODA la red!" → ["escanea", "toda", "red"]
    """
    texto = texto.lower()
    texto = texto.translate(_TILDES)
    # Reemplazar todo lo que no sea letra o número con espacio
    texto = re.sub(r"[^a-z0-9\s]", " ", texto)
    tokens = texto.split()
    tokens = [t for t in tokens if t not in _STOPWORDS and len(t) > 1]
    return tokens


# ─────────────────────────────────────────────
#  VECTORIZADOR (Bag of Words)
#  Convierte listas de tokens en vectores numéricos
# ─────────────────────────────────────────────

class VectorizadorBoW:
    """
    Construye un vocabulario compartido y convierte texto en vectores.
    
    ¿POR QUÉ NECESITAMOS UN VOCABULARIO COMPARTIDO?
    Para comparar dos textos con similitud coseno, ambos vectores
    deben tener la MISMA longitud y las MISMAS posiciones.
    
    Vocabulario: ["red", "scan", "ping", "puertos", "intrusos"]
                   pos0   pos1   pos2    pos3        pos4
    
    "escanear la red" → [1, 1, 0, 0, 0]
    "hay intrusos?"   → [0, 0, 0, 0, 1]
    "ping a 192..."   → [0, 0, 1, 0, 0]
    
    Ahora podemos calcular el ángulo entre cualquier par de vectores.
    """
    
    def __init__(self):
        self.vocabulario = {}  # palabra → índice
        self.construido = False
    
    def construir(self, corpus: list):
        """
        corpus: lista de listas de tokens
        Asigna un índice único a cada palabra que aparece.
        """
        palabras_unicas = set()
        for tokens in corpus:
            palabras_unicas.update(tokens)
        
        self.vocabulario = {palabra: i for i, palabra in enumerate(sorted(palabras_unicas))}
        self.construido = True
    
    def vectorizar(self, tokens: list) -> list:
        """
        Convierte una lista de tokens en un vector numérico.
        Posiciones del vocabulario no presentes quedan en 0.
        Usamos frecuencia (count) no solo presencia (0/1).
        """
        if not self.construido:
            raise RuntimeError("Llamá a construir() primero")
        
        vector = [0.0] * len(self.vocabulario)
        conteo = Counter(tokens)
        
        for palabra, frecuencia in conteo.items():
            if palabra in self.vocabulario:
                vector[self.vocabulario[palabra]] = float(frecuencia)
        
        return vector
    
    def dimension(self) -> int:
        return len(self.vocabulario)


# ─────────────────────────────────────────────
#  SIMILITUD COSENO
#  El corazón matemático del clasificador
# ─────────────────────────────────────────────

def similitud_coseno(a: list, b: list) -> float:
    """
    Mide qué tan parecidos son dos vectores.
    
    INTUICIÓN GEOMÉTRICA:
    Pensá en cada vector como una flecha en el espacio N-dimensional.
    La similitud coseno mide el coseno del ángulo entre esas dos flechas:
      - Mismo ángulo (0°)  → cos(0°)  = 1.0  → idénticos
      - Ángulo recto (90°) → cos(90°) = 0.0  → sin relación
      - Opuestos (180°)    → cos(180°) = -1.0 → opuestos
    
    FÓRMULA:
      cos(θ) = (A · B) / (|A| × |B|)
      
      donde:
        A · B  = producto punto (suma de a_i × b_i para cada i)
        |A|    = magnitud de A (raíz de la suma de cuadrados)
    
    Para texto, siempre obtenemos valores entre 0 y 1
    porque las frecuencias nunca son negativas.
    """
    if not a or not b or len(a) != len(b):
        return 0.0
    
    # Producto punto: suma de productos elemento a elemento
    punto = sum(x * y for x, y in zip(a, b))
    
    # Magnitud de cada vector
    mag_a = math.sqrt(sum(x * x for x in a))
    mag_b = math.sqrt(sum(y * y for y in b))
    
    if mag_a == 0 or mag_b == 0:
        return 0.0
    
    return punto / (mag_a * mag_b)


# ─────────────────────────────────────────────
#  CLASIFICADOR DE INTENCIONES
#  El cerebro del NLP: mapea texto libre → comando
# ─────────────────────────────────────────────

# Base de conocimiento: cada intención tiene ejemplos de frases
# Entre más ejemplos pongas, mejor va a reconocer variantes.
# Esto es "entrenamiento" manual — vos sos el que etiqueta.
INTENCIONES = {
    "scan": [
        "escanear red", "escanea la red", "scan completo", "buscar dispositivos",
        "ver que hay en la red", "que dispositivos hay", "mostrar todos",
        "explorá la red", "descubrir dispositivos", "listar red"
    ],
    "scan_rapido": [
        "scan rapido", "escaneo rapido", "rapido", "ping rapido",
        "solo ping", "rapido no tarda", "escaneo liviano"
    ],
    "scan_profundo": [
        "scan profundo", "escaneo completo con puertos", "analisis completo",
        "todo incluido", "puertos y mac", "escaneo detallado"
    ],
    "scan_rango": [
        "escanear rango", "scan entre", "de ip a ip", "rango especifico",
        "entre estas ips", "subnet especifica"
    ],
    "puertos": [
        "puertos abiertos", "que puertos tiene", "escanear puertos",
        "ver puertos", "puertos de", "que servicios corre"
    ],
    "todos_puertos": [
        "todos los puertos", "escaneo completo de puertos", "65535",
        "cada puerto", "todos sin excepcion"
    ],
    "ping": [
        "hacer ping", "ping a", "esta activo", "responde",
        "verificar conexion", "llega el ping", "esta encendido"
    ],
    "mac": [
        "que mac tiene", "direccion mac", "fabricante del dispositivo",
        "quien fabrico", "mac address", "vendor de"
    ],
    "mi_ip": [
        "cual es mi ip", "mi ip", "mi direccion", "que ip tengo",
        "ip local", "ip del equipo"
    ],
    "gateway": [
        "gateway", "router principal", "puerta de enlace",
        "ip del router", "cual es el gateway"
    ],
    "analizar": [
        "analizar seguridad", "hay intrusos", "algo sospechoso",
        "que tan segura esta la red", "riesgos", "vulnerabilidades",
        "amenazas detectadas", "analisis de seguridad", "quien es raro"
    ],
    "neuro": [
        "analisis neuronal", "que dice la ia", "analisis con neuronas",
        "perceptron", "clasificacion neuronal", "ia que opina"
    ],
    "monitorear": [
        "monitorear", "monitoreo continuo", "vigilar la red",
        "avisar cuando cambie", "alerta de cambios", "modo monitor"
    ],
    "informe": [
        "generar informe", "reporte completo", "exportar informe",
        "informe html", "resumen general", "dame un reporte"
    ],
    "export_json": [
        "exportar json", "guardar json", "export json", "salvar json"
    ],
    "export_csv": [
        "exportar csv", "guardar csv", "excel", "planilla"
    ],
    "ver_historial": [
        "historial", "escaneos anteriores", "ver historial",
        "que escanee antes", "escaneos pasados"
    ],
    "ayuda": [
        "ayuda", "help", "que puedo hacer", "comandos disponibles",
        "que comandos hay", "como funciona", "opciones"
    ],
    "salir": [
        "salir", "cerrar", "exit", "quit", "chau", "adios", "terminar"
    ],
    "debug_nlp": [
        "debug nlp", "modo debug", "activar debug", "ver que entiende",
        "mostrar interpretacion", "que entendiste", "ver debug"
    ],
}


class ClasificadorNLP:
    """
    Clasifica texto libre en intenciones usando Bag of Words + cosine similarity.
    
    FLUJO COMPLETO:
      texto_usuario
        → normalizar()          "hay intrusos en la red?" → ["hay","intrusos","red"]
        → vectorizar()          ["hay","intrusos","red"] → [0,1,0,0,1,0,...] 
        → similitud_coseno()    comparar contra cada intención
        → argmax               elegir la intención con mayor similitud
        → comando              mapear intención → comando de C.L.A.V.E.
    
    UMBRAL:
      Si ninguna intención supera el umbral (default 0.15),
      el clasificador responde "no entendí" en vez de adivinar.
      Podés bajar el umbral para más sensibilidad o subirlo para
      más precisión. Es un hiperparámetro ajustable.
    """
    
    def __init__(self, umbral: float = 0.15):
        self.umbral = umbral
        self.vectorizador = VectorizadorBoW()
        self.vectores_intencion = {}  # intención → vector promedio
        self._entrenar()
    
    def _entrenar(self):
        """
        Convierte los ejemplos de INTENCIONES en vectores.
        
        Para cada intención, promediamos los vectores de todos sus ejemplos.
        Esto nos da un "vector representativo" de esa intención.
        
        EJEMPLO:
          "escanear red"       → [1, 0, 1, 0, ...]
          "buscar dispositivos" → [0, 1, 0, 1, ...]
          promedio scan        → [0.5, 0.5, 0.5, 0.5, ...]
        
        Así el clasificador es robusto a variantes del mismo comando.
        """
        # Primero construimos el vocabulario con TODOS los ejemplos
        todos_los_tokens = []
        ejemplos_por_intencion = {}
        
        for intencion, frases in INTENCIONES.items():
            tokens_intencion = []
            for frase in frases:
                tokens = normalizar(frase)
                todos_los_tokens.append(tokens)
                tokens_intencion.extend(tokens)
            ejemplos_por_intencion[intencion] = tokens_intencion
        
        self.vectorizador.construir(todos_los_tokens)
        
        # Vectorizamos el "texto combinado" de cada intención
        for intencion, tokens_combinados in ejemplos_por_intencion.items():
            self.vectores_intencion[intencion] = self.vectorizador.vectorizar(
                tokens_combinados
            )
        
        print(f"🧠 NLP iniciado: {len(INTENCIONES)} intenciones, "
              f"vocabulario de {self.vectorizador.dimension()} palabras")
    
    def clasificar(self, texto: str) -> dict:
        """
        Clasifica un texto y devuelve la intención más probable.
        
        Returns:
          {
            "intencion": "analizar",      # el comando a ejecutar
            "confianza": 0.87,            # qué tan seguro estamos
            "tokens": ["hay","intrusos"], # lo que entendió
            "ambiguo": False              # si hay empate cercano
          }
        """
        tokens = normalizar(texto)
        
        if not tokens:
            return {"intencion": None, "confianza": 0.0, 
                    "tokens": [], "ambiguo": False}
        
        vector_entrada = self.vectorizador.vectorizar(tokens)
        
        # Calcular similitud contra cada intención
        similitudes = {}
        for intencion, vector_ref in self.vectores_intencion.items():
            similitudes[intencion] = similitud_coseno(vector_entrada, vector_ref)
        
        # Ordenar por similitud descendente
        ranking = sorted(similitudes.items(), key=lambda x: x[1], reverse=True)
        mejor_intencion, mejor_score = ranking[0]
        segunda_intencion, segundo_score = ranking[1] if len(ranking) > 1 else (None, 0)
        
        # Considerar ambiguo si el segundo está muy cerca del primero
        ambiguo = (mejor_score > 0 and segundo_score > 0 and 
                   (mejor_score - segundo_score) < 0.08)
        
        if mejor_score < self.umbral:
            return {
                "intencion": None,
                "confianza": mejor_score,
                "tokens": tokens,
                "ambiguo": False,
                "ranking": ranking[:3]
            }
        
        return {
            "intencion": mejor_intencion,
            "confianza": round(mejor_score, 3),
            "tokens": tokens,
            "ambiguo": ambiguo,
            "segunda_opcion": segunda_intencion if ambiguo else None,
            "ranking": ranking[:3]
        }
    
    def aprender_ejemplo(self, texto: str, intencion: str):
        """
        El usuario puede enseñarle al NLP nuevos ejemplos en tiempo real.
        Re-entrena el vector de esa intención incorporando el nuevo texto.
        
        Esto es aprendizaje online (incremental): el modelo mejora
        sin tener que re-entrenarse desde cero.
        """
        tokens = normalizar(texto)
        if not tokens or intencion not in self.vectores_intencion:
            return False
        
        # Actualizar el vocabulario si hay palabras nuevas
        nuevas = [t for t in tokens if t not in self.vectorizador.vocabulario]
        if nuevas:
            for palabra in nuevas:
                self.vectorizador.vocabulario[palabra] = len(self.vectorizador.vocabulario)
            # Re-vectorizar todas las intenciones con el vocabulario expandido
            self._expandir_vectores(len(nuevas))
        
        # Agregar el nuevo ejemplo al vector de la intención
        nuevo_vec = self.vectorizador.vectorizar(tokens)
        vec_actual = self.vectores_intencion[intencion]
        
        # Promedio ponderado: damos más peso al vector existente (momento 0.8)
        # para no sobre-aprender un solo ejemplo
        self.vectores_intencion[intencion] = [
            0.8 * v + 0.2 * n for v, n in zip(vec_actual, nuevo_vec)
        ]
        return True
    
    def _expandir_vectores(self, n_nuevas: int):
        """Agrega ceros al final de todos los vectores cuando el vocabulario crece."""
        for intencion in self.vectores_intencion:
            self.vectores_intencion[intencion].extend([0.0] * n_nuevas)
    
    def procesar_input(self, texto: str, modo_debug: bool = False) -> tuple:
        """
        Interfaz principal: toma texto libre, devuelve (comando, args).
        
        Maneja casos especiales como "info 192.168.1.1" donde
        hay un comando + un argumento IP.
        """
        texto = texto.strip()
        
        # Detectar si hay una IP en el texto (argumento)
        patron_ip = r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b'
        ips_encontradas = re.findall(patron_ip, texto)
        
        # Detectar rango de IPs
        ips_rango = re.findall(patron_ip, texto)
        
        resultado = self.clasificar(texto)
        
        if modo_debug:
            print(f"\n🔍 NLP Debug:")
            print(f"   Tokens:    {resultado['tokens']}")
            print(f"   Intención: {resultado['intencion']}")
            print(f"   Confianza: {resultado['confianza']:.3f}")
            if resultado.get("ranking"):
                for intent, score in resultado["ranking"]:
                    print(f"   {intent:20} {score:.3f}")
        
        intencion = resultado["intencion"]
        
        if intencion is None:
            return None, []
        
        # Construir args según la intención
        args = []
        if intencion in ("info", "puertos", "todos_puertos", "mac", "ping", "so",
                         "marcar_intruso", "marcar_seguro", "watch") and ips_encontradas:
            args = [ips_encontradas[0]]
        elif intencion == "scan_rango" and len(ips_rango) >= 2:
            args = [ips_rango[0], ips_rango[1]]
        
        return intencion, args