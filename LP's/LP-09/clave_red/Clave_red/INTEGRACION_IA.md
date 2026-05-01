# ─────────────────────────────────────────────────────────────
#  INSTRUCCIONES DE INTEGRACIÓN DEL MÓDULO IA EN C.L.A.V.E.
# ─────────────────────────────────────────────────────────────
#
# PASO 1 — Instalar la librería de Anthropic
#   pip install anthropic
#
# PASO 2 — Crear el archivo .env en la misma carpeta del proyecto
#   Contenido del .env:
#   ANTHROPIC_API_KEY=sk-ant-PEGA_TU_KEY_AQUI
#
#   Para obtener tu API key:
#   → Entrá a https://console.anthropic.com/
#   → Creá una cuenta o iniciá sesión
#   → Menú "API Keys" → "Create Key"
#   → Copiá la key y pegala en el .env
#
# PASO 3 — Copiar ia.py a la carpeta del proyecto
#   (junto a escaner.py, voz.py, etc.)
#
# PASO 4 — Modificar clave_definitiva.py
#   Agregá estas líneas:
#
#   from ia import AnalistaIA          ← en los imports del principio
#
#   En __init__ de la clase CLAVE:
#   self.ia = AnalistaIA()             ← después de self.exportador = Exportador()
#
#   En self.comandos (el diccionario):
#   "informe_ia": "Generar informe IA del último escaneo",
#   "preguntar":  "Hacerle una pregunta a la IA sobre la red (ej: preguntar qué IP es más sospechosa)",
#
# PASO 5 — Modificar interfaz.py
#   En el método ejecutar_comando(), antes del else final, agregá:
#
#   elif comando == "informe_ia":
#       self.comando_informe_ia()
#   elif comando == "preguntar":
#       pregunta = " ".join(args) if args else ""
#       if pregunta:
#           respuesta = self.clave.ia.hacer_pregunta(
#               pregunta,
#               self.clave.escaner.ultimos_resultados
#           )
#           print(f"\n🤖 IA:\n{respuesta}")
#       else:
#           print("Uso: preguntar <tu pregunta>  ej: preguntar cuál IP tiene más riesgo")
#
#   Agregá este nuevo método en la clase Interfaz:
#
#   def comando_informe_ia(self):
#       if not self.clave.escaner.ultimos_resultados:
#           print("Ejecutá 'scan' primero para tener datos que analizar")
#           return
#       # Obtener análisis neuronal si está disponible
#       resultados_neuro = None
#       try:
#           resultados_neuro = self.clave.escaner.cerebro.analizar_red(
#               self.clave.escaner.ultimos_resultados
#           )
#       except Exception:
#           pass
#       informe = self.clave.ia.generar_informe(
#           self.clave.escaner.ultimos_resultados,
#           resultados_neuro
#       )
#       print("\n" + "=" * 70)
#       print("🤖 INFORME DE SEGURIDAD — ANÁLISIS IA")
#       print("=" * 70)
#       print(informe)
#       print("=" * 70)
#       self.clave.voz.decir("Informe de inteligencia artificial generado")
#
# PASO 6 — (Opcional) Auto-informe después de cada scan
#   En interfaz.py, al final del método comando_scan():
#   Reemplazá la última línea por:
#
#   self.clave.exportador.exportar_json(resultados)
#   if self.clave.ia.disponible:           ← agregar esto
#       self.comando_informe_ia()          ← y esto
#
# ─────────────────────────────────────────────────────────────
#  RESUMEN DE NUEVOS COMANDOS DISPONIBLES
# ─────────────────────────────────────────────────────────────
#  informe_ia  → Análisis completo en lenguaje natural
#  preguntar   → Pregunta libre sobre los datos del escaneo
#               Ejemplos:
#               preguntar cuál es el dispositivo más peligroso
#               preguntar hay algún router expuesto
#               preguntar qué fabricantes desconozco
# ─────────────────────────────────────────────────────────────
