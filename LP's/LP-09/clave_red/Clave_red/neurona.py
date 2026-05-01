# neurona.py - Sistema de neuronas con aprendizaje para C.L.A.V.E.
# Perceptrón  → clasifica si un dispositivo es intruso (0 o 1)
# Sigmoide    → estima probabilidad de riesgo (0.0 a 1.0)
# ReLU        → capa oculta que combina señales (score continuo)

import json
import os
import math
from datetime import datetime


# ─────────────────────────────────────────────
#  UTILIDADES
# ─────────────────────────────────────────────

def _relu(z):
    return max(0.0, z)

def _relu_deriv(z):
    return 1.0 if z > 0 else 0.0

def _sigmoid(z):
    z = max(-500, min(500, z))          # evitar overflow
    return 1.0 / (1.0 + math.exp(-z))

def _sigmoid_deriv(s):                  # s = sigmoid(z) ya calculado
    return s * (1.0 - s)

def _dot(pesos, entradas):
    return sum(p * e for p, e in zip(pesos, entradas))


# ─────────────────────────────────────────────
#  EXTRACTOR DE FEATURES
#  Convierte un dict de dispositivo en un vector numérico normalizado
# ─────────────────────────────────────────────

PUERTOS_PELIGROSOS = {21, 23, 445, 1433, 3389, 5900, 8080}
PUERTOS_COMUNES    = {22, 80, 443, 53, 8443}

def extraer_features(dispositivo: dict) -> list:
    """
    Devuelve un vector de 7 features en [0, 1]:
      0  tiene_mac          - MAC detectada (no "No disponible")
      1  mac_desconocida    - fabricante desconocido
      2  tiene_nombre_dns   - hostname resuelto
      3  puertos_peligrosos - tiene al menos un puerto peligroso
      4  puertos_normalizados - cantidad de puertos / 10, capped en 1
      5  ttl_bajo           - TTL < 64 (puede indicar router/IoT raro)
      6  sin_puertos        - ningún puerto abierto detectado
    """
    mac = dispositivo.get("mac", "No disponible")
    fab = dispositivo.get("fabricante", "Desconocido")
    nombre = dispositivo.get("nombre", "Desconocido")
    puertos = dispositivo.get("puertos", [])
    ttl = dispositivo.get("ttl", 128)

    numeros_puertos = set(p["puerto"] for p in puertos) if puertos else set()
    cantidad_puertos = len(numeros_puertos)

    tiene_mac           = 0.0 if mac in ("No disponible", "", None) else 1.0
    mac_desconocida     = 1.0 if fab in ("Desconocido", "", None)   else 0.0
    tiene_nombre_dns    = 0.0 if nombre in ("Desconocido", "", None) else 1.0
    tiene_peligrosos    = 1.0 if numeros_puertos & PUERTOS_PELIGROSOS else 0.0
    ports_norm          = min(1.0, cantidad_puertos / 10.0)
    ttl_bajo            = 1.0 if (ttl and ttl < 64) else 0.0
    sin_puertos         = 1.0 if cantidad_puertos == 0 else 0.0

    return [
        tiene_mac,
        mac_desconocida,
        tiene_nombre_dns,
        tiene_peligrosos,
        ports_norm,
        ttl_bajo,
        sin_puertos,
    ]


# ─────────────────────────────────────────────
#  NEURONA PERCEPTRÓN
#  Clasificación binaria: ¿es un intruso? → 0 (no) / 1 (sí)
#  Aprende con la Regla Delta
# ─────────────────────────────────────────────

class Perceptron:
    N_ENTRADAS = 7

    def __init__(self, tasa_aprendizaje=0.1):
        self.lr     = tasa_aprendizaje
        self.pesos  = [0.0] * self.N_ENTRADAS
        self.bias   = 0.0
        self.epocas = 0

        # Pesos iniciales heurísticos (lógica de red)
        # mac_desconocida y puertos_peligrosos tienen peso alto positivo
        # tiene_mac y tiene_nombre_dns tienen peso negativo (baja sospecha)
        self.pesos = [
            -0.4,   # tiene_mac          (tiene MAC → menos sospechoso)
             0.6,   # mac_desconocida    (sin fabricante → más sospechoso)
            -0.3,   # tiene_nombre_dns   (nombre conocido → menos sospechoso)
             0.8,   # puertos_peligrosos (FTP/Telnet/RDP → muy sospechoso)
             0.3,   # puertos_norm       (muchos puertos → algo sospechoso)
             0.2,   # ttl_bajo           (TTL raro → leve sospecha)
             0.1,   # sin_puertos        (ningún puerto → neutro)
        ]
        self.bias = -0.3

    def predecir(self, entradas: list) -> int:
        z = _dot(self.pesos, entradas) + self.bias
        return 1 if z >= 0 else 0

    def entrenar(self, entradas: list, objetivo: int):
        """Regla Delta: w += lr * (objetivo - prediccion) * entrada"""
        prediccion = self.predecir(entradas)
        error = objetivo - prediccion
        if error != 0:
            for i in range(len(self.pesos)):
                self.pesos[i] += self.lr * error * entradas[i]
            self.bias += self.lr * error
        self.epocas += 1
        return abs(error)

    def entrenar_lote(self, ejemplos: list, epocas=20):
        """ejemplos = [(features, etiqueta), ...]"""
        historial = []
        for _ in range(epocas):
            errores = sum(self.entrenar(x, y) for x, y in ejemplos)
            historial.append(errores)
        return historial


# ─────────────────────────────────────────────
#  NEURONA SIGMOIDE
#  Regresión logística: probabilidad de riesgo en [0, 1]
#  Aprende con Gradiente Descendente (backpropagation de 1 capa)
# ─────────────────────────────────────────────

class NeuronaSigmoide:
    N_ENTRADAS = 7

    def __init__(self, tasa_aprendizaje=0.05):
        self.lr    = tasa_aprendizaje
        self.bias  = 0.0
        self.epocas = 0

        # Pesos iniciales alineados con la lógica de riesgo
        self.pesos = [
            -0.5,   # tiene_mac
             0.7,   # mac_desconocida
            -0.4,   # tiene_nombre_dns
             1.0,   # puertos_peligrosos
             0.4,   # puertos_norm
             0.3,   # ttl_bajo
             0.0,   # sin_puertos
        ]
        self.bias = -0.5

    def predecir(self, entradas: list) -> float:
        z = _dot(self.pesos, entradas) + self.bias
        return _sigmoid(z)

    def entrenar(self, entradas: list, objetivo: float):
        """
        Backpropagation de una capa:
          loss = (objetivo - salida)²  (MSE)
          dL/dw = -(objetivo - salida) * sigmoid'(z) * entrada
        """
        salida = self.predecir(entradas)
        z      = _dot(self.pesos, entradas) + self.bias
        delta  = (objetivo - salida) * _sigmoid_deriv(_sigmoid(z))

        for i in range(len(self.pesos)):
            self.pesos[i] += self.lr * delta * entradas[i]
        self.bias += self.lr * delta

        self.epocas += 1
        return 0.5 * (objetivo - salida) ** 2   # loss MSE

    def entrenar_lote(self, ejemplos: list, epocas=30):
        """ejemplos = [(features, probabilidad_objetivo), ...]"""
        historial = []
        for _ in range(epocas):
            loss = sum(self.entrenar(x, y) for x, y in ejemplos) / max(len(ejemplos), 1)
            historial.append(loss)
        return historial


# ─────────────────────────────────────────────
#  NEURONA ReLU  (capa oculta)
#  Combina las salidas del Perceptrón y la Sigmoide en un score final
#  También aprende cuánto peso darle a cada neurona anterior
# ─────────────────────────────────────────────

class NeuronasReLU:
    """
    Mini red de 2 capas:
      Capa oculta: 4 neuronas ReLU sobre las 7 features
      Capa salida: 1 neurona lineal que produce el score combinado
    """
    N_ENTRADAS  = 7
    N_OCULTAS   = 4

    def __init__(self, tasa_aprendizaje=0.01):
        self.lr = tasa_aprendizaje

        # Pesos capa oculta: shape (N_OCULTAS, N_ENTRADAS)
        self.W1 = [
            [-0.3,  0.5, -0.2,  0.8,  0.3,  0.2,  0.1],
            [ 0.4, -0.1,  0.3,  0.6,  0.5,  0.1, -0.2],
            [-0.2,  0.6, -0.4,  0.7,  0.2,  0.4,  0.0],
            [ 0.1,  0.3,  0.1,  0.9,  0.4,  0.3,  0.2],
        ]
        self.b1 = [-0.1, -0.1, -0.2, -0.15]

        # Pesos capa salida: shape (N_OCULTAS,)
        self.W2 = [0.4, 0.3, 0.3, 0.5]
        self.b2 = -0.3

        self.epocas = 0

    def _forward(self, entradas):
        # Capa oculta con ReLU
        z1 = [_dot(self.W1[j], entradas) + self.b1[j] for j in range(self.N_OCULTAS)]
        a1 = [_relu(z) for z in z1]
        # Capa de salida (lineal, para score continuo)
        z2 = _dot(self.W2, a1) + self.b2
        return z1, a1, z2

    def predecir(self, entradas: list) -> float:
        _, _, z2 = self._forward(entradas)
        return max(0.0, z2)   # ReLU en salida también: score ≥ 0

    def entrenar(self, entradas: list, objetivo: float):
        z1, a1, z2 = self._forward(entradas)
        salida = max(0.0, z2)

        # Gradiente capa salida
        d_out = salida - objetivo
        d_z2  = d_out * _relu_deriv(z2)

        dW2 = [d_z2 * a for a in a1]
        db2 = d_z2

        # Gradiente capa oculta
        d_a1 = [self.W2[j] * d_z2 for j in range(self.N_OCULTAS)]
        d_z1 = [d_a1[j] * _relu_deriv(z1[j]) for j in range(self.N_OCULTAS)]

        dW1 = [[d_z1[j] * entradas[i] for i in range(self.N_ENTRADAS)] for j in range(self.N_OCULTAS)]
        db1 = list(d_z1)

        # Actualizar pesos
        for j in range(self.N_OCULTAS):
            self.W2[j] -= self.lr * dW2[j]
            self.b2     -= self.lr * db2
            for i in range(self.N_ENTRADAS):
                self.W1[j][i] -= self.lr * dW1[j][i]
            self.b1[j] -= self.lr * db1[j]

        self.epocas += 1
        return 0.5 * (salida - objetivo) ** 2

    def entrenar_lote(self, ejemplos: list, epocas=30):
        historial = []
        for _ in range(epocas):
            loss = sum(self.entrenar(x, y) for x, y in ejemplos) / max(len(ejemplos), 1)
            historial.append(loss)
        return historial


# ─────────────────────────────────────────────
#  CEREBRO NEURONAL  (orquesta las 3 neuronas)
# ─────────────────────────────────────────────

class CerebroNeuronal:
    ARCHIVO_PESOS = "datos/pesos_neurona.json"

    def __init__(self):
        self.perceptron = Perceptron()
        self.sigmoide   = NeuronaSigmoide()
        self.relu       = NeuronasReLU()
        self.historial_aprendizaje = []

        os.makedirs("datos", exist_ok=True)
        self._cargar_pesos()

    # ── Serialización ──────────────────────────────────────────────

    def _cargar_pesos(self):
        if not os.path.exists(self.ARCHIVO_PESOS):
            return
        try:
            with open(self.ARCHIVO_PESOS, "r", encoding="utf-8") as f:
                d = json.load(f)
            p = d.get("perceptron", {})
            self.perceptron.pesos  = p.get("pesos",  self.perceptron.pesos)
            self.perceptron.bias   = p.get("bias",   self.perceptron.bias)
            self.perceptron.epocas = p.get("epocas", 0)

            s = d.get("sigmoide", {})
            self.sigmoide.pesos  = s.get("pesos",  self.sigmoide.pesos)
            self.sigmoide.bias   = s.get("bias",   self.sigmoide.bias)
            self.sigmoide.epocas = s.get("epocas", 0)

            r = d.get("relu", {})
            self.relu.W1   = r.get("W1",    self.relu.W1)
            self.relu.b1   = r.get("b1",    self.relu.b1)
            self.relu.W2   = r.get("W2",    self.relu.W2)
            self.relu.b2   = r.get("b2",    self.relu.b2)
            self.relu.epocas = r.get("epocas", 0)

            self.historial_aprendizaje = d.get("historial", [])
            print("🧠 Pesos neuronales cargados desde disco")
        except Exception as e:
            print(f"⚠️  No se pudieron cargar pesos: {e}")

    def guardar_pesos(self):
        datos = {
            "timestamp": datetime.now().isoformat(),
            "perceptron": {
                "pesos":  self.perceptron.pesos,
                "bias":   self.perceptron.bias,
                "epocas": self.perceptron.epocas,
            },
            "sigmoide": {
                "pesos":  self.sigmoide.pesos,
                "bias":   self.sigmoide.bias,
                "epocas": self.sigmoide.epocas,
            },
            "relu": {
                "W1":    self.relu.W1,
                "b1":    self.relu.b1,
                "W2":    self.relu.W2,
                "b2":    self.relu.b2,
                "epocas": self.relu.epocas,
            },
            "historial": self.historial_aprendizaje[-50:],  # últimas 50 entradas
        }
        with open(self.ARCHIVO_PESOS, "w", encoding="utf-8") as f:
            json.dump(datos, f, indent=2, ensure_ascii=False)
        print(f"💾 Pesos guardados en {self.ARCHIVO_PESOS}")

    # ── Análisis ────────────────────────────────────────────────────

    def analizar_dispositivo(self, dispositivo: dict) -> dict:
        """
        Analiza un dispositivo y devuelve:
          - es_intruso   : bool (Perceptrón)
          - riesgo       : float 0-1 (Sigmoide)
          - score        : float ≥ 0 (ReLU combinado)
          - etiqueta     : str  (BAJO / MEDIO / ALTO / CRÍTICO)
          - explicacion  : list de str
        """
        features = extraer_features(dispositivo)

        es_intruso = bool(self.perceptron.predecir(features))
        riesgo     = self.sigmoide.predecir(features)
        score      = self.relu.predecir(features)

        # Etiqueta final combinando las 3 neuronas
        if riesgo < 0.3 and not es_intruso:
            etiqueta = "BAJO"
        elif riesgo < 0.55:
            etiqueta = "MEDIO"
        elif riesgo < 0.75:
            etiqueta = "ALTO"
        else:
            etiqueta = "CRÍTICO"

        # Explicación legible
        explicacion = []
        if features[0] == 0:
            explicacion.append("Sin MAC detectada")
        if features[1] == 1:
            explicacion.append("Fabricante desconocido")
        if features[2] == 0:
            explicacion.append("Sin nombre DNS")
        if features[3] == 1:
            explicacion.append("Puertos peligrosos abiertos (FTP/Telnet/RDP/SMB)")
        if features[4] > 0.5:
            explicacion.append(f"Muchos puertos abiertos ({int(features[4]*10)}+)")
        if features[5] == 1:
            explicacion.append("TTL anómalo (<64)")
        if not explicacion:
            explicacion.append("Sin señales de riesgo detectadas")

        return {
            "ip":         dispositivo.get("ip", "N/A"),
            "es_intruso": es_intruso,
            "riesgo":     round(riesgo, 3),
            "score":      round(score, 3),
            "etiqueta":   etiqueta,
            "features":   features,
            "explicacion": explicacion,
        }

    def analizar_red(self, dispositivos: list) -> list:
        """Analiza toda la lista de dispositivos escaneados"""
        return [self.analizar_dispositivo(d) for d in dispositivos]

    # ── Aprendizaje ─────────────────────────────────────────────────

    def aprender_de_red(self, dispositivos: list):
        """
        Genera ejemplos de entrenamiento automáticos a partir
        de los propios dispositivos escaneados y re-entrena
        las 3 neuronas con ellos.
        """
        if not dispositivos:
            print("⚠️  No hay dispositivos para aprender")
            return

        ejemplos_perceptron = []
        ejemplos_sigmoide   = []
        ejemplos_relu       = []

        for d in dispositivos:
            features = extraer_features(d)

            # Etiqueta heurística para el Perceptrón
            mac_ok     = features[0] == 1.0
            fab_ok     = features[1] == 0.0
            nombre_ok  = features[2] == 1.0
            peligroso  = features[3] == 1.0
            muchos_p   = features[4] > 0.5

            # Si tiene MAC + fabricante conocido + nombre DNS → probablemente legítimo
            es_legitimo = mac_ok and fab_ok and nombre_ok
            # Si tiene puertos peligrosos y sin MAC → sospechoso
            es_sospechoso = peligroso and (not mac_ok or not fab_ok)

            etiqueta_p = 1 if es_sospechoso else 0
            prob_riesgo = min(1.0, features[3] * 0.5 + features[1] * 0.3 + (1 - features[0]) * 0.2 + features[4] * 0.2)
            score_r     = prob_riesgo * 2.0   # rango más amplio para ReLU

            ejemplos_perceptron.append((features, etiqueta_p))
            ejemplos_sigmoide.append((features, prob_riesgo))
            ejemplos_relu.append((features, score_r))

        # Entrenar las 3 neuronas
        h_p = self.perceptron.entrenar_lote(ejemplos_perceptron, epocas=50)
        h_s = self.sigmoide.entrenar_lote(ejemplos_sigmoide,   epocas=50)
        h_r = self.relu.entrenar_lote(ejemplos_relu,           epocas=50)

        self.historial_aprendizaje.append({
            "timestamp":           datetime.now().isoformat(),
            "n_dispositivos":      len(dispositivos),
            "loss_final_perceptron": h_p[-1],
            "loss_final_sigmoide":   h_s[-1],
            "loss_final_relu":       h_r[-1],
        })

        self.guardar_pesos()
        print(f"🧠 Aprendizaje completado con {len(dispositivos)} dispositivos")
        print(f"   Perceptrón  — errores finales: {h_p[-1]:.3f}")
        print(f"   Sigmoide    — loss final:      {h_s[-1]:.4f}")
        print(f"   ReLU        — loss final:      {h_r[-1]:.4f}")

    def marcar_como_intruso(self, dispositivo: dict):
        """El usuario marca manualmente un dispositivo como intruso → refuerza el aprendizaje"""
        features = extraer_features(dispositivo)
        for _ in range(20):
            self.perceptron.entrenar(features, 1)
            self.sigmoide.entrenar(features, 0.95)
            self.relu.entrenar(features, 1.9)
        self.guardar_pesos()
        print(f"🎯 Dispositivo {dispositivo.get('ip')} marcado como intruso y aprendido")

    def marcar_como_seguro(self, dispositivo: dict):
        """El usuario confirma que un dispositivo es seguro → refuerza el aprendizaje"""
        features = extraer_features(dispositivo)
        for _ in range(20):
            self.perceptron.entrenar(features, 0)
            self.sigmoide.entrenar(features, 0.05)
            self.relu.entrenar(features, 0.05)
        self.guardar_pesos()
        print(f"✅ Dispositivo {dispositivo.get('ip')} marcado como seguro y aprendido")

    def estado_neuronas(self):
        """Muestra el estado actual de las 3 neuronas"""
        print("\n🧠 ESTADO DE LAS NEURONAS")
        print("=" * 50)
        print(f"  Perceptrón  — épocas entrenadas: {self.perceptron.epocas}")
        print(f"               pesos: {[round(p,3) for p in self.perceptron.pesos]}")
        print(f"               bias:  {round(self.perceptron.bias, 3)}")
        print(f"  Sigmoide    — épocas entrenadas: {self.sigmoide.epocas}")
        print(f"               pesos: {[round(p,3) for p in self.sigmoide.pesos]}")
        print(f"               bias:  {round(self.sigmoide.bias, 3)}")
        print(f"  ReLU        — épocas entrenadas: {self.relu.epocas}")
        print(f"               W2 (salida): {[round(w,3) for w in self.relu.W2]}")
        if self.historial_aprendizaje:
            ultimo = self.historial_aprendizaje[-1]
            print(f"\n  Último entrenamiento: {ultimo['timestamp']}")
            print(f"  Dispositivos vistos:  {ultimo['n_dispositivos']}")
        print("=" * 50)