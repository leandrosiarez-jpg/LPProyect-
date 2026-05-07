# red_profunda.py - Red neuronal multicapa (MLP) desde cero
#
# ARQUITECTURA:
#   Entrada (7 features) → Capa oculta 1 (12 neuronas, ReLU)
#                        → Capa oculta 2 (8 neuronas, ReLU)
#                        → Salida (1 neurona, Sigmoide)
#
# ¿POR QUÉ MÁS CAPAS?
#   neurona.py tiene 1 capa → solo aprende relaciones lineales
#   2 capas ocultas → puede aprender patrones no lineales complejos
#   Ejemplo: "dispositivo con MAC desconocida Y muchos puertos Y TTL raro"
#   es una combinación que la red simple no puede capturar bien
#
# BACKPROPAGATION (retropropagación del error):
#   Paso hacia adelante:  entrada → capas → predicción
#   Calcular error:       comparar predicción con la realidad
#   Paso hacia atrás:     propagar el error hacia atrás, ajustar pesos
#   El gradiente indica la dirección en que sube el error
#   Movemos los pesos en la dirección OPUESTA (gradiente descendente)

import json
import math
import random
import os
from datetime import datetime


# ─────────────────────────────────────────────
#  FUNCIONES DE ACTIVACIÓN Y SUS DERIVADAS
#  Las derivadas son esenciales para backpropagation
# ─────────────────────────────────────────────

def relu(z):
    """ReLU: max(0, z). Simple pero muy efectiva en capas ocultas."""
    return max(0.0, z)

def relu_d(z):
    """Derivada de ReLU: 1 si z > 0, 0 si no. Esto es el 'gradiente local'."""
    return 1.0 if z > 0 else 0.0

def sigmoid(z):
    z = max(-500.0, min(500.0, z))
    return 1.0 / (1.0 + math.exp(-z))

def sigmoid_d(s):
    """Derivada de sigmoid dado s = sigmoid(z). s*(1-s)"""
    return s * (1.0 - s)

def dot(W_fila, x):
    """Producto punto de un vector fila de pesos con el vector de entrada."""
    return sum(w * xi for w, xi in zip(W_fila, x))


# ─────────────────────────────────────────────
#  CAPA DENSA
#  Bloque fundamental: n_entradas → n_neuronas
# ─────────────────────────────────────────────

class CapaDensa:
    """
    Una capa fully-connected (densa):
    cada neurona se conecta con TODAS las entradas.
    
    ESTRUCTURA INTERNA:
      W: matriz de pesos  [n_neuronas × n_entradas]
         W[i][j] = peso de la entrada j hacia la neurona i
      b: vector de bias   [n_neuronas]
         b[i] = bias de la neurona i
    
    FORWARD PASS (cálculo hacia adelante):
      Para cada neurona i:
        z_i = sum(W[i][j] * x[j]) + b[i]   ← combinación lineal
        a_i = activacion(z_i)                ← aplicar no-linealidad
    
    INICIALIZACIÓN DE XAVIER:
      Si los pesos empiezan muy grandes → gradientes explotan
      Si los pesos empiezan muy chicos  → gradientes desaparecen
      Xavier usa ±sqrt(6 / (n_entrada + n_salida)) como rango
      Esto mantiene la varianza de activaciones estable entre capas
    """
    
    def __init__(self, n_entradas: int, n_neuronas: int, activacion: str = "relu"):
        self.n_entradas = n_entradas
        self.n_neuronas = n_neuronas
        self.activacion_nombre = activacion
        
        # Inicialización Xavier/Glorot
        limite = math.sqrt(6.0 / (n_entradas + n_neuronas))
        self.W = [
            [random.uniform(-limite, limite) for _ in range(n_entradas)]
            for _ in range(n_neuronas)
        ]
        self.b = [0.0] * n_neuronas
        
        # Gradientes acumulados (para el paso de backprop)
        self.grad_W = [[0.0] * n_entradas for _ in range(n_neuronas)]
        self.grad_b = [0.0] * n_neuronas
        
        # Cache del forward pass (necesario para backprop)
        self.ultima_entrada = None
        self.ultimos_z     = None
        self.ultima_salida = None
    
    def forward(self, x: list) -> list:
        """
        Pasa la entrada x a través de esta capa.
        Guarda z y a en cache para usarlos en backprop.
        """
        self.ultima_entrada = x[:]
        self.ultimos_z = []
        self.ultima_salida = []
        
        for i in range(self.n_neuronas):
            z = dot(self.W[i], x) + self.b[i]
            self.ultimos_z.append(z)
            
            if self.activacion_nombre == "relu":
                a = relu(z)
            elif self.activacion_nombre == "sigmoid":
                a = sigmoid(z)
            else:
                a = z  # lineal
            
            self.ultima_salida.append(a)
        
        return self.ultima_salida[:]
    
    def backward(self, delta_siguiente: list) -> list:
        """
        Recibe el delta (error propagado) de la capa siguiente.
        Calcula:
          1. Los gradientes de W y b (para actualizar los pesos)
          2. El delta para la capa anterior (para seguir propagando)
        
        REGLA DE LA CADENA (chain rule):
          dL/dW[i][j] = delta[i] * x[j]
          dL/db[i]    = delta[i]
          dL/dx[j]    = sum_i(delta[i] * W[i][j])  ← delta para la capa anterior
        
        donde delta[i] = error_llegado[i] * derivada_activacion(z[i])
        """
        delta_local = []
        
        for i in range(self.n_neuronas):
            # Derivada de la función de activación en z_i
            if self.activacion_nombre == "relu":
                d_act = relu_d(self.ultimos_z[i])
            elif self.activacion_nombre == "sigmoid":
                d_act = sigmoid_d(self.ultima_salida[i])
            else:
                d_act = 1.0
            
            d = delta_siguiente[i] * d_act
            delta_local.append(d)
            
            # Acumular gradientes
            for j in range(self.n_entradas):
                self.grad_W[i][j] += d * self.ultima_entrada[j]
            self.grad_b[i] += d
        
        # Delta para la capa anterior: suma ponderada de deltas actuales
        delta_prev = [
            sum(delta_local[i] * self.W[i][j] for i in range(self.n_neuronas))
            for j in range(self.n_entradas)
        ]
        return delta_prev
    
    def actualizar_pesos(self, lr: float):
        """Gradiente descendente: mover pesos en dirección opuesta al gradiente."""
        for i in range(self.n_neuronas):
            for j in range(self.n_entradas):
                self.W[i][j] -= lr * self.grad_W[i][j]
                self.grad_W[i][j] = 0.0  # limpiar para el próximo batch
            self.b[i] -= lr * self.grad_b[i]
            self.grad_b[i] = 0.0


# ─────────────────────────────────────────────
#  RED NEURONAL PROFUNDA (MLP)
#  Apila capas densas y coordina el entrenamiento
# ─────────────────────────────────────────────

class RedProfunda:
    """
    MLP de 3 capas para clasificación de dispositivos de red.
    
    Arquitectura:
      7 features → [12 ReLU] → [8 ReLU] → [1 Sigmoid]
    
    La salida es un valor entre 0 y 1:
      < 0.3   → riesgo BAJO
      0.3-0.6 → riesgo MEDIO  
      0.6-0.8 → riesgo ALTO
      > 0.8   → riesgo CRÍTICO
    
    VENTAJA SOBRE neurona.py:
      neurona.py tiene 3 neuronas independientes (no se comunican)
      Esta red tiene 12+8+1 = 21 neuronas que aprenden juntas
      Las capas ocultas detectan combinaciones complejas de features
    """
    
    ARCHIVO_PESOS = "datos/red_profunda_pesos.json"
    N_FEATURES = 7
    
    def __init__(self, lr: float = 0.01):
        self.lr = lr
        self.epocas_entrenadas = 0
        self.historial_loss = []
        
        # Arquitectura: 7 → 12 → 8 → 1
        self.capas = [
            CapaDensa(7,  12, "relu"),
            CapaDensa(12,  8, "relu"),
            CapaDensa(8,   1, "sigmoid"),
        ]
        
        self.cargar_pesos()
    
    # ── Forward y Backward ─────────────────────
    
    def predecir(self, x: list) -> float:
        """
        Forward pass completo: entrada → salida.
        La entrada pasa secuencialmente por cada capa.
        """
        activacion = x[:]
        for capa in self.capas:
            activacion = capa.forward(activacion)
        return activacion[0]  # salida única entre 0 y 1
    
    def entrenar_uno(self, x: list, objetivo: float) -> float:
        """
        Entrena con UN ejemplo: forward → calcular error → backward → actualizar.
        
        FUNCIÓN DE PÉRDIDA: Binary Cross-Entropy
          L = -(y*log(ŷ) + (1-y)*log(1-ŷ))
          
          Es mejor que MSE para clasificación porque penaliza más
          las predicciones muy equivocadas con mucha confianza.
          Ej: predecir 0.99 cuando la respuesta era 0 → penalidad enorme.
        
        GRADIENTE INICIAL (dL/dŷ para cross-entropy + sigmoid):
          Se simplifica a: ŷ - y
          Esto es lo que inicializa la retropropagación.
        """
        # Forward
        prediccion = self.predecir(x)
        
        # Pérdida BCE
        eps = 1e-12  # evitar log(0)
        loss = -(objetivo * math.log(prediccion + eps) + 
                 (1 - objetivo) * math.log(1 - prediccion + eps))
        
        # Gradiente inicial: derivada de BCE + sigmoid = prediccion - objetivo
        grad_inicial = [prediccion - objetivo]
        
        # Backward pass: propagar gradiente de atrás hacia adelante
        grad = grad_inicial
        for capa in reversed(self.capas):
            grad = capa.backward(grad)
        
        # Actualizar todos los pesos
        for capa in self.capas:
            capa.actualizar_pesos(self.lr)
        
        return loss
    
    def entrenar_lote(self, ejemplos: list, epocas: int = 100) -> list:
        """
        Entrena con un lote de ejemplos durante múltiples épocas.
        
        Una ÉPOCA = ver todos los ejemplos una vez.
        Mezclamos (shuffle) en cada época para evitar que el orden
        influya en el aprendizaje.
        
        ejemplos: lista de (features_lista, objetivo_float)
        """
        if not ejemplos:
            return []
        
        historial = []
        for epoca in range(epocas):
            random.shuffle(ejemplos)
            loss_total = sum(
                self.entrenar_uno(x, y) for x, y in ejemplos
            )
            loss_promedio = loss_total / len(ejemplos)
            historial.append(loss_promedio)
            self.epocas_entrenadas += 1
        
        self.historial_loss.extend(historial[-20:])  # guardar últimas 20
        self.guardar_pesos()
        return historial
    
    # ── Análisis ───────────────────────────────
    
    def analizar(self, dispositivo: dict) -> dict:
        """
        Analiza un dispositivo y devuelve predicción con etiqueta.
        Importamos extraer_features de neurona.py para reutilizar la lógica.
        """
        from neurona import extraer_features
        features = extraer_features(dispositivo)
        riesgo = self.predecir(features)
        
        if riesgo < 0.3:
            etiqueta = "BAJO"
        elif riesgo < 0.6:
            etiqueta = "MEDIO"
        elif riesgo < 0.8:
            etiqueta = "ALTO"
        else:
            etiqueta = "CRÍTICO"
        
        return {
            "ip":      dispositivo.get("ip", "N/A"),
            "riesgo":  round(riesgo, 3),
            "etiqueta": etiqueta,
            "confianza": "alta" if abs(riesgo - 0.5) > 0.3 else "media"
        }
    
    def analizar_red(self, dispositivos: list) -> list:
        return [self.analizar(d) for d in dispositivos]
    
    # ── Persistencia ───────────────────────────
    
    def guardar_pesos(self):
        datos = {
            "timestamp": datetime.now().isoformat(),
            "lr": self.lr,
            "epocas_entrenadas": self.epocas_entrenadas,
            "historial_loss": self.historial_loss[-50:],
            "capas": [
                {
                    "n_entradas":   c.n_entradas,
                    "n_neuronas":   c.n_neuronas,
                    "activacion":   c.activacion_nombre,
                    "W":            c.W,
                    "b":            c.b,
                }
                for c in self.capas
            ]
        }
        os.makedirs("datos", exist_ok=True)
        with open(self.ARCHIVO_PESOS, "w", encoding="utf-8") as f:
            json.dump(datos, f, indent=2)
    
    def cargar_pesos(self):
        if not os.path.exists(self.ARCHIVO_PESOS):
            return
        try:
            with open(self.ARCHIVO_PESOS, "r", encoding="utf-8") as f:
                datos = json.load(f)
            for i, cd in enumerate(datos.get("capas", [])):
                if i < len(self.capas):
                    self.capas[i].W = cd["W"]
                    self.capas[i].b = cd["b"]
            self.epocas_entrenadas = datos.get("epocas_entrenadas", 0)
            self.historial_loss = datos.get("historial_loss", [])
            print(f"🧠 Red profunda: pesos cargados ({self.epocas_entrenadas} épocas)")
        except Exception as e:
            print(f"⚠️  No se pudieron cargar pesos de red profunda: {e}")