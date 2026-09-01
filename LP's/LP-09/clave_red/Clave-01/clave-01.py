"""
==============================
CLAVE - Cerebro Artificial Modular
Arquitectura inspirada en neurociencia
==============================
"""

import numpy as np
from collections import deque
import random

# ----------------------------------------------------------
# MÓDULO 1: LA NEURONA FUNDAMENTAL DE CLAVE
# El "ciudadano" básico. Todo lo demás se construye con esto.
# ----------------------------------------------------------
class NeuronaClave:
    """
    Simplifica la neurona biológica:
    - Dendritas: Reciben señales ponderadas (entradas * pesos)
    - Soma: Suma las señales (suma ponderada + bias)
    - Axón: Aplica función de activación y transmite
    """
    def __init__(self, num_entradas, tipo_activacion='relu'):
        # "Sinapsis": Pesos que representan la fuerza de cada conexión
        self.pesos = np.random.randn(num_entradas) * np.sqrt(2.0 / num_entradas)
        self.bias = 0.0
        self.tipo_activacion = tipo_activacion
        
        # Para plasticidad (aprendizaje)
        self.grad_pesos = np.zeros_like(self.pesos)
        self.grad_bias = 0.0
        
    def activar(self, entrada):
        """El potencial de acción: suma ponderada -> activación"""
        self.entrada = entrada
        self.suma_ponderada = np.dot(entrada, self.pesos) + self.bias
        
        if self.tipo_activacion == 'relu':
            self.salida = max(0, self.suma_ponderada)
        elif self.tipo_activacion == 'sigmoide':
            self.salida = 1.0 / (1.0 + np.exp(-self.suma_ponderada))
        
        return self.salida


# ----------------------------------------------------------
# MÓDULO 2: CAPA DE NEURONAS (Columna Cortical Simplificada)
# Un "minicolumna" como las de la corteza cerebral.
# ----------------------------------------------------------
class CapaCortical:
    """Una capa de neuronas que opera como una unidad de procesamiento"""
    def __init__(self, num_entradas, num_neuronas, tipo='oculta'):
        self.neuronas = [NeuronaClave(num_entradas) for _ in range(num_neuronas)]
        self.tipo = tipo
        self.salida = np.zeros(num_neuronas)
        
    def forward(self, entrada):
        """Propagación hacia adelante por toda la capa"""
        self.salida = np.array([neurona.activar(entrada) for neurona in self.neuronas])
        return self.salida
    
    def actualizar_pesos(self, tasa_aprendizaje):
        """Plasticidad: ajusta los pesos según el error calculado"""
        for neurona in self.neuronas:
            neurona.pesos -= tasa_aprendizaje * neurona.grad_pesos
            neurona.bias -= tasa_aprendizaje * neurona.grad_bias


# ----------------------------------------------------------
# MÓDULO 3: LÓBULO OCCIPITAL (VISIÓN SIMPLIFICADA)
# No procesa píxeles, sino "características visuales" pre-extraídas
# ----------------------------------------------------------
class LobuloOccipital:
    """
    Simula la corteza visual jerárquica:
    V1 -> V2 -> V4 -> IT (reconocimiento de objetos)
    Simplificado a 3 capas que extraen características progresivamente.
    """
    def __init__(self, dim_entrada=100, dim_salida=32):
        # V1-V2: Detectores de bordes y formas simples
        self.capa_v1 = CapaCortical(dim_entrada, 64, 'visual_temprana')
        # V4: Formas complejas y color
        self.capa_v4 = CapaCortical(64, 48, 'visual_media')
        # IT: Reconocimiento de objetos (representación compacta)
        self.capa_it = CapaCortical(48, dim_salida, 'visual_superior')
        
        # Memoria de patrones visuales conocidos
        self.memoria_visual = {}
        
    def ver(self, estimulo_visual):
        """
        Procesa un estímulo visual a través de la jerarquía.
        entrada: vector de características visuales (ej. de una CNN pre-entrenada)
        salida: representación abstracta del objeto
        """
        # Jerarquía visual
        v1_out = self.capa_v1.forward(estimulo_visual)
        v4_out = self.capa_v4.forward(v1_out)
        percepcion_visual = self.capa_it.forward(v4_out)
        
        return percepcion_visual
    
    def reconocer_objeto(self, estimulo_visual, umbral=0.8):
        """Reconoce si el objeto es conocido (como la corteza inferotemporal)"""
        percepcion = self.ver(estimulo_visual)
        
        for nombre_objeto, representacion in self.memoria_visual.items():
            similitud = self._calcular_similitud(percepcion, representacion)
            if similitud > umbral:
                return nombre_objeto, similitud
        
        return "desconocido", 0.0
    
    def aprender_objeto(self, nombre, estimulo_visual):
        """Memoriza un nuevo objeto (plasticidad en IT)"""
        representacion = self.ver(estimulo_visual)
        self.memoria_visual[nombre] = representacion
        print(f"[Occipital] He aprendido a reconocer: {nombre}")
    
    def _calcular_similitud(self, vec1, vec2):
        """Similitud coseno como medida de reconocimiento"""
        return np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2) + 1e-8)


# ----------------------------------------------------------
# MÓDULO 4: LÓBULO TEMPORAL (AUDICIÓN Y LENGUAJE)
# Procesamiento de secuencias y comprensión semántica
# ----------------------------------------------------------
class LobuloTemporal:
    """
    Simula el procesamiento auditivo y del lenguaje:
    - Corteza auditiva: Procesa sonidos
    - Área de Wernicke: Comprensión del lenguaje
    """
    def __init__(self, dim_entrada=50, dim_salida=32):
        # Corteza auditiva primaria
        self.capa_auditiva = CapaCortical(dim_entrada, 48, 'auditiva')
        # Área de Wernicke: significado semántico
        self.area_wernicke = CapaCortical(48, dim_salida, 'semantica')
        
        # Memoria semántica: conceptos y sus relaciones
        self.red_semantica = {}
        self.memoria_secuencial = deque(maxlen=10)  # Memoria ecoica a corto plazo
        
    def escuchar(self, entrada_auditiva):
        """
        Procesa entrada auditiva (ya pre-procesada a características)
        retorna: representación semántica
        """
        # Procesamiento auditivo
        activacion_auditiva = self.capa_auditiva.forward(entrada_auditiva)
        # Comprensión semántica
        significado = self.area_wernicke.forward(activacion_auditiva)
        
        # Guardar en memoria ecoica (a corto plazo)
        self.memoria_secuencial.append(significado)
        
        return significado
    
    def comprender_contexto_temporal(self):
        """
        Integra las últimas entradas para entender el contexto.
        Como el área de Wernicke procesando una frase completa.
        """
        if len(self.memoria_secuencial) < 2:
            return self.memoria_secuencial[-1] if self.memoria_secuencial else np.zeros(32)
        
        # Promedio ponderado: más peso a lo reciente
        contexto = np.zeros(32)
        for i, mem in enumerate(self.memoria_secuencial):
            peso = (i + 1) / len(self.memoria_secuencial)
            contexto += mem * peso
        
        return contexto / len(self.memoria_secuencial)
    
    def asociar_concepto(self, palabra, significado_vector):
        """Aprendizaje semántico: asocia palabra con representación"""
        self.red_semantica[palabra] = significado_vector
        print(f"[Temporal] Concepto '{palabra}' integrado en la red semántica")


# ----------------------------------------------------------
# MÓDULO 5: AMÍGDALA (SISTEMA EMOCIONAL Y DE ALERTA)
# Evaluación rápida de relevancia emocional
# ----------------------------------------------------------
class Amigdala:
    """
    Sistema de evaluación emocional rápida:
    - Vía rápida (tálamo->amígdala): Respuesta inmediata
    - Vía lenta (tálamo->corteza->amígdala): Evaluación refinada
    """
    def __init__(self, dim_entrada=32):
        # Evaluador rápido (poco preciso, pero veloz)
        self.evaluador_rapido = CapaCortical(dim_entrada, 8, 'emocional_rapida')
        self.capa_valencia = CapaCortical(8, 1, 'valencia')
        
        # Memoria emocional: eventos con carga emocional
        self.memoria_emocional = []
        self.estado_actual = {
            'valencia': 0.0,      # -1 (miedo/desagrado) a +1 (placer)
            'activacion': 0.0,    # 0 (calma) a 1 (alerta máxima)
            'dominancia': 0.5     # 0 (sin control) a 1 (control total)
        }
        
    def evaluar_situacion(self, estimulo):
        """
        Evalúa la carga emocional de un estímulo.
        Como la amígdala basolateral evaluando una situación.
        """
        # Vía rápida: evaluación inmediata
        respuesta_rapida = self.evaluador_rapido.forward(estimulo)
        valencia_cruda = self.capa_valencia.forward(respuesta_rapida)[0]
        
        # Normalizar entre -1 y 1
        valencia = np.tanh(valencia_cruda)
        
        # Actualizar estado emocional
        self.estado_actual['valencia'] = valencia
        self.estado_actual['activacion'] = abs(valencia)  # Intensidad = valor absoluto
        
        # Si es muy intenso, guardar en memoria emocional
        if abs(valencia) > 0.6:
            self._marcar_como_significativo(estimulo, valencia)
        
        return valencia
    
    def _marcar_como_significativo(self, estimulo, valencia):
        """Consolidación de memoria emocional"""
        self.memoria_emocional.append({
            'estimulo': estimulo.copy(),
            'valencia': valencia,
            'intensidad': abs(valencia)
        })
        # Mantener solo los últimos 20 recuerdos emocionales
        if len(self.memoria_emocional) > 20:
            self.memoria_emocional.pop(0)
    
    def consultar_estado(self):
        """Retorna el estado emocional actual"""
        return self.estado_actual
    
    def recordar_evento_similar(self, estimulo, umbral=0.7):
        """Busca en la memoria emocional eventos parecidos"""
        for recuerdo in self.memoria_emocional:
            similitud = np.dot(estimulo, recuerdo['estimulo']) / (
                np.linalg.norm(estimulo) * np.linalg.norm(recuerdo['estimulo']) + 1e-8
            )
            if similitud > umbral:
                return recuerdo
        return None


# ----------------------------------------------------------
# MÓDULO 6: HIPOCAMPO (SISTEMA DE MEMORIA EPISÓDICA)
# Formación y recuperación de recuerdos
# ----------------------------------------------------------
class Hipocampo:
    """
    Simula el sistema de memoria del hipocampo:
    - Codificación: Convierte experiencias en "huellas de memoria"
    - Consolidación: Fortalece recuerdos importantes
    - Recuperación: Recuerda por similitud contextual
    """
    def __init__(self, dim_representacion=32):
        self.dim_representacion = dim_representacion
        self.memoria_episodica = []  # Almacén de episodios
        self.memoria_trabajo = deque(maxlen=7)  # Mágico número 7±2 de Miller
        self.indice_consolidacion = 0
        
    def codificar_episodio(self, contexto, emocion, accion, resultado):
        """
        Codifica una experiencia completa.
        Como el giro dentado creando una nueva representación.
        """
        episodio = {
            'id': self.indice_consolidacion,
            'contexto': contexto.copy(),      # Dónde y qué
            'emocion': emocion,               # Cómo me sentí
            'accion': accion,                 # Qué hice
            'resultado': resultado,           # Qué pasó después
            'fuerza': abs(emocion) * 0.5,     # La emoción modula la fuerza
            'accesos': 1,                     # Cada recuerdo fortalece el recuerdo
            'timestamp': self.indice_consolidacion
        }
        
        self.memoria_episodica.append(episodio)
        self.indice_consolidacion += 1
        
        # Consolidación: mantener un límite práctico
        if len(self.memoria_episodica) > 100:
            self._consolidar_memorias()
        
        print(f"[Hipocampo] Episodio #{episodio['id']} codificado (fuerza: {episodio['fuerza']:.2f})")
        return episodio['id']
    
    def recuperar_por_contexto(self, contexto_actual, k=3):
        """
        Recupera los k recuerdos más similares al contexto actual.
        Como la recuperación por patrones de finalización en CA3.
        """
        if not self.memoria_episodica:
            return []
        
        similitudes = []
        for episodio in self.memoria_episodica:
            sim = np.dot(contexto_actual, episodio['contexto']) / (
                np.linalg.norm(contexto_actual) * np.linalg.norm(episodio['contexto']) + 1e-8
            )
            # Ponderar por fuerza del recuerdo
            puntuacion = sim * episodio['fuerza']
            similitudes.append((puntuacion, episodio))
        
        # Ordenar y retornar los k mejores
        similitudes.sort(key=lambda x: x[0], reverse=True)
        recuperados = [ep for _, ep in similitudes[:k]]
        
        # Fortalecer recuerdos accedidos (reconsolidación)
        for ep in recuperados:
            ep['fuerza'] *= 1.1
            ep['accesos'] += 1
        
        return recuperados
    
    def _consolidar_memorias(self):
        """
        Elimina recuerdos débiles, fortalece los importantes.
        Como la consolidación durante el sueño.
        """
        # Ordenar por fuerza * accesos
        self.memoria_episodica.sort(
            key=lambda ep: ep['fuerza'] * (1 + 0.1 * ep['accesos']), 
            reverse=True
        )
        # Mantener solo los más fuertes (los 50 principales)
        self.memoria_episodica = self.memoria_episodica[:50]
        print("[Hipocampo] Consolidación completada: memorias débiles eliminadas")


# ----------------------------------------------------------
# MÓDULO 7: CORTEZA PREFRONTAL (FUNCIONES EJECUTIVAS)
# El "Director General" de Clave
# ----------------------------------------------------------
class CortezaPrefrontal:
    """
    Simula las funciones ejecutivas:
    - Memoria de trabajo
    - Planificación
    - Control inhibitorio
    - Toma de decisiones
    """
    def __init__(self, dim_entrada=96):  # 32*3 (visual + semántico + emocional)
        self.dim_entrada = dim_entrada
        self.memoria_trabajo = deque(maxlen=7)
        self.objetivos_activos = []
        self.plan_actual = None
        
        # Red de decisión: evalúa opciones y elige acciones
        self.capa_evaluacion = CapaCortical(dim_entrada, 64, 'prefrontal_eval')
        self.capa_decision = CapaCortical(64, 8, 'prefrontal_dec')
        
        # Sistema de recompensa y error
        self.historial_decisiones = []
        
    def integrar_informacion(self, percepcion_visual, comprension_semantica, estado_emocional):
        """
        Integra toda la información como la corteza prefrontal.
        Esta es la "conciencia de trabajo" de Clave.
        """
        # Concatenar toda la información sensorial y emocional
        informacion_integrada = np.concatenate([
            percepcion_visual,
            comprension_semantica,
            np.array([estado_emocional['valencia'], 
                      estado_emocional['activacion'],
                      estado_emocional['dominancia']])
        ])
        
        # Ajustar tamaño si es necesario
        if len(informacion_integrada) < self.dim_entrada:
            informacion_integrada = np.pad(informacion_integrada, 
                                          (0, self.dim_entrada - len(informacion_integrada)))
        
        self.memoria_trabajo.append(informacion_integrada)
        return informacion_integrada
    
    def evaluar_opciones(self, opciones, contexto_integrado):
        """
        Evalúa diferentes cursos de acción posibles.
        Como la corteza orbitofrontal evaluando recompensas.
        """
        evaluaciones = []
        for opcion in opciones:
            # Combinar contexto con opción
            entrada_eval = np.concatenate([contexto_integrado[:64], opcion[:32]])
            if len(entrada_eval) < self.dim_entrada:
                entrada_eval = np.pad(entrada_eval, (0, self.dim_entrada - len(entrada_eval)))
            
            valor = self.capa_evaluacion.forward(entrada_eval[:self.dim_entrada])
            valor_final = self.capa_decision.forward(valor)
            evaluaciones.append(np.mean(valor_final))
        
        return evaluaciones
    
    def tomar_decision(self, opciones, contexto_integrado):
        """
        Elige la mejor acción basada en evaluación y estado actual.
        """
        if not opciones:
            return None, 0.0
        
        evaluaciones = self.evaluar_opciones(opciones, contexto_integrado)
        mejor_idx = np.argmax(evaluaciones)
        
        decision = {
            'opcion_elegida': mejor_idx,
            'confianza': evaluaciones[mejor_idx],
            'alternativas': evaluaciones,
            'contexto': contexto_integrado.copy()
        }
        
        self.historial_decisiones.append(decision)
        print(f"[Prefrontal] Decisión tomada: Opción {mejor_idx} (confianza: {evaluaciones[mejor_idx]:.2f})")
        
        return mejor_idx, evaluaciones[mejor_idx]
    
    def establecer_objetivo(self, objetivo):
        """Mantiene un objetivo en mente (como la corteza prefrontal dorsolateral)"""
        self.objetivos_activos.append(objetivo)
        print(f"[Prefrontal] Nuevo objetivo establecido: {objetivo}")
    
    def inhibir_respuesta(self, respuesta_automatica, contexto):
        """
        Control inhibitorio: frena respuestas inapropiadas.
        Como la corteza prefrontal ventromedial.
        """
        # Si hay conflicto entre respuesta automática y objetivos
        if self.objetivos_activos and self._conflicto_con_objetivos(respuesta_automatica):
            print("[Prefrontal] Respuesta inhibida por conflicto con objetivos")
            return True
        return False
    
    def _conflicto_con_objetivos(self, respuesta):
        """Verifica si una respuesta contradice los objetivos activos"""
        # Simplificado: en una implementación real, esto sería más sofisticado
        return random.random() < 0.3  # Probabilístico para demostración


# ----------------------------------------------------------
# MÓDULO 8: CEREBELO (COORDINACIÓN Y REFINAMIENTO)
# Aprendizaje motor y ajuste fino de acciones
# ----------------------------------------------------------
class Cerebelo:
    """
    Simula el cerebelo como refinador de acciones:
    - No inicia acciones, las pule
    - Aprendizaje supervisado de errores motores
    """
    def __init__(self, dim_accion=10):
        self.dim_accion = dim_accion
        self.modelo_interno = CapaCortical(dim_accion * 2, dim_accion, 'cerebelo')
        self.error_acumulado = 0
        
    def refinar_accion(self, accion_bruta, contexto_motor):
        """
        Refina una acción motora.
        Como el cerebelo ajustando movimientos basado en experiencia.
        """
        entrada = np.concatenate([accion_bruta, contexto_motor])
        if len(entrada) < 20:
            entrada = np.pad(entrada, (0, 20 - len(entrada)))
        
        correccion = self.modelo_interno.forward(entrada[:20])
        accion_refinada = accion_bruta + 0.1 * correccion
        
        return accion_refinada
    
    def aprender_de_error(self, accion_prevista, resultado_real):
        """
        Aprendizaje por error: como las fibras trepadoras
        señalando errores de predicción.
        """
        error = resultado_real - accion_prevista
        self.error_acumulado += np.mean(np.abs(error))
        print(f"[Cerebelo] Error detectado: {np.mean(np.abs(error)):.3f}")


# ----------------------------------------------------------
# MÓDULO 9: TRONCO ENCEFÁLICO Y HOMEOSTASIS
# Regulación automática vital
# ----------------------------------------------------------
class TroncoEncefalico:
    """
    Sistema homeostático que mantiene el equilibrio interno.
    Como el hipotálamo y tronco encefálico.
    """
    def __init__(self):
        self.necesidades = {
            'energia': 1.0,      # 0 = agotado, 1 = lleno
            'seguridad': 1.0,    # 0 = amenaza, 1 = seguro
            'curiosidad': 0.5,   # Deseo de explorar
            'descanso': 1.0      # 0 = agotado, 1 = descansado
        }
        self.tasa_decaimiento = {
            'energia': 0.02,
            'seguridad': 0.01,
            'curiosidad': 0.005,
            'descanso': 0.015
        }
    
    def actualizar_homeostasis(self):
        """Actualiza las necesidades internas con el tiempo"""
        for necesidad in self.necesidades:
            self.necesidades[necesidad] -= self.tasa_decaimiento[necesidad]
            self.necesidades[necesidad] = max(0, self.necesidades[necesidad])
    
    def generar_impulso(self):
        """
        Genera impulsos básicos basados en necesidades.
        Como el hipotálamo generando señales de hambre/sed.
        """
        impulsos = {}
        if self.necesidades['energia'] < 0.3:
            impulsos['buscar_recurso'] = 1 - self.necesidades['energia']
        if self.necesidades['seguridad'] < 0.3:
            impulsos['buscar_seguridad'] = 1 - self.necesidades['seguridad']
        if self.necesidades['curiosidad'] > 0.6:
            impulsos['explorar'] = self.necesidades['curiosidad']
        if self.necesidades['descanso'] < 0.2:
            impulsos['descansar'] = 1 - self.necesidades['descanso']
        
        return impulsos
    
    def satisfacer_necesidad(self, necesidad, cantidad=0.5):
        """Satisface una necesidad específica"""
        if necesidad in self.necesidades:
            self.necesidades[necesidad] += cantidad
            self.necesidades[necesidad] = min(1.0, self.necesidades[necesidad])
            print(f"[TroncoEncefalico] Necesidad '{necesidad}' satisfecha (+{cantidad})")


# ----------------------------------------------------------
# MÓDULO 10: SISTEMA DE ATENCIÓN (SARA)
# Sistema Activador Reticular Ascendente
# ----------------------------------------------------------
class SistemaAtencion:
    """
    Controla el foco atencional y el estado de alerta.
    """
    def __init__(self, dim_entrada=96):
        self.foco_actual = None
        self.nivel_alerta = 0.5  # 0=dormido, 1=hiperalerta
        self.filtro_atencional = CapaCortical(dim_entrada, dim_entrada, 'atencion')
        
    def enfocar_atencion(self, informacion_entrada, prioridades):
        """
        Filtra la información según relevancia.
        Como el SARA filtrando estímulos irrelevantes.
        """
        # Combinar información con prioridades
        entrada_filtrada = self.filtro_atencional.forward(informacion_entrada)
        
        # Si hay prioridad de seguridad, aumentar alerta
        if prioridades and 'seguridad' in prioridades:
            self.nivel_alerta = min(1.0, self.nivel_alerta + 0.1)
        
        return entrada_filtrada * self.nivel_alerta


# ==========================================================
# "CLAVE" - EL CEREBRO COMPLETO INTEGRADO
# Aquí todas las partes trabajan juntas
# ==========================================================
class Clave:
    """
    Arquitectura completa de cerebro artificial.
    Inspirada en la organización funcional del cerebro humano.
    """
    def __init__(self, nombre="Clave"):
        self.nombre = nombre
        self.edad_mental = 0  # Ciclos de experiencia
        
        # Todos los módulos trabajando en conjunto
        self.occipital = LobuloOccipital(dim_entrada=100, dim_salida=32)
        self.temporal = LobuloTemporal(dim_entrada=50, dim_salida=32)
        self.amigdala = Amigdala(dim_entrada=32)
        self.hipocampo = Hipocampo(dim_representacion=32)
        self.prefrontal = CortezaPrefrontal(dim_entrada=96)
        self.cerebelo = Cerebelo(dim_accion=10)
        self.tronco = TroncoEncefalico()
        self.atencion = SistemaAtencion(dim_entrada=96)
        
        # Estado de conciencia (simplificado)
        self.consciente = True
        self.memoria_procedimental = {}  # Hábitos y habilidades
        
        print(f"""
        ╔══════════════════════════════════════╗
        ║     {self.nombre} - Cerebro Artificial    ║
        ║     Inspirado en neurociencia        ║
        ╚══════════════════════════════════════╝
        """)
    
    def percibir_mundo(self, estimulo_visual, estimulo_auditivo=None):
        """
        Percibe el mundo a través de los sentidos.
        Entrada principal de información a Clave.
        """
        # Procesamiento paralelo (como en el cerebro real)
        percepcion_visual = self.occipital.ver(estimulo_visual)
        
        if estimulo_auditivo is not None:
            comprension_semantica = self.temporal.escuchar(estimulo_auditivo)
        else:
            comprension_semantica = np.zeros(32)
        
        return percepcion_visual, comprension_semantica
    
    def sentir(self, estimulo_interno=None):
        """
        Genera el estado emocional basado en estímulos.
        """
        # Evaluación emocional de la situación
        if estimulo_interno is None:
            estimulo_interno = np.random.randn(32) * 0.1
        
        valencia = self.amigdala.evaluar_situacion(estimulo_interno)
        estado = self.amigdala.consultar_estado()
        
        return estado, valencia
    
    def pensar(self, percepcion_visual, comprension_semantica, estado_emocional):
        """
        Integra información y toma decisiones.
        Este es el "espacio de trabajo global" de Clave.
        """
        # Integración multimodal (como la corteza prefrontal)
        contexto_integrado = self.prefrontal.integrar_informacion(
            percepcion_visual, comprension_semantica, estado_emocional
        )
        
        # Recuperar memorias relevantes para informar la decisión
        recuerdos = self.hipocampo.recuperar_por_contexto(contexto_integrado[:32])
        
        # Generar opciones de acción basadas en necesidades y recuerdos
        impulsos = self.tronco.generar_impulso()
        opciones = self._generar_opciones(impulsos, recuerdos, estado_emocional)
        
        # Tomar decisión
        accion_idx, confianza = self.prefrontal.tomar_decision(opciones, contexto_integrado)
        
        return accion_idx, confianza, recuerdos, contexto_integrado
    
    def actuar(self, accion_idx, contexto):
        """
        Ejecuta una acción refinada por el cerebelo.
        """
        # Acción base
        accion_base = np.zeros(10)
        accion_base[accion_idx] = 1.0
        
        # El cerebelo refina la acción
        contexto_motor = contexto[:10] if len(contexto) >= 10 else np.pad(contexto, (0, 10-len(contexto)))
        accion_refinada = self.cerebelo.refinar_accion(accion_base, contexto_motor)
        
        # Verificar si debemos inhibir la acción (control prefrontal)
        if self.prefrontal.inhibir_respuesta(accion_refinada, contexto):
            print(f"[{self.nombre}] Acción inhibida por control ejecutivo")
            return None
        
        return accion_refinada
    
    def aprender_experiencia(self, percepcion, emocion, accion, resultado):
        """
        Aprende de la experiencia (ciclo completo de aprendizaje).
        """
        # 1. Codificar en memoria episódica (hipocampo)
        self.hipocampo.codificar_episodio(percepcion, emocion, accion, resultado)
        
        # 2. Si hay error, el cerebelo aprende
        if resultado < 0.5:
            self.cerebelo.aprender_de_error(accion, resultado)
        
        # 3. Actualizar homeostasis
        self.tronco.actualizar_homeostasis()
        
        self.edad_mental += 1
    
    def _generar_opciones(self, impulsos, recuerdos, estado_emocional):
        """Genera posibles acciones basadas en estado interno y memorias"""
        opciones = []
        
        # Opciones basadas en impulsos
        for impulso, intensidad in impulsos.items():
            opcion = np.random.randn(96) * intensidad
            opciones.append(opcion)
        
        # Si no hay impulsos, generar opciones por defecto
        if not opciones:
            opciones = [np.random.randn(96) for _ in range(3)]
        
        return opciones
    
    def ciclo_completo(self, estimulo_visual, estimulo_auditivo=None):
        """
        Un ciclo completo de percepción-pensamiento-acción de Clave.
        """
        print(f"\n{'='*50}")
        print(f"[{self.nombre}] Ciclo mental #{self.edad_mental + 1}")
        print(f"{'='*50}")
        
        # 1. PERCIBIR
        print("\n[1] PERCIBIENDO...")
        vis, sem = self.percibir_mundo(estimulo_visual, estimulo_auditivo)
        print(f"    Visión procesada: {vis[:4]}...")
        
        # 2. SENTIR
        print("\n[2] SINTIENDO...")
        estado_emocional, valencia = self.sentir()
        print(f"    Estado emocional: valencia={estado_emocional['valencia']:.2f}, "
              f"activación={estado_emocional['activacion']:.2f}")
        
        # 3. PENSAR Y DECIDIR
        print("\n[3] PENSANDO...")
        accion_idx, confianza, recuerdos, contexto = self.pensar(vis, sem, estado_emocional)
        print(f"    Recuerdos recuperados: {len(recuerdos)}")
        
        # 4. ACTUAR
        print("\n[4] ACTUANDO...")
        accion = self.actuar(accion_idx, contexto)
        if accion is not None:
            print(f"    Acción ejecutada: {accion_idx} (confianza: {confianza:.2f})")
        
        # 5. APRENDER (simulando un resultado)
        print("\n[5] APRENDIENDO...")
        resultado_simulado = random.uniform(0.3, 0.9)
        self.aprender_experiencia(vis[:32], valencia, accion_idx, resultado_simulado)
        
        return {
            'percepcion': vis,
            'emocion': estado_emocional,
            'decision': accion_idx,
            'confianza': confianza,
            'resultado': resultado_simulado
        }
    
    def reporte_estado(self):
        """Genera un reporte del estado interno de Clave"""
        print(f"""
        ╔══════════════════════════════════════╗
        ║     ESTADO INTERNO DE {self.nombre}      ║
        ╠══════════════════════════════════════╣
        ║ Edad mental: {self.edad_mental} ciclos          ║
        ║ Memorias episódicas: {len(self.hipocampo.memoria_episodica)}          ║
        ║ Objetos reconocidos: {len(self.occipital.memoria_visual)}         ║
        ║ Conceptos semánticos: {len(self.temporal.red_semantica)}        ║
        ╠══════════════════════════════════════╣
        ║ Necesidades:                        ║
        ║   Energía: {self.tronco.necesidades['energia']:.2f}                     ║
        ║   Seguridad: {self.tronco.necesidades['seguridad']:.2f}                    ║
        ║   Curiosidad: {self.tronco.necesidades['curiosidad']:.2f}                   ║
        ║   Descanso: {self.tronco.necesidades['descanso']:.2f}                    ║
        ╚══════════════════════════════════════╝
        """)


# ==========================================================
# DEMOSTRACIÓN: CLAVE EN ACCIÓN
# ==========================================================
if __name__ == "__main__":
    # Crear a Clave
    clave = Clave(nombre="Clave v1.0")
    
    # Enseñarle a reconocer objetos (aprendizaje visual)
    print("\n[ENTRENAMIENTO] Enseñando a Clave a reconocer objetos...")
    for _ in range(5):
        objeto_aleatorio = np.random.randn(100)
        clave.occipital.aprender_objeto(f"objeto_{_}", objeto_aleatorio)
    
    # Enseñarle conceptos semánticos
    print("\n[ENTRENAMIENTO] Enseñando conceptos semánticos...")
    conceptos = ['peligro', 'seguro', 'interesante', 'aburrido']
    for concepto in conceptos:
        clave.temporal.asociar_concepto(concepto, np.random.randn(32))
    
    # Ejecutar varios ciclos de Clave
    print("\n" + "="*60)
    print("CLAVE EN FUNCIONAMIENTO")
    print("="*60)
    
    for ciclo in range(3):
        # Estímulos aleatorios simulados
        estimulo_visual = np.random.randn(100)
        estimulo_auditivo = np.random.randn(50)
        
        resultado = clave.ciclo_completo(estimulo_visual, estimulo_auditivo)
        
        # Mostrar estado cada 2 ciclos
        if ciclo % 2 == 0:
            clave.reporte_estado()
    
    print(f"\n[FIN] Clave ha completado {clave.edad_mental} ciclos de experiencia.")
    print("Arquitectura neuronal funcionando de forma integrada.")