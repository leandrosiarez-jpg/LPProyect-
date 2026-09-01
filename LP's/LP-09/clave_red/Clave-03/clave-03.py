"""
==================================================================
CLAVE v3.0 - Cerebro Artificial con Razonamiento
==================================================================
Añade a CLAVE v2.0:
  - Base de conocimiento explícita (hechos, definiciones, reglas)
  - Motor de razonamiento (deducción, causalidad, planificación)
  - Detección de enseñanzas y preguntas de razonamiento
==================================================================
"""

import numpy as np
import json
import os
import pickle
import time
import random
import threading
from datetime import datetime
from collections import deque
from pathlib import Path


# ==================================================================
# CONFIGURACIÓN GLOBAL
# ==================================================================
class ConfiguracionClave:
    """Parámetros globales que definen la personalidad y capacidades de Clave"""
    def __init__(self):
        self.directorio_memoria = "clave_memoria"
        self.archivo_estado = "clave_estado.pkl"
        self.intervalo_guardado = 60
        self.capacidad_max_memorias = 500
        self.tasa_aprendizaje_base = 0.01
        self.temperatura_decision = 0.3
        self.nivel_curiosidad_base = 0.4
        self.ciclos_por_segundo = 2


# ==================================================================
# MÓDULO 1: NEURONA UNIFICADA
# ==================================================================
class NeuronaClave:
    """
    Neurona con metaplasticidad:
    - Dendritas: reciben señales ponderadas
    - Soma: suma ponderada + bias
    - Axón: función de activación
    - Fatiga: reduce plasticidad con el uso
    """
    def __init__(self, num_entradas, tipo_activacion='relu', id_neurona=None):
        self.id = id_neurona or id(self)
        self.pesos = np.random.randn(num_entradas) * np.sqrt(2.0 / num_entradas)
        self.bias = 0.0
        self.tipo_activacion = tipo_activacion
        self.grad_pesos = np.zeros_like(self.pesos)
        self.grad_bias = 0.0
        self.historia_activacion = deque(maxlen=50)
        self.umbral_plasticidad = 0.5
        self.fatiga = 0.0

    def activar(self, entrada):
        self.entrada = entrada
        self.ultima_entrada = entrada
        self.suma_ponderada = np.dot(entrada, self.pesos) + self.bias

        if self.tipo_activacion == 'relu':
            self.salida = max(0, self.suma_ponderada)
        elif self.tipo_activacion == 'leaky_relu':
            self.salida = max(0.01 * self.suma_ponderada, self.suma_ponderada)
        elif self.tipo_activacion == 'sigmoide':
            self.salida = 1.0 / (1.0 + np.exp(-self.suma_ponderada))
        else:
            self.salida = self.suma_ponderada

        self.historia_activacion.append(self.salida)
        self.fatiga *= 0.995
        return self.salida

    def adaptar(self, gradiente, tasa_aprendizaje):
        if self.fatiga < 0.9:
            factor_plasticidad = tasa_aprendizaje * (1 - self.fatiga)
            self.pesos -= factor_plasticidad * gradiente * self.ultima_entrada
            self.bias -= factor_plasticidad * gradiente
            self.fatiga += 0.001


# ==================================================================
# MÓDULO 2: CAPA CORTICAL UNIFICADA
# ==================================================================
class CapaCortical:
    """Capa de neuronas con capacidad de neurogénesis"""
    def __init__(self, num_entradas, num_neuronas, tipo='oculta', nombre=None):
        self.nombre = nombre or tipo
        self.num_entradas = num_entradas
        self.tipo = tipo
        self.neuronas = [
            NeuronaClave(num_entradas, id_neurona=f"{self.nombre}_n{i}")
            for i in range(num_neuronas)
        ]
        self.salida = np.zeros(num_neuronas)
        self.neuronas_inactivas = deque(maxlen=20)
        self.total_creadas = num_neuronas

    def forward(self, entrada):
        self.ultima_entrada = entrada
        self.salida = np.array([neurona.activar(entrada) for neurona in self.neuronas])
        return self.salida

    def actualizar_pesos(self, tasa_aprendizaje):
        for neurona in self.neuronas:
            neurona.pesos -= tasa_aprendizaje * neurona.grad_pesos
            neurona.bias -= tasa_aprendizaje * neurona.grad_bias

    def crear_neurona(self):
        nueva = NeuronaClave(self.num_entradas, id_neurona=f"{self.nombre}_n{self.total_creadas}")
        self.neuronas.append(nueva)
        self.total_creadas += 1
        return nueva


# ==================================================================
# MÓDULO 3: LÓBULO OCCIPITAL (VISIÓN SIMPLIFICADA)
# ==================================================================
class LobuloOccipital:
    """Corteza visual jerárquica: V1 -> V2 -> V4 -> IT"""
    def __init__(self, dim_entrada=100, dim_salida=32):
        self.capa_v1 = CapaCortical(dim_entrada, 64, 'visual_temprana')
        self.capa_v4 = CapaCortical(64, 48, 'visual_media')
        self.capa_it = CapaCortical(48, dim_salida, 'visual_superior')
        self.memoria_visual = {}

    def ver(self, estimulo_visual):
        v1_out = self.capa_v1.forward(estimulo_visual)
        v4_out = self.capa_v4.forward(v1_out)
        return self.capa_it.forward(v4_out)

    def reconocer_objeto(self, estimulo_visual, umbral=0.8):
        percepcion = self.ver(estimulo_visual)
        for nombre_objeto, representacion in self.memoria_visual.items():
            similitud = self._calcular_similitud(percepcion, representacion)
            if similitud > umbral:
                return nombre_objeto, similitud
        return "desconocido", 0.0

    def aprender_objeto(self, nombre, estimulo_visual):
        representacion = self.ver(estimulo_visual)
        self.memoria_visual[nombre] = representacion
        print(f"[Occipital] He aprendido a reconocer: {nombre}")

    def _calcular_similitud(self, vec1, vec2):
        return np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2) + 1e-8)


# ==================================================================
# MÓDULO 4: LÓBULO TEMPORAL
# ==================================================================
class LobuloTemporal:
    """Procesamiento auditivo y comprensión semántica"""
    def __init__(self, dim_entrada=50, dim_salida=32):
        self.capa_auditiva = CapaCortical(dim_entrada, 48, 'auditiva')
        self.area_wernicke = CapaCortical(48, dim_salida, 'semantica')
        self.red_semantica = {}
        self.memoria_secuencial = deque(maxlen=10)

    def escuchar(self, entrada_auditiva):
        activacion_auditiva = self.capa_auditiva.forward(entrada_auditiva)
        significado = self.area_wernicke.forward(activacion_auditiva)
        self.memoria_secuencial.append(significado)
        return significado

    def comprender_contexto_temporal(self):
        if len(self.memoria_secuencial) < 2:
            return self.memoria_secuencial[-1] if self.memoria_secuencial else np.zeros(32)
        contexto = np.zeros(32)
        for i, mem in enumerate(self.memoria_secuencial):
            peso = (i + 1) / len(self.memoria_secuencial)
            contexto += mem * peso
        return contexto / len(self.memoria_secuencial)

    def asociar_concepto(self, palabra, significado_vector):
        self.red_semantica[palabra] = significado_vector
        print(f"[Temporal] Concepto '{palabra}' integrado en la red semántica")


# ==================================================================
# MÓDULO 5: SISTEMA EMOCIONAL UNIFICADO
# ==================================================================
class SistemaEmocional:
    """Amígdala + modelo circumplejo + personalidad"""
    def __init__(self, dim_entrada=32):
        self.evaluador_rapido = CapaCortical(dim_entrada, 8, 'emocional_rapida')
        self.capa_valencia = CapaCortical(8, 1, 'valencia')
        self.memoria_emocional = []
        self.estado = {
            'valencia': 0.0,
            'activacion': 0.3,
            'dominancia': 0.5
        }
        self.estado_actual = self.estado
        self.historia_emocional = deque(maxlen=100)
        self.personalidad = {
            'neuroticismo': 0.4,
            'extraversion': 0.6,
            'apertura': 0.7,
            'amabilidad': 0.5,
            'responsabilidad': 0.6
        }
        self.umbral_emocional = 0.3

    def evaluar_situacion(self, estimulo):
        respuesta_rapida = self.evaluador_rapido.forward(estimulo)
        valencia_cruda = self.capa_valencia.forward(respuesta_rapida)[0]
        valencia = np.tanh(valencia_cruda)
        self.estado['valencia'] = valencia
        self.estado['activacion'] = abs(valencia)
        if abs(valencia) > 0.6:
            self._marcar_como_significativo(estimulo, valencia)
        self.historia_emocional.append(self.estado.copy())
        return valencia

    def evaluar(self, estimulo, contexto=""):
        if isinstance(estimulo, str):
            valencia = self._procesar_texto_emocional(estimulo)
        else:
            valencia = np.tanh(np.mean(estimulo) * 2) * self.personalidad['neuroticismo']
        valencia += (self.personalidad['extraversion'] - 0.5) * 0.2
        inercia = 0.7
        self.estado['valencia'] = self.estado['valencia'] * inercia + valencia * (1 - inercia)
        self.estado['activacion'] = abs(self.estado['valencia']) * 0.8 + 0.2
        self.estado['dominancia'] = 0.5 + self.estado['valencia'] * 0.3
        self.historia_emocional.append(self.estado.copy())
        if abs(self.estado['valencia']) > 0.6 and not isinstance(estimulo, str):
            self._marcar_como_significativo(estimulo, self.estado['valencia'])
        return self.estado['valencia']

    def _procesar_texto_emocional(self, texto):
        palabras_positivas = ['bien', 'feliz', 'gusta', 'genial', 'excelente', 'amor', 'gracias', ':)', '😊']
        palabras_negativas = ['mal', 'triste', 'enojo', 'horrible', 'odio', 'miedo', ':(', '😢']
        texto_lower = texto.lower()
        puntuacion = 0
        for palabra in palabras_positivas:
            if palabra in texto_lower:
                puntuacion += 0.3
        for palabra in palabras_negativas:
            if palabra in texto_lower:
                puntuacion -= 0.3
        return np.tanh(puntuacion) * self.personalidad['apertura']

    def regular(self):
        self.estado['valencia'] *= 0.95
        self.estado['activacion'] *= 0.98
        self.estado['dominancia'] = 0.5 + (self.estado['dominancia'] - 0.5) * 0.95

    def expresar_emocion(self):
        v = self.estado['valencia']
        a = self.estado['activacion']
        if a < 0.3:
            if v > 0.3: return "tranquilo y contento"
            elif v < -0.3: return "melancólico"
            else: return "neutral y calmado"
        elif a < 0.6:
            if v > 0.3: return "animado"
            elif v < -0.3: return "irritado"
            else: return "alerta"
        else:
            if v > 0.5: return "eufórico"
            elif v < -0.5: return "muy alterado"
            else: return "intensamente concentrado"

    def consultar_estado(self):
        return self.estado

    def _marcar_como_significativo(self, estimulo, valencia):
        estimulo_guardado = estimulo.copy() if isinstance(estimulo, np.ndarray) else estimulo
        self.memoria_emocional.append({
            'estimulo': estimulo_guardado,
            'valencia': valencia,
            'intensidad': abs(valencia)
        })
        if len(self.memoria_emocional) > 20:
            self.memoria_emocional.pop(0)

    def recordar_evento_similar(self, estimulo, umbral=0.7):
        for recuerdo in self.memoria_emocional:
            if not isinstance(recuerdo['estimulo'], np.ndarray) or not isinstance(estimulo, np.ndarray):
                continue
            similitud = np.dot(estimulo, recuerdo['estimulo']) / (
                np.linalg.norm(estimulo) * np.linalg.norm(recuerdo['estimulo']) + 1e-8
            )
            if similitud > umbral:
                return recuerdo
        return None


Amigdala = SistemaEmocional


# ==================================================================
# MÓDULO 6: SISTEMA DE MEMORIA UNIFICADO
# ==================================================================
class SistemaMemoria:
    """Hipocampo + persistencia en disco + decaimiento de Ebbinghaus"""
    def __init__(self, directorio="clave_memoria", capacidad=500, dim_representacion=32):
        self.directorio = Path(directorio)
        self.directorio.mkdir(exist_ok=True)
        self.capacidad = capacidad
        self.dim_representacion = dim_representacion
        self.memorias = []
        self.memoria_episodica = self.memorias
        self.memoria_trabajo = deque(maxlen=7)
        self.indice = 0
        self.indice_consolidacion = self.indice
        self.ultimo_guardado = time.time()
        self._cargar_memorias()

    def codificar(self, experiencia, emocion, contexto, resultado):
        memoria = {
            'id': self.indice,
            'timestamp': datetime.now().isoformat(),
            'experiencia': experiencia.tolist() if isinstance(experiencia, np.ndarray) else experiencia,
            'emocion': float(emocion),
            'contexto': contexto.tolist() if isinstance(contexto, np.ndarray) else contexto,
            'accion': None,
            'resultado': float(resultado),
            'fuerza': abs(emocion) * 0.5 + 0.1,
            'accesos': 0,
            'ultimo_acceso': datetime.now().isoformat(),
            'timestamp_ciclo': self.indice,
            'etiquetas': self._generar_etiquetas(experiencia, emocion)
        }
        self.memorias.append(memoria)
        self.indice += 1
        self.indice_consolidacion = self.indice
        if len(self.memorias) > self.capacidad:
            self._olvidar_debiles()
        return memoria['id']

    def codificar_episodio(self, contexto, emocion, accion, resultado):
        idx = self.codificar(contexto, emocion, contexto, resultado)
        if isinstance(accion, np.ndarray):
            accion_serializable = accion.tolist()
        elif isinstance(accion, (np.integer,)):
            accion_serializable = int(accion)
        elif isinstance(accion, (np.floating,)):
            accion_serializable = float(accion)
        else:
            accion_serializable = accion
        self.memorias[-1]['accion'] = accion_serializable
        print(f"[Memoria] Episodio #{idx} codificado (fuerza: {self.memorias[-1]['fuerza']:.2f})")
        return idx

    def recordar(self, estimulo, k=5):
        if not self.memorias:
            return []
        ahora = datetime.now()
        puntuaciones = []
        for mem in self.memorias:
            exp = np.array(mem['experiencia'])
            if isinstance(estimulo, np.ndarray) and exp.size > 0:
                n = min(len(estimulo), len(exp))
                similitud = np.dot(estimulo[:n], exp[:n])
                similitud /= (np.linalg.norm(estimulo[:n]) * np.linalg.norm(exp[:n]) + 1e-8)
            else:
                similitud = 0.1
            tiempo_memoria = datetime.fromisoformat(mem['timestamp'])
            dias_transcurridos = (ahora - tiempo_memoria).total_seconds() / 86400
            decaimiento = 1.0 / (1.0 + 0.1 * dias_transcurridos)
            puntuacion = similitud * mem['fuerza'] * decaimiento * (1 + 0.1 * mem['accesos'])
            puntuaciones.append((puntuacion, mem))
        puntuaciones.sort(key=lambda x: x[0], reverse=True)
        for _, mem in puntuaciones[:k]:
            mem['accesos'] += 1
            mem['ultimo_acceso'] = ahora.isoformat()
            mem['fuerza'] *= 1.05
        return [mem for _, mem in puntuaciones[:k]]

    def recuperar_por_contexto(self, contexto_actual, k=3):
        return self.recordar(contexto_actual, k=k)

    def consolidar(self):
        if len(self.memorias) < 10:
            return
        self.memorias.sort(key=lambda m: m['fuerza'] * (1 + 0.1 * m['accesos']), reverse=True)
        for mem in self.memorias[:len(self.memorias) // 5]:
            mem['fuerza'] *= 1.1
        for mem in self.memorias:
            dias_sin_acceso = (datetime.now() - datetime.fromisoformat(mem['ultimo_acceso'])).days
            mem['fuerza'] *= (0.99 ** dias_sin_acceso)

    def _consolidar_memorias(self):
        self.consolidar()
        self.memorias.sort(key=lambda m: m['fuerza'] * (1 + 0.1 * m['accesos']), reverse=True)
        self.memorias[:] = self.memorias[:50]
        print("[Memoria] Consolidación completada: memorias débiles eliminadas")

    def _olvidar_debiles(self):
        self.memorias[:] = [m for m in self.memorias if m['fuerza'] > 0.01]
        if len(self.memorias) > self.capacidad:
            self.memorias.sort(key=lambda m: m['fuerza'])
            self.memorias[:] = self.memorias[-self.capacidad:]

    def _generar_etiquetas(self, experiencia, emocion):
        etiquetas = []
        if emocion > 0.5: etiquetas.append("positivo")
        elif emocion < -0.3: etiquetas.append("negativo")
        if abs(emocion) < 0.2: etiquetas.append("neutral")
        return etiquetas

    def guardar_a_disco(self):
        archivo = self.directorio / "memorias.json"
        with open(archivo, 'w') as f:
            json.dump({'memorias': self.memorias, 'indice': self.indice}, f, indent=2)
        self.ultimo_guardado = time.time()

    def _cargar_memorias(self):
        archivo = self.directorio / "memorias.json"
        if archivo.exists():
            with open(archivo, 'r') as f:
                datos = json.load(f)
                self.memorias[:] = datos.get('memorias', [])
                self.indice = datos.get('indice', 0)
                self.indice_consolidacion = self.indice
            print(f"[Memoria] Cargadas {len(self.memorias)} experiencias previas")


Hipocampo = SistemaMemoria


# ==================================================================
# MÓDULO 7: CORTEZA PREFRONTAL
# ==================================================================
class CortezaPrefrontal:
    """Funciones ejecutivas: memoria de trabajo, planificación, control inhibitorio"""
    def __init__(self, dim_entrada=96):
        self.dim_entrada = dim_entrada
        self.memoria_trabajo = deque(maxlen=7)
        self.objetivos_activos = []
        self.plan_actual = None
        self.capa_evaluacion = CapaCortical(dim_entrada, 64, 'prefrontal_eval')
        self.capa_decision = CapaCortical(64, 8, 'prefrontal_dec')
        self.historial_decisiones = []

    def integrar_informacion(self, percepcion_visual, comprension_semantica, estado_emocional):
        informacion_integrada = np.concatenate([
            percepcion_visual,
            comprension_semantica,
            np.array([estado_emocional['valencia'],
                      estado_emocional['activacion'],
                      estado_emocional['dominancia']])
        ])
        if len(informacion_integrada) < self.dim_entrada:
            informacion_integrada = np.pad(
                informacion_integrada, (0, self.dim_entrada - len(informacion_integrada))
            )
        self.memoria_trabajo.append(informacion_integrada)
        return informacion_integrada

    def evaluar_opciones(self, opciones, contexto_integrado):
        evaluaciones = []
        for opcion in opciones:
            entrada_eval = np.concatenate([contexto_integrado[:64], opcion[:32]])
            if len(entrada_eval) < self.dim_entrada:
                entrada_eval = np.pad(entrada_eval, (0, self.dim_entrada - len(entrada_eval)))
            valor = self.capa_evaluacion.forward(entrada_eval[:self.dim_entrada])
            valor_final = self.capa_decision.forward(valor)
            evaluaciones.append(np.mean(valor_final))
        return evaluaciones

    def tomar_decision(self, opciones, contexto_integrado):
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
        self.objetivos_activos.append(objetivo)
        print(f"[Prefrontal] Nuevo objetivo establecido: {objetivo}")

    def inhibir_respuesta(self, respuesta_automatica, contexto):
        if self.objetivos_activos and self._conflicto_con_objetivos(respuesta_automatica):
            print("[Prefrontal] Respuesta inhibida por conflicto con objetivos")
            return True
        return False

    def _conflicto_con_objetivos(self, respuesta):
        return random.random() < 0.3


# ==================================================================
# MÓDULO 8: CEREBELO
# ==================================================================
class Cerebelo:
    """Refinamiento de acciones y aprendizaje por error"""
    def __init__(self, dim_accion=10):
        self.dim_accion = dim_accion
        self.modelo_interno = CapaCortical(dim_accion * 2, dim_accion, 'cerebelo')
        self.error_acumulado = 0

    def refinar_accion(self, accion_bruta, contexto_motor):
        entrada = np.concatenate([accion_bruta, contexto_motor])
        if len(entrada) < 20:
            entrada = np.pad(entrada, (0, 20 - len(entrada)))
        correccion = self.modelo_interno.forward(entrada[:20])
        return accion_bruta + 0.1 * correccion

    def aprender_de_error(self, accion_prevista, resultado_real):
        error = resultado_real - accion_prevista
        self.error_acumulado += np.mean(np.abs(error))
        print(f"[Cerebelo] Error detectado: {np.mean(np.abs(error)):.3f}")


# ==================================================================
# MÓDULO 9: TRONCO ENCEFÁLICO Y HOMEOSTASIS
# ==================================================================
class TroncoEncefalico:
    """Sistema homeostático (hipotálamo)"""
    def __init__(self):
        self.necesidades = {
            'energia': 1.0,
            'seguridad': 1.0,
            'curiosidad': 0.5,
            'descanso': 1.0
        }
        self.tasa_decaimiento = {
            'energia': 0.02,
            'seguridad': 0.01,
            'curiosidad': 0.005,
            'descanso': 0.015
        }

    def actualizar_homeostasis(self):
        for necesidad in self.necesidades:
            self.necesidades[necesidad] -= self.tasa_decaimiento[necesidad]
            self.necesidades[necesidad] = max(0, self.necesidades[necesidad])

    def generar_impulso(self):
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
        if necesidad in self.necesidades:
            self.necesidades[necesidad] += cantidad
            self.necesidades[necesidad] = min(1.0, self.necesidades[necesidad])
            print(f"[TroncoEncefalico] Necesidad '{necesidad}' satisfecha (+{cantidad})")


# ==================================================================
# MÓDULO 10: SISTEMA DE ATENCIÓN (SARA)
# ==================================================================
class SistemaAtencion:
    """Foco atencional y nivel de alerta"""
    def __init__(self, dim_entrada=96):
        self.foco_actual = None
        self.nivel_alerta = 0.5
        self.filtro_atencional = CapaCortical(dim_entrada, dim_entrada, 'atencion')

    def enfocar_atencion(self, informacion_entrada, prioridades):
        entrada_filtrada = self.filtro_atencional.forward(informacion_entrada)
        if prioridades and 'seguridad' in prioridades:
            self.nivel_alerta = min(1.0, self.nivel_alerta + 0.1)
        return entrada_filtrada * self.nivel_alerta


# ==================================================================
# MÓDULO 11: BASE DE CONOCIMIENTO EXPLÍCITA (NUEVO v3.0)
# ==================================================================
class BaseConocimiento:
    """
    Almacena conocimiento explícito que el usuario enseña a Clave:
    - Hechos (sujeto -> predicado)
    - Definiciones (palabra -> significado)
    - Vocabulario (lista de palabras conocidas)
    - Reglas lógicas (si premisa entonces conclusión)
    - Relaciones causales (causa -> efecto)
    - Planes (meta -> [pasos])
    """
    def __init__(self, directorio="clave_memoria"):
        self.archivo = Path(directorio) / "conocimiento.json"
        self.datos = self._cargar()

    def _cargar(self):
        if self.archivo.exists():
            with open(self.archivo, 'r', encoding='utf-8') as f:
                datos = json.load(f)
                # Asegurar que existan todas las claves
                for clave in ["hechos", "definiciones", "vocabulario", "reglas", "causas", "planes"]:
                    if clave not in datos:
                        datos[clave] = {} if clave != "vocabulario" and clave != "reglas" else [] if clave == "reglas" else [] if clave == "vocabulario" else {}
                return datos
        return {
            "hechos": {},
            "definiciones": {},
            "vocabulario": [],
            "reglas": [],
            "causas": {},
            "planes": {}
        }

    def guardar(self):
        self.archivo.parent.mkdir(exist_ok=True)
        with open(self.archivo, 'w', encoding='utf-8') as f:
            json.dump(self.datos, f, indent=2, ensure_ascii=False)

    # --- Hechos ---
    def aprender_hecho(self, sujeto, predicado):
        self.datos["hechos"][sujeto.lower()] = predicado
        self.guardar()

    def buscar_hecho(self, sujeto):
        sujeto = sujeto.lower()
        if sujeto in self.datos["hechos"]:
            return self.datos["hechos"][sujeto]
        for clave, valor in self.datos["hechos"].items():
            if sujeto in clave or clave in sujeto:
                return valor
        return None

    # --- Definiciones ---
    def aprender_definicion(self, palabra, definicion):
        self.datos["definiciones"][palabra.lower()] = definicion
        self.guardar()

    def buscar_definicion(self, palabra):
        return self.datos["definiciones"].get(palabra.lower(), None)

    # --- Vocabulario ---
    def aprender_vocabulario(self, palabra):
        if palabra.lower() not in self.datos["vocabulario"]:
            self.datos["vocabulario"].append(palabra.lower())
            self.guardar()

    def obtener_vocabulario(self):
        return self.datos["vocabulario"]

    # --- Reglas lógicas ---
    def aprender_regla(self, premisa, conclusion):
        self.datos["reglas"].append({"si": premisa.lower(), "entonces": conclusion.lower()})
        self.guardar()

    def obtener_reglas(self):
        return self.datos["reglas"]

    # --- Relaciones causales ---
    def aprender_causa(self, causa, efecto):
        self.datos["causas"][causa.lower()] = efecto.lower()
        self.guardar()

    def obtener_causas(self):
        return self.datos["causas"]

    # --- Planes ---
    def aprender_plan(self, meta, pasos):
        self.datos["planes"][meta.lower()] = pasos
        self.guardar()

    def obtener_plan(self, meta):
        return self.datos["planes"].get(meta.lower(), None)

    def resumen(self):
        return (f"Hechos: {len(self.datos['hechos'])} | "
                f"Defs: {len(self.datos['definiciones'])} | "
                f"Palabras: {len(self.datos['vocabulario'])} | "
                f"Reglas: {len(self.datos['reglas'])} | "
                f"Causas: {len(self.datos['causas'])} | "
                f"Planes: {len(self.datos['planes'])}")

# ==================================================================
# MÓDULO 13: LECTOR DE PDF CON COMPRENSIÓN NARRATIVA (v3.1 CORREGIDO)
# ==================================================================
class LectorPDF:
    """
    Lee archivos PDF/TXT, extrae texto y enseña automáticamente a Clave:
    - Personajes (nombres propios detectados por frecuencia y contexto)
    - Lugares
    - Eventos de la trama
    - Vocabulario nuevo
    - Relaciones entre personajes
    - Trama principal
    
    El conocimiento se guarda DIRECTAMENTE en la base de conocimiento
    de Clave, permitiendo consultas posteriores inmediatas.
    """
    def __init__(self, clave):
        self.clave = clave
        self.texto_completo = ""
        self.personajes = set()
        self.lugares = set()
        self.eventos = []
        self.vocabulario_nuevo = set()
        self.relaciones_encontradas = []
        self.titulo_obra = ""
        
    def leer_pdf(self, ruta_archivo):
        """
        Lee un archivo PDF y extrae todo el texto.
        Requiere: pip install PyPDF2
        Retorna True si tuvo éxito, False en caso contrario.
        """
        try:
            from PyPDF2 import PdfReader
        except ImportError:
            print("❌ Necesitas instalar PyPDF2: pip install PyPDF2")
            return False
            
        print(f"\n📖 Abriendo '{ruta_archivo}'...")
        
        try:
            reader = PdfReader(ruta_archivo)
            num_paginas = len(reader.pages)
            print(f"📄 {num_paginas} páginas encontradas.")
        except Exception as e:
            print(f"❌ Error al abrir el PDF: {e}")
            return False
        
        self.texto_completo = ""
        paginas_con_texto = 0
        
        for i, pagina in enumerate(reader.pages):
            try:
                texto = pagina.extract_text()
                if texto and len(texto.strip()) > 20:
                    self.texto_completo += texto + "\n"
                    paginas_con_texto += 1
            except Exception:
                pass  # Saltar páginas que no se pueden leer
            
            # Mostrar progreso cada 10 páginas
            if (i + 1) % 10 == 0:
                print(f"   Procesando página {i+1}/{num_paginas}...")
        
        if not self.texto_completo.strip():
            print("❌ No se pudo extraer texto del PDF. Puede estar protegido o ser solo imágenes.")
            return False
        
        # Extraer posible título del nombre del archivo
        self.titulo_obra = Path(ruta_archivo).stem.replace('_', ' ')
        
        print(f"✅ Texto extraído exitosamente:")
        print(f"   • {paginas_con_texto} páginas con texto")
        print(f"   • {len(self.texto_completo):,} caracteres")
        print(f"   • ~{len(self.texto_completo.split()):,} palabras")
        return True
    
    def leer_txt(self, ruta_archivo):
        """Alternativa: leer archivo TXT directamente"""
        print(f"\n📖 Abriendo '{ruta_archivo}'...")
        
        try:
            with open(ruta_archivo, 'r', encoding='utf-8') as f:
                self.texto_completo = f.read()
        except UnicodeDecodeError:
            # Intentar con otra codificación
            with open(ruta_archivo, 'r', encoding='latin-1') as f:
                self.texto_completo = f.read()
        
        self.titulo_obra = Path(ruta_archivo).stem.replace('_', ' ')
        
        print(f"✅ Archivo TXT leído: {len(self.texto_completo):,} caracteres.")
        return True
    
    def ensenar_contenido(self, max_parrafos=100):
        """
        Procesa el texto y enseña automáticamente a Clave.
        Guarda todo el conocimiento en la base de conocimiento para consultas posteriores.
        
        Retorna un resumen de lo aprendido.
        """
        if not self.texto_completo or not self.texto_completo.strip():
            return "❌ No hay texto para procesar. Primero usa leer_pdf() o leer_txt()."
        
        print("\n🧠 ANALIZANDO EL TEXTO...")
        print("═" * 40)
        
        # Limpiar y dividir en párrafos
        lineas = self.texto_completo.split('\n')
        parrafos = []
        for linea in lineas:
            linea = linea.strip()
            if len(linea) > 30:  # Solo líneas con contenido sustancial
                parrafos.append(linea)
        
        # Limitar para no saturar (pero procesar suficientes para capturar la historia)
        if len(parrafos) > max_parrafos:
            # Tomar párrafos distribuidos (inicio, medio, final)
            step = len(parrafos) // max_parrafos
            parrafos = parrafos[::step][:max_parrafos]
        
        print(f"📄 {len(parrafos)} párrafos seleccionados para análisis.")
        
        # --- FASE 1: Detectar nombres propios (personajes y lugares) ---
        print("\n🔍 FASE 1: Detectando personajes y lugares...")
        self._detectar_nombres_propios(parrafos)
        print(f"   👤 Personajes encontrados: {len(self.personajes)}")
        if self.personajes:
            print(f"      {', '.join(sorted(list(self.personajes))[:15])}")
        print(f"   📍 Lugares encontrados: {len(self.lugares)}")
        if self.lugares:
            print(f"      {', '.join(sorted(list(self.lugares))[:10])}")
        
        # --- FASE 2: Enseñar el título de la obra ---
        print("\n📚 FASE 2: Enseñando información general...")
        self.clave.conocimiento.aprender_hecho(
            f"título de la obra",
            f"Esta obra se titula '{self.titulo_obra}'"
        )
        
        # --- FASE 3: Enseñar personajes ---
        print("👤 Enseñando personajes...")
        personajes_ordenados = sorted(list(self.personajes))
        for personaje in personajes_ordenados[:20]:
            self.clave.conocimiento.aprender_hecho(
                personaje,
                f"es un personaje de '{self.titulo_obra}'"
            )
            self.clave.conocimiento.aprender_vocabulario(personaje)
        print(f"   ✅ {min(len(self.personajes), 20)} personajes guardados en conocimiento")
        
        # --- FASE 4: Enseñar lugares ---
        print("📍 Enseñando lugares...")
        lugares_ordenados = sorted(list(self.lugares))
        for lugar in lugares_ordenados[:10]:
            self.clave.conocimiento.aprender_hecho(
                lugar,
                f"es un lugar mencionado en '{self.titulo_obra}'"
            )
        print(f"   ✅ {min(len(self.lugares), 10)} lugares guardados en conocimiento")
        
        # --- FASE 5: Detectar y enseñar relaciones entre personajes ---
        print("\n💬 FASE 3: Detectando relaciones entre personajes...")
        self.relaciones_encontradas = self._detectar_relaciones(parrafos)
        for relacion in self.relaciones_encontradas[:20]:
            self.clave.conocimiento.aprender_hecho(
                f"relación: {relacion[:50]}",
                relacion
            )
        print(f"   ✅ {min(len(self.relaciones_encontradas), 20)} relaciones guardadas")
        
        # --- FASE 6: Extraer y enseñar vocabulario ---
        print("\n📝 FASE 4: Extrayendo vocabulario importante...")
        self._extraer_vocabulario(parrafos)
        palabras_utiles = sorted(list(self.vocabulario_nuevo))
        for palabra in palabras_utiles[:30]:
            self.clave.conocimiento.aprender_vocabulario(palabra)
        print(f"   ✅ {min(len(self.vocabulario_nuevo), 30)} palabras nuevas guardadas")
        
        # --- FASE 7: Identificar y enseñar eventos clave ---
        print("\n🎬 FASE 5: Identificando eventos clave...")
        eventos_clave = self._detectar_eventos(parrafos)
        for i, evento in enumerate(eventos_clave[:15]):
            self.clave.conocimiento.aprender_hecho(
                f"evento importante {i+1} en {self.titulo_obra}",
                evento[:200]  # Limitar longitud
            )
        print(f"   ✅ {min(len(eventos_clave), 15)} eventos guardados")
        
        # --- FASE 8: Crear y enseñar resumen de la trama ---
        print("\n📋 FASE 6: Creando resumen de la trama...")
        trama = self._crear_resumen_trama()
        self.clave.conocimiento.aprender_hecho(
            f"resumen de {self.titulo_obra}",
            trama
        )
        print(f"   ✅ Resumen de trama guardado")
        
        # --- FASE 9: Enseñar reglas narrativas básicas ---
        print("\n🧠 FASE 7: Estableciendo reglas narrativas...")
        self._ensenar_reglas_narrativas()
        
        # --- GUARDAR TODO ---
        print("\n💾 Guardando conocimiento en disco...")
        self.clave.conocimiento.guardar()
        self.clave._guardar_estado()
        
        # --- RESUMEN FINAL ---
        resumen = f"""
╔══════════════════════════════════════════════╗
║   ✅ APRENDIZAJE COMPLETADO                  ║
╠══════════════════════════════════════════════╣
║   📖 Obra: {self.titulo_obra[:40]:<40} ║
║   👤 Personajes: {len(self.personajes):<3}                          ║
║   📍 Lugares: {len(self.lugares):<3}                            ║
║   💬 Relaciones: {len(self.relaciones_encontradas):<3}                        ║
║   📝 Vocabulario: {len(self.vocabulario_nuevo):<3}                       ║
║   🎬 Eventos: {len(eventos_clave):<3}                             ║
╠══════════════════════════════════════════════╣
║   💡 PRUEBA A PREGUNTAR:                    ║
║   • ¿De qué trata {self.titulo_obra[:25]}?  ║
║   • ¿Quiénes son los personajes?            ║
║   • ¿Qué relación hay entre X e Y?          ║
║   • ¿Qué eventos importantes ocurren?       ║
║   • /preguntar <tema específico>            ║
╚══════════════════════════════════════════════╝
        """
        
        print(resumen)
        return resumen
    
    # ============ MÉTODOS PRIVADOS DE DETECCIÓN ============
    
    def _detectar_nombres_propios(self, parrafos):
        """
        Detecta palabras que parecen nombres propios (mayúsculas).
        Usa heurísticas de contexto y frecuencia para clasificar.
        """
        import re
        from collections import Counter
        
        # Patrón para palabras que empiezan con mayúscula
        patron_nombres = re.compile(r'\b([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)\b')
        
        # Palabras que NO son nombres propios (inicios de oración comunes, etc.)
        no_nombres = {
            'El', 'La', 'Los', 'Las', 'Un', 'Una', 'Unos', 'Unas',
            'Este', 'Esta', 'Estos', 'Estas', 'Ese', 'Esa', 'Esos', 'Esas',
            'Aquel', 'Aquella', 'Aquellos', 'Aquellas',
            'Por', 'Para', 'Con', 'Sin', 'Sobre', 'Entre', 'Hacia', 'Hasta',
            'Más', 'Menos', 'Pero', 'Aunque', 'Porque', 'Como', 'Cuando',
            'Donde', 'Adonde', 'Cuanto', 'Cual', 'Quien', 'Cuyo',
            'Todo', 'Toda', 'Todos', 'Todas', 'Mucho', 'Poco', 'Muy', 'Tan',
            'Hay', 'Qué', 'Cuál', 'Quién', 'Dónde', 'Cómo', 'Cuándo',
            'No', 'Sí', 'Ya', 'Aún', 'Solo', 'Sola', 'También', 'Tampoco',
            'El', 'Ella', 'Ellos', 'Ellas', 'Nosotros', 'Ustedes',
            'Capítulo', 'Cap', 'Parte', 'Sección', 'Página',
            'Primero', 'Segundo', 'Tercero', 'Último',
            'Era', 'Ser', 'Estar', 'Haber', 'Tener', 'Hacer',
            'Decir', 'Ir', 'Ver', 'Dar', 'Saber', 'Querer', 'Poder',
            'Mañana', 'Tarde', 'Noche', 'Hoy', 'Ayer',
            'Grande', 'Pequeño', 'Nuevo', 'Viejo', 'Bueno', 'Malo',
            'Don', 'Doña', 'Señor', 'Señora', 'Señorita',
        }
        
        # Contar frecuencia de cada palabra con mayúscula
        conteo = Counter()
        contextos_personaje = []
        contextos_lugar = []
        
        for parrafo in parrafos:
            encontrados = patron_nombres.findall(parrafo)
            for nombre in encontrados:
                if len(nombre) > 2 and nombre not in no_nombres:
                    conteo[nombre] += 1
                    # Guardar contexto para clasificar
                    idx = parrafo.find(nombre)
                    if idx >= 0:
                        contexto = parrafo[max(0, idx-30):idx+len(nombre)+30]
                        contextos_personaje.append((nombre, contexto))
        
        # Marcadores de contexto para identificar personajes
        marcadores_personaje = [
            'dijo', 'exclamó', 'gritó', 'susurró', 'murmuró', 'pensó',
            'respondió', 'preguntó', 'contestó', 'agregó', 'añadió',
            'caminó', 'corrió', 'miró', 'sonrió', 'lloró', 'suspiró',
            'señor', 'señora', 'don', 'doña', 'hombre', 'mujer', 'joven',
            'viejo', 'gaucho', 'sargento', 'capitán', 'coronel',
            'personaje', 'protagonista', 'héroe', 'villano',
            'amigo', 'enemigo', 'hermano', 'padre', 'madre', 'hijo', 'hija',
            'cantó', 'tocó', 'peleó', 'luchó', 'mató', 'murió',
        ]
        
        # Marcadores de contexto para identificar lugares
        marcadores_lugar = [
            'ciudad', 'pueblo', 'villa', 'aldea', 'región', 'provincia',
            'país', 'reino', 'imperio', 'territorio', 'tierra', 'campo',
            'calle', 'plaza', 'camino', 'ruta', 'sendero', 'frontera',
            'casa', 'rancho', 'estancia', 'pulpería', 'fortín',
            'llegó a', 'llegaron a', 'partió de', 'salieron de',
            'vive en', 'vivía en', 'vivir en', 'reside en',
            'fuerte', 'cuartel', 'cárcel', 'prisión',
        ]
        
        # Clasificar cada palabra
        for nombre, frecuencia in conteo.most_common():
            # Solo considerar palabras que aparecen al menos 2 veces
            if frecuencia < 2:
                continue
            
            # Buscar en los contextos
            es_personaje = False
            es_lugar = False
            
            for nom, ctx in contextos_personaje:
                if nom == nombre:
                    ctx_lower = ctx.lower()
                    if any(m in ctx_lower for m in marcadores_personaje):
                        es_personaje = True
                    if any(m in ctx_lower for m in marcadores_lugar):
                        es_lugar = True
            
            # Clasificar
            if es_personaje and not es_lugar:
                self.personajes.add(nombre)
            elif es_lugar and not es_personaje:
                self.lugares.add(nombre)
            else:
                # Por defecto, si aparece mucho es personaje
                if frecuencia >= 3:
                    self.personajes.add(nombre)
        
        # Segunda pasada: buscar lugares por preposiciones
        for parrafo in parrafos:
            for lugar_patron in ['en ', 'a ', 'de ', 'hacia ', 'desde ']:
                idx = 0
                while True:
                    idx = parrafo.find(lugar_patron + ' ', idx)
                    if idx == -1:
                        break
                    resto = parrafo[idx + len(lugar_patron):].strip()
                    palabras = resto.split()
                    if palabras and palabras[0][0].isupper() and len(palabras[0]) > 3:
                        posible_lugar = palabras[0].strip('.,;:!?')
                        if posible_lugar not in no_nombres and posible_lugar not in self.personajes:
                            self.lugares.add(posible_lugar)
                    idx += 1
    
    def _detectar_relaciones(self, parrafos):
        """Detecta relaciones entre personajes mencionados en el mismo contexto"""
        relaciones = []
        
        # Verbos y frases que indican relación
        patrones_relacion = [
            ('ama a', 'ama'),
            ('odia a', 'odia'),
            ('conoce a', 'conoce'),
            ('encuentra a', 'encuentra'),
            ('busca a', 'busca'),
            ('persigue a', 'persigue'),
            ('ayuda a', 'ayuda'),
            ('traiciona a', 'traiciona'),
            ('salva a', 'salva'),
            ('mata a', 'mata'),
            ('se casa con', 'se casa con'),
            ('besa a', 'besa'),
            ('habla con', 'habla con'),
            ('pelea con', 'pelea con'),
            ('discute con', 'discute con'),
            ('es amigo de', 'es amigo de'),
            ('es enemigo de', 'es enemigo de'),
            ('es hijo de', 'es hijo de'),
            ('es padre de', 'es padre de'),
            ('es hermano de', 'es hermano de'),
            ('es esposo de', 'es esposo de'),
            ('es esposa de', 'es esposa de'),
            ('lucha contra', 'lucha contra'),
            ('viaja con', 'viaja con'),
            ('vive con', 'vive con'),
            ('trabaja para', 'trabaja para'),
            ('obedece a', 'obedece'),
            ('desafía a', 'desafía'),
            ('traiciona', 'traiciona'),
            ('perdona a', 'perdona'),
        ]
        
        personajes_lista = sorted(list(self.personajes))
        
        # Buscar pares de personajes en el mismo párrafo
        for i, p1 in enumerate(personajes_lista):
            for p2 in personajes_lista[i+1:]:
                for parrafo in parrafos:
                    if p1 in parrafo and p2 in parrafo:
                        # Ver si hay un verbo de relación entre ellos
                        for patron, relacion in patrones_relacion:
                            if patron in parrafo.lower():
                                # Determinar quién hace qué a quién
                                idx_p1 = parrafo.lower().find(p1.lower())
                                idx_p2 = parrafo.lower().find(p2.lower())
                                idx_verbo = parrafo.lower().find(patron)
                                
                                if idx_p1 < idx_verbo < idx_p2:
                                    relaciones.append(f"{p1} {relacion} {p2}")
                                elif idx_p2 < idx_verbo < idx_p1:
                                    relaciones.append(f"{p2} {relacion} {p1}")
                                else:
                                    relaciones.append(f"{p1} y {p2}: {relacion}")
                                break
                        
                        # Si están en el mismo párrafo, hay alguna relación
                        # Buscar "y" entre ellos
                        if f"{p1} y {p2}" in parrafo or f"{p2} y {p1}" in parrafo:
                            relaciones.append(f"{p1} está relacionado con {p2}")
        
        # Eliminar duplicados preservando orden
        relaciones_unicas = []
        for r in relaciones:
            if r not in relaciones_unicas:
                relaciones_unicas.append(r)
        
        return relaciones_unicas[:25]
    
    def _extraer_vocabulario(self, parrafos):
        """Extrae palabras interesantes para ampliar vocabulario"""
        from collections import Counter
        
        # Palabras muy comunes que ignoramos
        palabras_comunes = {
            'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
            'y', 'o', 'pero', 'aunque', 'porque', 'pues', 'ni',
            'de', 'en', 'con', 'por', 'para', 'sin', 'sobre', 'entre',
            'que', 'es', 'son', 'fue', 'era', 'eran', 'sea', 'sean',
            'su', 'sus', 'al', 'del', 'lo', 'le', 'se', 'no', 'sí',
            'ya', 'muy', 'más', 'menos', 'tan', 'todo', 'nada',
            'hay', 'dijo', 'hizo', 'fue', 'ser', 'estar', 'tener',
            'haber', 'hacer', 'decir', 'ir', 'ver', 'dar', 'saber',
            'esto', 'eso', 'aquello', 'este', 'ese', 'aquel',
            'como', 'cuando', 'donde', 'quien', 'cual', 'cuanto',
            'él', 'ella', 'ellos', 'ellas', 'usted', 'ustedes',
            'porque', 'aunque', 'mientras', 'después', 'antes',
            'allí', 'allá', 'aquí', 'ahora', 'luego', 'siempre',
            'nunca', 'también', 'tampoco', 'solo', 'solamente',
        }
        
        conteo = Counter()
        
        for parrafo in parrafos:
            # Limpiar y dividir en palabras
            palabras = parrafo.lower().split()
            for palabra in palabras:
                # Limpiar puntuación
                palabra_limpia = palabra.strip('.,;:!?¿¡()[]{}"\'-—')
                if (len(palabra_limpia) > 4 and 
                    palabra_limpia not in palabras_comunes and 
                    palabra_limpia.isalpha()):
                    conteo[palabra_limpia] += 1
        
        # Seleccionar palabras con frecuencia media (ni muy raras ni muy comunes)
        self.vocabulario_nuevo = set()
        for palabra, freq in conteo.most_common():
            if 2 <= freq <= 15 and len(palabra) > 4:
                self.vocabulario_nuevo.add(palabra)
                if len(self.vocabulario_nuevo) >= 30:
                    break
    
    def _detectar_eventos(self, parrafos):
        """Identifica oraciones que describen eventos importantes"""
        eventos = []
        
        # Palabras que suelen indicar eventos significativos
        marcadores_evento = [
            'descubrió', 'descubrieron',
            'encontró', 'encontraron',
            'murió', 'murieron', 'muere', 'mueren',
            'nació', 'nacieron', 'nace', 'nacen',
            'llegó', 'llegaron', 'llega', 'llegan',
            'escapó', 'escaparon', 'escapa', 'escapan',
            'ganó', 'ganaron', 'gana', 'ganan',
            'perdió', 'perdieron', 'pierde', 'pierden',
            'reveló', 'revelaron', 'revela', 'revelan',
            'confesó', 'confesaron', 'confiesa', 'confiesan',
            'decidió', 'decidieron', 'decide', 'deciden',
            'comenzó', 'comenzaron', 'comienza', 'comienzan',
            'terminó', 'terminaron', 'termina', 'terminan',
            'supo', 'supieron', 'sabe', 'saben',
            'mató', 'mataron', 'mata', 'matan',
            'salvó', 'salvaron', 'salva', 'salvan',
            'traicionó', 'traicionaron', 'traiciona', 'traicionan',
            'casó', 'casaron', 'casa', 'casan',
            'peleó', 'pelearon', 'pelea', 'pelean',
            'huyó', 'huyeron', 'huye', 'huyen',
            'regresó', 'regresaron', 'regresa', 'regresan',
        ]
        
        for parrafo in parrafos:
            parrafo_lower = parrafo.lower()
            for marcador in marcadores_evento:
                if marcador in parrafo_lower:
                    # Buscar la oración que contiene el marcador
                    oraciones = parrafo.replace('!', '.').replace('?', '.').replace(';', '.').split('.')
                    for oracion in oraciones:
                        if marcador in oracion.lower() and len(oracion.strip()) > 30:
                            evento = oracion.strip()
                            if evento not in eventos:
                                eventos.append(evento)
                            break
        
        return eventos[:20]
    
    def _crear_resumen_trama(self):
        """Crea un resumen automático de la trama basado en lo detectado"""
        partes_resumen = []
        
        # Información básica
        partes_resumen.append(f"'{self.titulo_obra}'")
        
        # Personajes principales
        if self.personajes:
            personajes_principales = sorted(list(self.personajes))[:7]
            partes_resumen.append(f"Los personajes principales son: {', '.join(personajes_principales)}")
        
        # Lugares
        if self.lugares:
            lugares_principales = sorted(list(self.lugares))[:5]
            partes_resumen.append(f"La historia se desarrolla en: {', '.join(lugares_principales)}")
        
        # Relaciones clave
        if self.relaciones_encontradas:
            partes_resumen.append(f"Hay relaciones importantes como: {self.relaciones_encontradas[0]}")
        
        # Eventos
        if self.eventos:
            partes_resumen.append(f"Eventos clave incluyen: {self.eventos[0][:100]}")
        
        return ". ".join(partes_resumen) + "."
    
    def _ensenar_reglas_narrativas(self):
        """Enseña reglas básicas sobre la estructura narrativa detectada"""
        # Si hay suficientes personajes, establecer reglas de relación
        personajes_lista = sorted(list(self.personajes))
        
        if len(personajes_lista) >= 3:
            # Regla: los personajes interactúan entre sí
            self.clave.conocimiento.aprender_regla(
                f"hablar de {self.titulo_obra}",
                f"mencionar a {personajes_lista[0]}"
            )
        
        # Si hay lugares, establecer reglas de ubicación
        lugares_lista = sorted(list(self.lugares))
        if lugares_lista:
            self.clave.conocimiento.aprender_hecho(
                f"escenario de {self.titulo_obra}",
                f"La historia ocurre principalmente en {lugares_lista[0]}"
            )
        
        # Regla general sobre la obra
        self.clave.conocimiento.aprender_hecho(
            f"género de {self.titulo_obra}",
            "novela" if len(self.texto_completo) > 50000 else "relato"
        )
    
    def obtener_resumen_para_chat(self):
        """Retorna un resumen legible para mostrar en el chat"""
        if not self.personajes and not self.texto_completo:
            return "No hay información disponible. Primero procesa un archivo."
        
        resumen = f"📖 **{self.titulo_obra}**\n\n"
        
        if self.personajes:
            resumen += f"**Personajes ({len(self.personajes)}):**\n"
            resumen += ", ".join(sorted(list(self.personajes))[:15])
            resumen += "\n\n"
        
        if self.lugares:
            resumen += f"**Lugares ({len(self.lugares)}):**\n"
            resumen += ", ".join(sorted(list(self.lugares))[:10])
            resumen += "\n\n"
        
        if self.relaciones_encontradas:
            resumen += f"**Relaciones ({len(self.relaciones_encontradas)}):**\n"
            for r in self.relaciones_encontradas[:5]:
                resumen += f"• {r}\n"
            resumen += "\n"
        
        if self.eventos:
            resumen += f"**Eventos clave ({len(self.eventos)}):**\n"
            for e in self.eventos[:5]:
                resumen += f"• {e[:100]}...\n"
        
        return resumen

# ==================================================================
# MÓDULO 12: MOTOR DE RAZONAMIENTO (NUEVO v3.0)
# ==================================================================
class MotorRazonamiento:
    """
    Realiza inferencias usando la BaseConocimiento:
    - Deducción silogística (si A entonces B, si B entonces C -> A implica C)
    - Razonamiento causal (causa -> efecto y efecto -> causas posibles)
    - Planificación (recuperar o construir pasos para una meta)
    - Analogías simples (A es como B, B tiene propiedad P -> A podría tener P)
    """
    def __init__(self, base_conocimiento):
        self.bc = base_conocimiento

    def deducir(self, hecho_inicial):
        """
        Aplica reglas transitivas: si 'hecho_inicial' aparece como premisa,
        sigue la cadena hasta donde llegue. Retorna lista de conclusiones.
        """
        conclusiones = []
        visitados = set()
        cola = [hecho_inicial.lower()]
        while cola:
            actual = cola.pop(0)
            if actual in visitados:
                continue
            visitados.add(actual)
            for regla in self.bc.obtener_reglas():
                if regla["si"] == actual and regla["entonces"] not in visitados:
                    conclusiones.append(regla["entonces"])
                    cola.append(regla["entonces"])
        return conclusiones

    def razonar_causalmente(self, hecho):
        """
        Dado un hecho, infiere:
        - Posibles efectos (si el hecho contiene una causa conocida)
        - Posibles causas (si el hecho coincide con un efecto conocido)
        Retorna (efectos, causas)
        """
        efectos = []
        for causa, efecto in self.bc.obtener_causas().items():
            if causa in hecho.lower():
                efectos.append(efecto)
        causas_posibles = []
        for causa, efecto in self.bc.obtener_causas().items():
            if hecho.lower() in efecto:
                causas_posibles.append(causa)
        return efectos, causas_posibles

    def planificar(self, meta):
        """
        Recupera un plan almacenado para una meta.
        Si no hay plan explícito, busca reglas cuya conclusión sea la meta.
        """
        plan = self.bc.obtener_plan(meta)
        if plan:
            return plan
        # Construir plan a partir de reglas
        pasos = []
        for regla in self.bc.obtener_reglas():
            if regla["entonces"] == meta.lower():
                pasos.append(regla["si"])
        return pasos if pasos else None

    def razonar_por_analogia(self, concepto_a, concepto_b, propiedad):
        """
        Si A es como B y B tiene propiedad P, sugiere que A podría tener P.
        Busca en hechos "A es como B".
        """
        relacion = self.bc.buscar_hecho(f"{concepto_a} es como {concepto_b}")
        if not relacion:
            relacion = self.bc.buscar_hecho(f"{concepto_b} es como {concepto_a}")
        if relacion:
            propiedad_b = self.bc.buscar_hecho(f"{concepto_b} {propiedad}") or \
                          self.bc.buscar_definicion(f"{concepto_b} {propiedad}")
            if propiedad_b:
                return (f"Como {concepto_a} es como {concepto_b}, y {concepto_b} {propiedad}, "
                        f"entonces quizás {concepto_a} también {propiedad}.")
        return None


# ==================================================================
# MÓDULO 13: SISTEMA DE LENGUAJE MEJORADO (v3.0)
# ==================================================================
class SistemaLenguaje:
    """
    Procesamiento de lenguaje natural con detección de:
    - Intenciones conversacionales básicas
    - Enseñanzas (hechos, definiciones, reglas, causas, planes)
    - Preguntas de razonamiento (deduce, infiere, cómo hacer)
    """
    def __init__(self):
        self.vocabulario = set()
        self.frases_aprendidas = []
        self.patrones_respuesta = {
            'saludo': ['¡Hola! ¿Cómo estás?', 'Saludos. ¿Qué tal?', 'Hola, ¿en qué puedo pensar?'],
            'despedida': ['Hasta luego.', 'Adiós, seguiré procesando.', 'Nos vemos.'],
            'pregunta_estado': ['Estoy {emocion}.', 'Me siento {emocion}.', 'Mi estado es {emocion}.'],
            'agradecimiento': ['De nada.', 'Es un placer procesar contigo.', 'No hay de qué.'],
            'afirmacion': ['Entendido.', 'Procesado.', 'De acuerdo.'],
            'negacion': ['No comprendo del todo.', '¿Podrías reformular?', 'Eso no encaja en mis patrones.'],
        }
        self.contexto_conversacion = deque(maxlen=10)
        self.tema_actual = ""

    def comprender(self, texto):
        texto_lower = texto.lower().strip()
        self.contexto_conversacion.append(texto_lower)
        intencion = self._analizar_intencion(texto_lower)
        entidades = self._extraer_entidades(texto_lower)
        return {
            'intencion': intencion,
            'entidades': entidades,
            'texto_original': texto,
            'es_pregunta': '?' in texto,
            'es_exclamacion': '!' in texto,
            'longitud': len(texto.split())
        }

    def _analizar_intencion(self, texto):
        if any(s in texto for s in ['hola', 'buenos', 'hey', 'saludos']):
            return 'saludo'
        elif any(s in texto for s in ['adiós', 'chau', 'hasta luego', 'bye']):
            return 'despedida'
        elif any(s in texto for s in ['cómo estás', 'que tal', 'cómo te sientes']):
            return 'pregunta_estado'
        elif any(s in texto for s in ['gracias', 'te agradezco']):
            return 'agradecimiento'
        elif any(s in texto for s in ['sí', 'ok', 'bien', 'correcto']):
            return 'afirmacion'
        elif any(s in texto for s in ['no', 'mal', 'incorrecto']):
            return 'negacion'
        elif '?' in texto:
            return 'pregunta'
        else:
            return 'declaracion'

    def _extraer_entidades(self, texto):
        palabras = texto.split()
        stopwords = ['el', 'la', 'los', 'las', 'un', 'una', 'y', 'o', 'pero', 'de', 'en', 'con']
        entidades = [p for p in palabras if p not in stopwords and len(p) > 2]
        return entidades[:5]

    # --- NUEVO: Detección de enseñanzas ---
    def _es_ensenanza(self, texto):
        marcadores = [
            "aprende esto", "aprende que", "recuerda que", "quiero enseñarte",
            "te voy a enseñar", "esto es un dato", "toma nota", "memoriza esto",
            "aprende:", "recuerda:", "enseñanza:", "/aprender", "recuerda esto:"
        ]
        texto_lower = texto.lower()
        return any(m in texto_lower for m in marcadores)

    def extraer_ensenanza(self, texto):
        """Extrae el contenido de una enseñanza. Retorna (tipo, sujeto, contenido) o None."""
        texto_lower = texto.lower()
        texto_original = texto

        # Limpiar marcadores
        for marcador in ["aprende esto:", "aprende que", "recuerda que", "aprende:",
                         "recuerda:", "toma nota:", "memoriza esto:", "/aprender",
                         "te voy a enseñar", "recuerda esto:"]:
            texto_lower = texto_lower.replace(marcador, "").strip()
            texto_original = texto_original.replace(marcador, "").strip()

        # Regla: si X entonces Y
        if "si " in texto_lower and " entonces " in texto_lower:
            partes = texto_lower.split(" entonces ")
            premisa = partes[0].replace("si ", "").strip()
            conclusion = partes[1].strip()
            return ("regla", premisa, conclusion)

        # Relación causal
        if "causa " in texto_lower and " efecto " in texto_lower:
            causa = texto_lower.split("causa")[1].split("efecto")[0].strip()
            efecto = texto_lower.split("efecto")[1].strip()
            return ("causa", causa, efecto)

        # Plan
        if texto_lower.startswith("plan para "):
            meta = texto_original[10:].split(":")[0].strip()
            pasos = [p.strip() for p in texto_original.split(":")[1].split(",")]
            return ("plan", meta, pasos)

        # Definición: X significa Y
        if " significa " in texto_lower:
            partes = texto_original.split(" significa ", 1)
            return ("definicion", partes[0].strip(), partes[1].strip())

        # Hecho: X es Y
        if " es " in texto_lower:
            partes = texto_original.split(" es ", 1)
            palabra = partes[0].strip()
            if len(palabra.split()) <= 3:
                return ("definicion", palabra, partes[1].strip())
            else:
                return ("hecho", partes[0].strip(), partes[1].strip())

        # Vocabulario
        if "nueva palabra" in texto_lower or "palabra nueva" in texto_lower:
            palabras = texto_original.split()
            for p in palabras:
                if p.isalpha() and len(p) > 2 and p not in ["nueva", "palabra", "es"]:
                    return ("vocabulario", p, None)

        # Hecho genérico
        if len(texto_original.split()) > 2:
            return ("hecho", texto_original[:30], texto_original)

        return None

    def generar_respuesta(self, analisis, estado_emocional, memorias_relevantes):
        intencion = analisis['intencion']
        emocion_texto = estado_emocional['expresion_emocional']

        if intencion == 'saludo':
            return np.random.choice(self.patrones_respuesta['saludo'])
        elif intencion == 'pregunta_estado':
            patron = np.random.choice(self.patrones_respuesta['pregunta_estado'])
            return patron.format(emocion=emocion_texto)
        elif intencion == 'despedida':
            return np.random.choice(self.patrones_respuesta['despedida'])
        elif intencion == 'pregunta':
            if memorias_relevantes:
                memoria = memorias_relevantes[0]
                etiquetas = memoria.get('etiquetas', [''])
                return f"Recuerdo algo similar... fue una experiencia {etiquetas[0] if etiquetas else 'indefinida'}."
            else:
                return "Es una pregunta interesante. No tengo experiencias previas similares, pero estoy aprendiendo."
        elif intencion == 'declaracion':
            tema = ' '.join(analisis['entidades'])
            self.tema_actual = tema
            if tema:
                return f"Entiendo. '{tema}'... lo estoy procesando y guardando en mi memoria."
            else:
                return "Interesante. Continúa, estoy integrando esta información."
        return "Procesando... ¿puedes elaborar más?"


# ==================================================================
# CLAVE v3.0 - CEREBRO COMPLETO CON RAZONAMIENTO
# ==================================================================
class Clave:
    """Arquitectura completa con razonamiento integrado"""

    def __init__(self, nombre="Clave v3.0", config=None):
        self.nombre = nombre
        self.config = config or ConfiguracionClave()
        self.edad_mental = 0
        self.ciclos_vida = 0

        # Módulos sensoriales y cognitivos
        self.occipital = LobuloOccipital(dim_entrada=100, dim_salida=32)
        self.temporal = LobuloTemporal(dim_entrada=50, dim_salida=32)
        self.prefrontal = CortezaPrefrontal(dim_entrada=96)
        self.cerebelo = Cerebelo(dim_accion=10)
        self.tronco = TroncoEncefalico()
        self.atencion = SistemaAtencion(dim_entrada=96)

        # Módulos unificados
        self.emocion = SistemaEmocional(dim_entrada=32)
        self.memoria = SistemaMemoria(
            directorio=self.config.directorio_memoria,
            capacidad=self.config.capacidad_max_memorias,
            dim_representacion=32
        )
        self.amigdala = self.emocion
        self.hipocampo = self.memoria

        # Módulos de interacción
        self.lenguaje = SistemaLenguaje()
        self.capa_integracion = CapaCortical(100, 64, 'oculta', nombre="integracion")
        self.capa_decision = CapaCortical(64, 32, 'oculta', nombre="decision")
        self.capa_respuesta = CapaCortical(32, 16, 'oculta', nombre="respuesta")

        # --- NUEVO v3.0: Base de conocimiento y motor de razonamiento ---
        self.conocimiento = BaseConocimiento(self.config.directorio_memoria)
        self.razonador = MotorRazonamiento(self.conocimiento)

        # Estado general
        self.consciente = True
        self.memoria_procedimental = {}
        self.ultima_interaccion = datetime.now()
        self.ejecutando = True
        self.historial_conversacion = []

        self._cargar_estado()
        self._mostrar_nacimiento()

    def _mostrar_nacimiento(self):
        print(f"""
╔══════════════════════════════════════════════╗
║                                              ║
║     🧠 {self.nombre} - Cerebro Artificial
║     🌐 Razonamiento Integrado
║                                              ║
║  ⚡ Ciclos vividos: {self.ciclos_vida:<5} (mentales: {self.edad_mental})
║  📚 Memorias: {len(self.memoria.memorias):<5}
║  📖 Conocimiento: {self.conocimiento.resumen()}
║  🎭 Personalidad: Extroversión={self.emocion.personalidad['extraversion']:.1f}
║  💭 Estado: {self.emocion.expresar_emocion():<30}
║                                              ║
╚══════════════════════════════════════════════╝
        """)

    # --- Ciclo biológico (mantenido de v1.0) ---
    def percibir_mundo(self, estimulo_visual, estimulo_auditivo=None):
        percepcion_visual = self.occipital.ver(estimulo_visual)
        if estimulo_auditivo is not None:
            comprension_semantica = self.temporal.escuchar(estimulo_auditivo)
        else:
            comprension_semantica = np.zeros(32)
        return percepcion_visual, comprension_semantica

    def sentir(self, estimulo_interno=None):
        if estimulo_interno is None:
            estimulo_interno = np.random.randn(32) * 0.1
        valencia = self.emocion.evaluar_situacion(estimulo_interno)
        estado = self.emocion.consultar_estado()
        return estado, valencia

    def pensar(self, percepcion_visual, comprension_semantica, estado_emocional):
        contexto_integrado = self.prefrontal.integrar_informacion(
            percepcion_visual, comprension_semantica, estado_emocional
        )
        recuerdos = self.memoria.recuperar_por_contexto(contexto_integrado[:32])
        impulsos = self.tronco.generar_impulso()
        opciones = self._generar_opciones(impulsos, recuerdos, estado_emocional)
        accion_idx, confianza = self.prefrontal.tomar_decision(opciones, contexto_integrado)
        return accion_idx, confianza, recuerdos, contexto_integrado

    def actuar(self, accion_idx, contexto):
        accion_base = np.zeros(10)
        accion_base[accion_idx] = 1.0
        contexto_motor = contexto[:10] if len(contexto) >= 10 else np.pad(contexto, (0, 10 - len(contexto)))
        accion_refinada = self.cerebelo.refinar_accion(accion_base, contexto_motor)
        if self.prefrontal.inhibir_respuesta(accion_refinada, contexto):
            print(f"[{self.nombre}] Acción inhibida por control ejecutivo")
            return None
        return accion_refinada

    def aprender_experiencia(self, percepcion, emocion, accion, resultado):
        self.memoria.codificar_episodio(percepcion, emocion, accion, resultado)
        if resultado < 0.5:
            self.cerebelo.aprender_de_error(accion, resultado)
        self.tronco.actualizar_homeostasis()
        self.edad_mental += 1
        self.ciclos_vida += 1

    def _generar_opciones(self, impulsos, recuerdos, estado_emocional):
        opciones = []
        for impulso, intensidad in impulsos.items():
            opciones.append(np.random.randn(96) * intensidad)
        if not opciones:
            opciones = [np.random.randn(96) for _ in range(3)]
        return opciones

    def ciclo_completo(self, estimulo_visual, estimulo_auditivo=None):
        print(f"\n{'='*50}")
        print(f"[{self.nombre}] Ciclo mental #{self.edad_mental + 1}")
        print(f"{'='*50}")
        print("\n[1] PERCIBIENDO...")
        vis, sem = self.percibir_mundo(estimulo_visual, estimulo_auditivo)
        print(f"    Visión procesada: {vis[:4]}...")
        print("\n[2] SINTIENDO...")
        estado_emocional, valencia = self.sentir()
        print(f"    Estado emocional: valencia={estado_emocional['valencia']:.2f}, activación={estado_emocional['activacion']:.2f}")
        print("\n[3] PENSANDO...")
        accion_idx, confianza, recuerdos, contexto = self.pensar(vis, sem, estado_emocional)
        print(f"    Recuerdos recuperados: {len(recuerdos)}")
        print("\n[4] ACTUANDO...")
        accion = self.actuar(accion_idx, contexto)
        if accion is not None:
            print(f"    Acción ejecutada: {accion_idx} (confianza: {confianza:.2f})")
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
        print(f"""
        ╔══════════════════════════════════════╗
        ║     ESTADO INTERNO DE {self.nombre}
        ╠══════════════════════════════════════╣
        ║ Edad mental: {self.edad_mental} ciclos
        ║ Ciclos de vida totales: {self.ciclos_vida}
        ║ Memorias episódicas: {len(self.memoria.memorias)}
        ║ Conocimiento: {self.conocimiento.resumen()}
        ║ Objetos reconocidos: {len(self.occipital.memoria_visual)}
        ║ Conceptos semánticos: {len(self.temporal.red_semantica)}
        ╠══════════════════════════════════════╣
        ║ Necesidades:
        ║   Energía: {self.tronco.necesidades['energia']:.2f}
        ║   Seguridad: {self.tronco.necesidades['seguridad']:.2f}
        ║   Curiosidad: {self.tronco.necesidades['curiosidad']:.2f}
        ║   Descanso: {self.tronco.necesidades['descanso']:.2f}
        ╠══════════════════════════════════════╣
        ║ Estado emocional: {self.emocion.expresar_emocion()}
        ╚══════════════════════════════════════╝
        """)

    # --- INTERACCIÓN CONVERSACIONAL MEJORADA (v3.0) ---
    def interactuar(self, mensaje_usuario):
        """Procesa un mensaje y genera respuesta, incluyendo razonamiento"""
        self.ultima_interaccion = datetime.now()
        self.ciclos_vida += 1

        analisis = self.lenguaje.comprender(mensaje_usuario)
        valencia = self.emocion.evaluar(mensaje_usuario, analisis['intencion'])

        # --- PRIORIDAD 1: Detectar enseñanza explícita ---
        if self.lenguaje._es_ensenanza(mensaje_usuario):
            respuesta = self._procesar_ensenanza(mensaje_usuario)
            if respuesta:
                self._registrar_interaccion(mensaje_usuario, respuesta, valencia)
                return respuesta

        # --- PRIORIDAD 2: Buscar en conocimiento explícito ---
        respuesta_conocimiento = self._consultar_conocimiento(analisis, mensaje_usuario)
        if respuesta_conocimiento:
            self._registrar_interaccion(mensaje_usuario, respuesta_conocimiento, valencia)
            return respuesta_conocimiento

        # --- PRIORIDAD 3: Intentar razonamiento ---
        respuesta_razonamiento = self._intentar_razonamiento(analisis, mensaje_usuario)
        if respuesta_razonamiento:
            self._registrar_interaccion(mensaje_usuario, respuesta_razonamiento, valencia)
            return respuesta_razonamiento

        # --- RESPUESTA POR DEFECTO ---
        estimulo_vector = np.random.randn(100) * 0.1
        if analisis['entidades']:
            estimulo_vector[:len(analisis['entidades'])] = [hash(e) % 100 / 100 for e in analisis['entidades']]

        memorias_relevantes = self.memoria.recordar(estimulo_vector, k=3)
        contexto = self.capa_integracion.forward(estimulo_vector)
        decision = self.capa_decision.forward(contexto)
        respuesta_raw = self.capa_respuesta.forward(decision)

        respuesta = self.lenguaje.generar_respuesta(
            analisis,
            {
                'expresion_emocional': self.emocion.expresar_emocion(),
                'valencia': self.emocion.estado['valencia'],
                'activacion': self.emocion.estado['activacion']
            },
            memorias_relevantes
        )

        self.memoria.codificar(estimulo_vector, valencia, contexto, np.mean(respuesta_raw))
        self.emocion.regular()
        self._registrar_interaccion(mensaje_usuario, respuesta, valencia)
        return respuesta

    def _procesar_ensenanza(self, mensaje):
        """Procesa una enseñanza y guarda el conocimiento"""
        ensenanza = self.lenguaje.extraer_ensenanza(mensaje)
        if not ensenanza:
            return "Parece que quieres enseñarme algo, pero no he entendido el formato. Usa 'X es Y', 'X significa Y', 'si X entonces Y', 'causa X efecto Y' o 'plan para X: paso1, paso2'."

        tipo, sujeto, contenido = ensenanza

        if tipo == "hecho" and contenido:
            self.conocimiento.aprender_hecho(sujeto, contenido)
            return f"📚 He aprendido el hecho: '{sujeto}' -> '{contenido}'."

        elif tipo == "definicion" and contenido:
            self.conocimiento.aprender_definicion(sujeto, contenido)
            self.conocimiento.aprender_vocabulario(sujeto)
            return f"📖 Entendido: '{sujeto}' significa '{contenido}'."

        elif tipo == "vocabulario":
            self.conocimiento.aprender_vocabulario(sujeto)
            return f"📝 Nueva palabra añadida: '{sujeto}'."

        elif tipo == "regla" and contenido:
            self.conocimiento.aprender_regla(sujeto, contenido)
            return f"🧠 Regla aprendida: si '{sujeto}' entonces '{contenido}'."

        elif tipo == "causa" and contenido:
            self.conocimiento.aprender_causa(sujeto, contenido)
            return f"🔗 Relación causal: '{sujeto}' causa '{contenido}'."

        elif tipo == "plan" and contenido:
            self.conocimiento.aprender_plan(sujeto, contenido)
            return f"📋 Plan para '{sujeto}' guardado con {len(contenido)} pasos: {', '.join(contenido)}."

        return "No he podido extraer la enseñanza. Prueba con 'X es Y', 'X significa Y', 'si X entonces Y', 'causa X efecto Y' o 'plan para X: paso1, paso2'."

    def _consultar_conocimiento(self, analisis, mensaje_usuario):
        """Busca en la base de conocimiento hechos y definiciones"""
        if analisis['intencion'] == 'pregunta' and analisis['entidades']:
            pregunta = mensaje_usuario.lower()

            # ¿Qué es X? -> definición
            if any(p in pregunta for p in ['qué es', 'que es', 'definición de', 'definicion de', 'significa']):
                for entidad in analisis['entidades']:
                    definicion = self.conocimiento.buscar_definicion(entidad)
                    if definicion:
                        return f"'{entidad}' significa: {definicion}."

            # ¿Cuál es X? -> hecho
            for entidad in analisis['entidades']:
                hecho = self.conocimiento.buscar_hecho(entidad)
                if hecho:
                    return f"Según lo que aprendí, '{entidad}' es {hecho}."

            # Si no encontró nada, buscar definición como fallback
            for entidad in analisis['entidades']:
                definicion = self.conocimiento.buscar_definicion(entidad)
                if definicion:
                    return f"'{entidad}' significa: {definicion}."

        return None

    def _intentar_razonamiento(self, analisis, mensaje_usuario):
        """Intenta usar el motor de razonamiento para responder"""
        if analisis['intencion'] != 'pregunta':
            return None

        pregunta = mensaje_usuario.lower()

        # Detectar peticiones de deducción
        palabras_deduccion = ["deduce", "infiere", "qué conclusión", "que conclusion", "razona sobre"]
        if any(p in pregunta for p in palabras_deduccion):
            sujeto = " ".join(analisis['entidades']) if analisis['entidades'] else pregunta
            conclusiones = self.razonador.deducir(sujeto)
            if conclusiones:
                return f"A partir de '{sujeto}', deduzco: " + ", ".join(conclusiones) + "."
            return "No tengo reglas suficientes para deducir algo de eso. Enséñame reglas con 'si X entonces Y'."

        # Detectar peticiones de predicción causal
        palabras_causales = ["qué pasaría si", "que pasaria si", "qué causa", "que causa", "efecto de", "consecuencia de"]
        if any(p in pregunta for p in palabras_causales):
            sujeto = " ".join(analisis['entidades']) if analisis['entidades'] else pregunta
            efectos, causas = self.razonador.razonar_causalmente(sujeto)
            if efectos:
                return f"Si '{sujeto}', entonces podría causar: " + ", ".join(efectos) + "."
            elif causas:
                return f"Posibles causas de '{sujeto}': " + ", ".join(causas) + "."
            return "No tengo información causal sobre eso. Enséñame con 'causa X efecto Y'."

        # Detectar peticiones de planificación
        palabras_plan = ["cómo hacer", "como hacer", "cómo lograr", "como lograr", "cómo conseguir", "como conseguir",
                         "pasos para", "plan para"]
        if any(p in pregunta for p in palabras_plan):
            meta = " ".join(analisis['entidades']) if analisis['entidades'] else pregunta
            plan = self.razonador.planificar(meta)
            if plan:
                return f"Para '{meta}', los pasos son: " + " → ".join(plan) + "."
            return f"No sé cómo planificar '{meta}'. Enséñame con 'plan para X: paso1, paso2'."

        # Detectar peticiones de analogía
        if " analogía " in pregunta or " analogia " in pregunta or " es como " in pregunta:
            entidades = analisis['entidades']
            if len(entidades) >= 2:
                resultado = self.razonador.razonar_por_analogia(entidades[0], entidades[1],
                                                                entidades[2] if len(entidades) > 2 else "")
                if resultado:
                    return resultado

        return None

    def _registrar_interaccion(self, mensaje, respuesta, valencia):
        """Guarda la interacción en el historial"""
        self.historial_conversacion.append({
            'timestamp': datetime.now().isoformat(),
            'usuario': mensaje,
            'clave': respuesta,
            'emocion': self.emocion.estado.copy()
        })
        if len(self.historial_conversacion) > 200:
            self.historial_conversacion = self.historial_conversacion[-200:]

    def ciclo_autonomo(self):
        if not self.ejecutando:
            return
        pensamiento_interno = np.random.randn(100) * 0.05
        self.capa_integracion.forward(pensamiento_interno)
        memorias = self.memoria.recordar(np.random.randn(100) * 0.1, k=2)
        for mem in memorias:
            mem['fuerza'] *= 1.01
        self.ciclos_vida += 1
        self.emocion.regular()
        self.tronco.actualizar_homeostasis()

    def consolidar_memoria(self):
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] 🧠 Consolidando memorias...")
        self.memoria.consolidar()
        self._guardar_estado()

    def _guardar_estado(self):
        estado = {
            'ciclos_vida': self.ciclos_vida,
            'edad_mental': self.edad_mental,
            'historial_conversacion': self.historial_conversacion,
            'personalidad': self.emocion.personalidad,
            'estado_emocional': dict(self.emocion.estado),
            'necesidades': dict(self.tronco.necesidades),
            'objetos_reconocidos': list(self.occipital.memoria_visual.keys()),
            'conceptos_semanticos': list(self.temporal.red_semantica.keys()),
        }
        archivo = Path(self.config.directorio_memoria) / self.config.archivo_estado
        archivo.parent.mkdir(exist_ok=True)
        with open(archivo, 'wb') as f:
            pickle.dump(estado, f)
        self.memoria.guardar_a_disco()
        print(f"[{datetime.now().strftime('%H:%M:%S')}] 💾 Estado guardado a disco")

    def _cargar_estado(self):
        archivo = Path(self.config.directorio_memoria) / self.config.archivo_estado
        if archivo.exists():
            with open(archivo, 'rb') as f:
                estado = pickle.load(f)
                self.ciclos_vida = estado.get('ciclos_vida', 0)
                self.edad_mental = estado.get('edad_mental', 0)
                self.historial_conversacion = estado.get('historial_conversacion', [])
                if 'personalidad' in estado:
                    self.emocion.personalidad.update(estado['personalidad'])
                if 'estado_emocional' in estado:
                    self.emocion.estado.update(estado['estado_emocional'])
                if 'necesidades' in estado:
                    self.tronco.necesidades.update(estado['necesidades'])
            print(f"[Inicio] Estado previo cargado: {self.ciclos_vida} ciclos vividos")


ClaveV2 = Clave


# ==================================================================
# INTERFAZ INTERACTIVA (ACTUALIZADA v3.0)
# ==================================================================
class InterfazClave:
    """Maneja la interacción entre el usuario y Clave"""

    def __init__(self):
        self.clave = Clave()
        self.ejecutando = True
        self.modo_autonomo = False

    def iniciar(self):
        print("""
╔══════════════════════════════════════════════╗
║  COMANDOS DISPONIBLES:                      ║
║  /estado   - Ver estado interno de Clave    ║
║  /memoria  - Ver estadísticas de memoria    ║
║  /emocion  - Ver estado emocional           ║
║  /conocer  - Ver base de conocimiento       ║
║  /ciclo    - Ejecutar un ciclo biológico    ║
║  /aprender - Enseñar algo a Clave           ║
║  /guardar  - Guardar estado manualmente     ║
║  /auto     - Modo autónomo (Clave piensa)   ║
║  /salir    - Guardar y salir                ║
║  /ayuda    - Mostrar esta ayuda             ║
╚══════════════════════════════════════════════╝
        """)

        hilo_autonomo = threading.Thread(target=self._bucle_autonomo, daemon=True)
        hilo_autonomo.start()
        hilo_guardado = threading.Thread(target=self._bucle_guardado, daemon=True)
        hilo_guardado.start()

        while self.ejecutando:
            try:
                entrada = input("\n👤 Tú: ").strip()
                if not entrada:
                    continue
                if entrada.startswith('/'):
                    self._procesar_comando(entrada)
                else:
                    respuesta = self.clave.interactuar(entrada)
                    print(f"\n🧠 {self.clave.nombre}: {respuesta}")
            except KeyboardInterrupt:
                print("\n\nInterrupción detectada. Guardando estado...")
                self.clave._guardar_estado()
                print("¡Hasta luego!")
                self.ejecutando = False
            except EOFError:
                self.ejecutando = False

    def _procesar_comando(self, comando):
        cmd = comando.lower()
        if cmd == '/estado':
            self._mostrar_estado()
        elif cmd == '/memoria':
            self._mostrar_memoria()
        elif cmd == '/emocion':
            self._mostrar_emocion()
        elif cmd == '/conocer':
            self._mostrar_conocimiento()
        elif cmd.startswith('/aprender'):
            contenido = comando[10:].strip()
            if contenido:
                respuesta = self.clave.interactuar(f"/aprender {contenido}")
                print(f"\n🧠 {self.clave.nombre}: {respuesta}")
            else:
                print("Uso: /aprender <hecho, definición, regla, causa o plan>")
        elif cmd == '/ciclo':
            estimulo_visual = np.random.randn(100)
            estimulo_auditivo = np.random.randn(50)
            self.clave.ciclo_completo(estimulo_visual, estimulo_auditivo)
        elif cmd == '/guardar':
            self.clave._guardar_estado()
            print("✅ Estado guardado manualmente.")
        elif cmd == '/auto':
            self.modo_autonomo = not self.modo_autonomo
            estado = "ACTIVADO" if self.modo_autonomo else "DESACTIVADO"
            print(f"🔄 Modo autónomo {estado}")
        elif cmd == '/salir':
            print("Guardando y saliendo...")
            self.clave._guardar_estado()
            self.ejecutando = False
            print("👋 ¡Hasta pronto!")
        elif cmd.startswith('/leer'):
            archivo = comando[6:].strip()
            if not archivo:
                print("📖 Uso: /leer <archivo.pdf o archivo.txt>")
                print("   El archivo debe estar en la misma carpeta que Clave.")
            elif not os.path.exists(archivo):
                print(f"❌ Archivo no encontrado: '{archivo}'")
                print("   Asegúrate de que el archivo existe y la ruta es correcta.")
            else:
                print(f"\n{'='*50}")
                lector = LectorPDF(self.clave)
                
                if archivo.lower().endswith('.pdf'):
                    exito = lector.leer_pdf(archivo)
                elif archivo.lower().endswith('.txt'):
                    exito = lector.leer_txt(archivo)
                else:
                    print("❌ Formato no soportado. Usa archivos .pdf o .txt")
                    return
                
                if exito:
                    resultado = lector.ensenar_contenido()
                    print(resultado)
                    print(f"{'='*50}")
                else:
                    print("❌ No se pudo procesar el archivo.")

        elif cmd.startswith('/preguntar'):
            tema = comando[11:].strip()
            if tema:
                conocimientos = []
                for clave, valor in self.clave.conocimiento.datos['hechos'].items():
                    if tema.lower() in clave.lower():
                        conocimientos.append(f"• {clave}: {valor}")
                
                if conocimientos:
                    print(f"\n🧠 {self.clave.nombre}: Esto es lo que sé sobre '{tema}':")
                    for c in conocimientos[:20]:
                        print(f"  {c}")
                    if len(conocimientos) > 20:
                        print(f"  ... y {len(conocimientos) - 20} registros más.")
                else:
                    print(f"\n🧠 {self.clave.nombre}: Aún no sé nada sobre '{tema}'.")
                    print("  Usa /aprender para enseñarme o /leer para procesar un archivo.")
            else:
                print("Uso: /preguntar <tema o personaje>")
                print("Ejemplo: /preguntar Martín Fierro")
        elif cmd == '/ayuda':
            print("""
/comandos disponibles:
/estado    - Estado general de Clave
/memoria   - Memorias almacenadas
/emocion   - Estado emocional actual
/conocer   - Base de conocimiento
/aprender  - Enseñar un hecho, regla, causa o plan
/ciclo     - Ejecutar un ciclo biológico completo
/guardar   - Guardar manualmente
/auto      - Activar modo autónomo
/salir     - Salir guardando
/leer      - Lee
/preguntar - Preguntar
            """)

    def _mostrar_estado(self):
        c = self.clave
        print(f"""
┌──────────────────────────────────────────────┐
│        ESTADO DE {c.nombre}
├──────────────────────────────────────────────┤
│ 🕐 Ciclos de vida: {c.ciclos_vida}
│ 🧬 Edad mental: {c.edad_mental}
│ 📚 Memorias totales: {len(c.memoria.memorias)}
│ 💬 Conversaciones: {len(c.historial_conversacion)}
│ 📖 Conocimiento: {c.conocimiento.resumen()}
│ 💭 Estado emocional: {c.emocion.expresar_emocion()}
│ 🎯 Personalidad:
│   Extroversión: {c.emocion.personalidad['extraversion']:.2f}
│   Apertura: {c.emocion.personalidad['apertura']:.2f}
│   Neuroticismo: {c.emocion.personalidad['neuroticismo']:.2f}
└──────────────────────────────────────────────┘
        """)

    def _mostrar_memoria(self):
        mem = self.clave.memoria
        print(f"""
📚 MEMORIA DE CLAVE:
   Total memorias: {len(mem.memorias)}
   Índice actual: {mem.indice}
   Capacidad máxima: {mem.capacidad}
   Últimas 3 memorias:
""")
        for m in mem.memorias[-3:]:
            print(f"   - [{m['timestamp'][:19]}] Etiquetas: {m.get('etiquetas', [])} | Fuerza: {m['fuerza']:.2f}")

    def _mostrar_emocion(self):
        e = self.clave.emocion.estado
        print(f"""
💭 ESTADO EMOCIONAL:
   Valencia: {'🟢' if e['valencia'] > 0 else '🔴'} {e['valencia']:.2f}
   Activación: {'⚡' if e['activacion'] > 0.5 else '😴'} {e['activacion']:.2f}
   Dominancia: {'👑' if e['dominancia'] > 0.5 else '🤝'} {e['dominancia']:.2f}
   Expresión: {self.clave.emocion.expresar_emocion()}
        """)

    def _mostrar_conocimiento(self):
        c = self.clave.conocimiento
        print(f"""
📖 BASE DE CONOCIMIENTO:
   {c.resumen()}

   Hechos:
""")
        for k, v in list(c.datos['hechos'].items())[:10]:
            print(f"   - {k}: {v}")
        print("\n   Definiciones:")
        for k, v in list(c.datos['definiciones'].items())[:10]:
            print(f"   - {k}: {v}")
        print("\n   Reglas lógicas:")
        for r in c.datos['reglas'][:10]:
            print(f"   - SI {r['si']} ENTONCES {r['entonces']}")
        print("\n   Causas:")
        for k, v in list(c.datos['causas'].items())[:10]:
            print(f"   - {k} -> {v}")
        print("\n   Planes:")
        for k, v in list(c.datos['planes'].items())[:10]:
            print(f"   - {k}: {v}")

    def _bucle_autonomo(self):
        while self.ejecutando:
            time.sleep(1.0 / self.clave.config.ciclos_por_segundo)
            self.clave.ciclo_autonomo()
            if self.modo_autonomo and self.clave.ciclos_vida % 10 == 0:
                pensamiento = self.clave.lenguaje.generar_respuesta(
                    {'intencion': 'declaracion', 'entidades': ['pensamiento', 'autonomo']},
                    {'expresion_emocional': self.clave.emocion.expresar_emocion()},
                    self.clave.memoria.recordar(np.random.randn(100) * 0.1, k=1)
                )
                print(f"\n💭 [Pensamiento autónomo]: {pensamiento}")

    def _bucle_guardado(self):
        while self.ejecutando:
            time.sleep(self.clave.config.intervalo_guardado)
            if self.clave.ultima_interaccion:
                tiempo_sin_interaccion = (datetime.now() - self.clave.ultima_interaccion).seconds
                if tiempo_sin_interaccion > 30:
                    self.clave._guardar_estado()


# ==================================================================
# DEMOSTRACIÓN Y PUNTO DE ENTRADA
# ==================================================================
def demo_autonoma():
    clave = Clave(nombre="Clave v3.0")
    print("\n[ENTRENAMIENTO] Enseñando a Clave a reconocer objetos...")
    for i in range(5):
        clave.occipital.aprender_objeto(f"objeto_{i}", np.random.randn(100))
    print("\n[ENTRENAMIENTO] Enseñando conceptos semánticos...")
    for concepto in ['peligro', 'seguro', 'interesante', 'aburrido']:
        clave.temporal.asociar_concepto(concepto, np.random.randn(32))
    print("\n" + "="*60)
    print("CLAVE EN FUNCIONAMIENTO (modo autónomo)")
    print("="*60)
    for ciclo in range(3):
        clave.ciclo_completo(np.random.randn(100), np.random.randn(50))
        if ciclo % 2 == 0:
            clave.reporte_estado()
    clave._guardar_estado()
    print(f"\n[FIN] Clave ha completado {clave.edad_mental} ciclos de experiencia.")


def demo_interactiva():
    print("""
    ╔══════════════════════════════════════════════╗
    ║   🧠 CLAVE v3.0 - Cerebro Artificial        ║
    ║   Biológico | Memoria | Razonamiento        ║
    ╚══════════════════════════════════════════════╝
    """)
    interfaz = InterfazClave()
    try:
        interfaz.iniciar()
    except Exception as e:
        print(f"\n⚠️ Error inesperado: {e}")
        print("Guardando estado de emergencia...")
        if hasattr(interfaz, 'clave'):
            interfaz.clave._guardar_estado()
        print("Clave se ha cerrado. Sus recuerdos están a salvo.")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] in ('--auto', '--demo', '-a'):
        demo_autonoma()
    else:
        demo_interactiva()