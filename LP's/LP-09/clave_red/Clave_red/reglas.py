# reglas.py - Motor de reglas + IA combinado
#
# FILOSOFÍA: "Si las reglas son suficientes, úsalas. Si no, delegá a la IA."
#
# Las REGLAS EXPLÍCITAS son buenas para casos claros y conocidos:
#   - Puerto 23 abierto → siempre es riesgo (Telnet, protocolo inseguro)
#   - MAC "00:00:00:00:00:00" → claramente falsa
#   - IP .1 del gateway → claramente el router
#
# La IA (red profunda + neurona.py) es buena para casos ambiguos:
#   - Dispositivo con fabricante raro + varios puertos medianos
#   - Patrones que emergen del historial de la red
#
# COMBINACIÓN: score_final = 0.4 * reglas + 0.6 * red_neuronal
# Los pesos se pueden ajustar según cuánto confiás en cada uno.

from red_profunda import RedProfunda
from neurona import CerebroNeuronal, extraer_features


# ─────────────────────────────────────────────
#  BASE DE REGLAS
# ─────────────────────────────────────────────

class Regla:
    """Una regla individual: condición → puntuación de riesgo."""
    def __init__(self, nombre: str, condicion, puntuacion: float, explicacion: str):
        self.nombre = nombre
        self.condicion = condicion      # función que toma un dispositivo y devuelve bool
        self.puntuacion = puntuacion    # cuánto riesgo suma (0.0 a 1.0)
        self.explicacion = explicacion  # texto legible para el usuario


# Definición de todas las reglas del sistema
REGLAS = [
    Regla(
        "telnet_abierto",
        lambda d: any(p.get("puerto") == 23 for p in d.get("puertos", [])),
        0.9,
        "Puerto 23 (Telnet) abierto — protocolo sin cifrado, riesgo crítico"
    ),
    Regla(
        "ftp_abierto",
        lambda d: any(p.get("puerto") == 21 for p in d.get("puertos", [])),
        0.7,
        "Puerto 21 (FTP) abierto — transferencia de archivos sin cifrado"
    ),
    Regla(
        "rdp_abierto",
        lambda d: any(p.get("puerto") == 3389 for p in d.get("puertos", [])),
        0.75,
        "Puerto 3389 (RDP) abierto — escritorio remoto expuesto"
    ),
    Regla(
        "smb_abierto",
        lambda d: any(p.get("puerto") == 445 for p in d.get("puertos", [])),
        0.7,
        "Puerto 445 (SMB) abierto — historial de vulnerabilidades graves (EternalBlue)"
    ),
    Regla(
        "vnc_abierto",
        lambda d: any(p.get("puerto") == 5900 for p in d.get("puertos", [])),
        0.65,
        "Puerto 5900 (VNC) abierto — acceso remoto visual potencialmente expuesto"
    ),
    Regla(
        "sin_mac",
        lambda d: d.get("mac") in (None, "", "No disponible"),
        0.5,
        "Sin dirección MAC detectable — dispositivo oculto o fuera de subred local"
    ),
    Regla(
        "fabricante_desconocido",
        lambda d: d.get("fabricante") in (None, "", "Desconocido"),
        0.3,
        "Fabricante de hardware desconocido"
    ),
    Regla(
        "muchos_puertos",
        lambda d: len(d.get("puertos", [])) > 8,
        0.4,
        f"Más de 8 puertos abiertos — superficie de ataque amplia"
    ),
    Regla(
        "mac_broadcast",
        lambda d: d.get("mac", "").upper() in ("FF:FF:FF:FF:FF:FF", "00:00:00:00:00:00"),
        0.95,
        "MAC inválida o broadcast — muy sospechoso"
    ),
    Regla(
        "sin_nombre_dns",
        lambda d: d.get("nombre") in (None, "", "Desconocido"),
        0.15,
        "Sin nombre DNS resuelto"
    ),
    Regla(
        "sql_expuesto",
        lambda d: any(p.get("puerto") in (1433, 3306, 5432) 
                     for p in d.get("puertos", [])),
        0.8,
        "Base de datos expuesta directamente en red (MSSQL/MySQL/PostgreSQL)"
    ),
]

# Reglas que REDUCEN el riesgo (dan confianza)
REGLAS_CONFIANZA = [
    Regla(
        "gateway_conocido",
        lambda d: d.get("ip", "").endswith(".1"),
        -0.3,
        "IP termina en .1 — probablemente el router/gateway"
    ),
    Regla(
        "tiene_nombre_dns",
        lambda d: bool(d.get("nombre")) and d.get("nombre") != "Desconocido",
        -0.15,
        "Nombre DNS resuelto — dispositivo registrado en la red"
    ),
    Regla(
        "fabricante_conocido",
        lambda d: bool(d.get("fabricante")) and d.get("fabricante") != "Desconocido",
        -0.2,
        "Fabricante de hardware identificado"
    ),
    Regla(
        "solo_http_https",
        lambda d: (len(d.get("puertos", [])) <= 2 and 
                   all(p.get("puerto") in (80, 443, 8080, 8443)
                       for p in d.get("puertos", []))),
        -0.25,
        "Solo puertos web estándar — perfil típico de servidor web"
    ),
]


class MotorReglas:
    """
    Evalúa todas las reglas sobre un dispositivo y devuelve un score.
    
    El score de reglas es la suma de puntuaciones,
    normalizada al rango [0, 1] por un techo configurable.
    """
    
    TECHO = 2.0  # puntaje máximo posible antes de normalizar
    
    def evaluar(self, dispositivo: dict) -> dict:
        activadas = []
        confianzas = []
        score_bruto = 0.0
        
        for regla in REGLAS:
            try:
                if regla.condicion(dispositivo):
                    activadas.append(regla)
                    score_bruto += regla.puntuacion
            except Exception:
                pass
        
        for regla in REGLAS_CONFIANZA:
            try:
                if regla.condicion(dispositivo):
                    confianzas.append(regla)
                    score_bruto += regla.puntuacion  # valores negativos
            except Exception:
                pass
        
        score_normalizado = max(0.0, min(1.0, score_bruto / self.TECHO))
        
        return {
            "score_reglas":   round(score_normalizado, 3),
            "reglas_activas": [r.nombre for r in activadas],
            "confianzas":     [r.nombre for r in confianzas],
            "explicaciones":  [r.explicacion for r in activadas],
        }


# ─────────────────────────────────────────────
#  MOTOR COMBINADO: Reglas + IA
# ─────────────────────────────────────────────

class SistemaDecision:
    """
    Combina el motor de reglas con la red neuronal profunda
    para una evaluación más robusta.
    
    PESOS DE COMBINACIÓN:
      score_final = W_reglas * score_reglas + W_neuro * score_neuronal
    
    Podés ajustar los pesos según qué tanto confiás en cada sistema.
    Al principio (poca data), conviene dar más peso a las reglas.
    Con el tiempo, a medida que la red aprende, subís W_neuro.
    """
    
    W_REGLAS = 0.40   # peso del motor de reglas
    W_NEURO  = 0.60   # peso de la red neuronal
    
    def __init__(self):
        self.motor_reglas = MotorReglas()
        self.red_profunda = RedProfunda()
        self.neuronas_simples = CerebroNeuronal()
        print("⚙️  Sistema de decisión híbrido iniciado")
    
    def evaluar(self, dispositivo: dict) -> dict:
        """
        Evaluación completa de un dispositivo.
        Combina reglas explícitas + red profunda + neuronas simples.
        """
        # Evaluación por reglas
        eval_reglas = self.motor_reglas.evaluar(dispositivo)
        
        # Evaluación neuronal (red profunda)
        eval_red = self.red_profunda.analizar(dispositivo)
        
        # Evaluación neuronal (neurona.py existente)
        eval_simple = self.neuronas_simples.analizar_dispositivo(dispositivo)
        
        # Score combinado: promedio ponderado
        score_final = (
            self.W_REGLAS * eval_reglas["score_reglas"] +
            self.W_NEURO  * eval_red["riesgo"]
        )
        score_final = round(min(1.0, score_final), 3)
        
        # Etiqueta final
        if score_final < 0.25:
            etiqueta = "🟢 BAJO"
        elif score_final < 0.50:
            etiqueta = "🟡 MEDIO"
        elif score_final < 0.75:
            etiqueta = "🟠 ALTO"
        else:
            etiqueta = "🔴 CRÍTICO"
        
        # Consolidar explicaciones de todas las fuentes
        explicaciones = eval_reglas["explicaciones"][:]
        explicaciones += eval_simple.get("explicacion", [])
        
        # Detectar consenso o divergencia entre sistemas
        dif = abs(eval_reglas["score_reglas"] - eval_red["riesgo"])
        consenso = dif < 0.25
        nota_consenso = (
            "✅ Reglas y red neuronal coinciden" if consenso
            else f"⚠️  Divergencia: reglas={eval_reglas['score_reglas']:.2f}, "
                 f"red={eval_red['riesgo']:.2f} — revisar manualmente"
        )
        
        return {
            "ip":              dispositivo.get("ip", "N/A"),
            "score_final":     score_final,
            "etiqueta":        etiqueta,
            "score_reglas":    eval_reglas["score_reglas"],
            "score_red":       eval_red["riesgo"],
            "score_simple":    eval_simple["riesgo"],
            "reglas_activas":  eval_reglas["reglas_activas"],
            "explicaciones":   list(set(explicaciones)),  # sin duplicados
            "consenso":        consenso,
            "nota_consenso":   nota_consenso,
        }
    
    def evaluar_red(self, dispositivos: list) -> list:
        resultados = [self.evaluar(d) for d in dispositivos]
        # Ordenar por score descendente (más peligrosos primero)
        return sorted(resultados, key=lambda r: r["score_final"], reverse=True)
    
    def mostrar_resultado(self, resultado: dict):
        print(f"\n  {resultado['etiqueta']}  {resultado['ip']}")
        print(f"  Score: {resultado['score_final']:.2f}  "
              f"(reglas: {resultado['score_reglas']:.2f}, "
              f"red: {resultado['score_red']:.2f})")
        if resultado["reglas_activas"]:
            for exp in resultado["explicaciones"][:3]:
                print(f"  → {exp}")
        print(f"  {resultado['nota_consenso']}")
    
    def reentrenar_con_memoria(self, memoria):
        """
        Usa los datos marcados manualmente guardados en memoria.py
        para re-entrenar la red profunda.
        
        Esto cierra el ciclo de aprendizaje:
          usuario marca intruso → se guarda en memoria → re-entrena red
        """
        from neurona import extraer_features
        ejemplos = memoria.obtener_ejemplos_entrenamiento()
        
        if not ejemplos:
            print("⚠️  No hay ejemplos de entrenamiento en memoria")
            return
        
        datos = []
        for dispositivo, accion in ejemplos:
            features = extraer_features(dispositivo)
            objetivo = 0.95 if accion == "intruso" else 0.05
            datos.append((features, objetivo))
        
        print(f"🧠 Re-entrenando red profunda con {len(datos)} ejemplos...")
        historial = self.red_profunda.entrenar_lote(datos, epocas=150)
        print(f"   Loss inicial: {historial[0]:.4f} → Loss final: {historial[-1]:.4f}")