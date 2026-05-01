# ia.py - Módulo de Inteligencia Artificial para C.L.A.V.E.
# Genera informes en lenguaje natural usando la API de Anthropic (Claude)
#
# INSTALACIÓN:
#   pip install anthropic
#
# CONFIGURACIÓN:
#   Crear archivo .env en la carpeta del proyecto con:
#   ANTHROPIC_API_KEY=sk-ant-...
#   O bien setear la variable de entorno antes de ejecutar:
#   Windows:  set ANTHROPIC_API_KEY=sk-ant-...
#   Linux/Mac: export ANTHROPIC_API_KEY=sk-ant-...

import os
import json
from datetime import datetime

try:
    import anthropic
    ANTHROPIC_DISPONIBLE = True
except ImportError:
    ANTHROPIC_DISPONIBLE = False

# Intentar cargar .env si existe (sin requerir python-dotenv)
def _cargar_env():
    ruta_env = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(ruta_env):
        with open(ruta_env, "r", encoding="utf-8") as f:
            for linea in f:
                linea = linea.strip()
                if linea and not linea.startswith("#") and "=" in linea:
                    clave, valor = linea.split("=", 1)
                    os.environ.setdefault(clave.strip(), valor.strip())

_cargar_env()


class AnalistaIA:
    """
    Módulo de IA para C.L.A.V.E.
    Analiza los resultados del escaneo y genera un informe en lenguaje natural.
    """

    MODELO = "claude-sonnet-4-20250514"

    # Prompt del sistema: define el rol y el contexto de C.L.A.V.E.
    SYSTEM_PROMPT = """Sos el módulo de análisis de seguridad de C.L.A.V.E. 
(Conciencia Lógica Autónoma de Visión y Exploración), una herramienta de 
escaneo de redes desarrollada en Python.

Tu rol es analizar los resultados crudos de un escaneo de red y producir 
un informe claro, útil y accionable en español. 

Tus informes deben:
- Ser directos y sin rodeos, con lenguaje técnico pero comprensible
- Identificar los dispositivos más sospechosos o riesgosos primero
- Destacar puertos peligrosos (21 FTP, 23 Telnet, 445 SMB, 3389 RDP, 5900 VNC)
- Mencionar fabricantes desconocidos como señal de alerta
- Dar recomendaciones concretas y priorizadas (qué hacer primero)
- Usar emojis para facilitar la lectura visual (🔴 crítico, 🟠 alto, 🟡 medio, 🟢 bajo)
- Terminar con un resumen ejecutivo de 2-3 líneas

Formato del informe:
1. Resumen rápido de la red
2. Dispositivos de atención prioritaria (si los hay)
3. Observaciones generales
4. Recomendaciones priorizadas
5. Resumen ejecutivo

Si no hay nada preocupante, decirlo claramente también es valioso.
Sé conciso: el informe no debe superar los 400 tokens."""

    def __init__(self):
        self.disponible = False
        self.cliente = None
        self._inicializar()

    def _inicializar(self):
        if not ANTHROPIC_DISPONIBLE:
            print("⚠️  Módulo IA: 'anthropic' no instalado.")
            print("   Ejecutá: pip install anthropic")
            return

        api_key = os.environ.get("ANTHROPIC_API_KEY", "")
        if not api_key or api_key == "sk-ant-PEGA_TU_KEY_AQUI":
            print("⚠️  Módulo IA: API key de Anthropic no configurada.")
            print("   Creá un archivo .env con: ANTHROPIC_API_KEY=sk-ant-...")
            print("   O conseguí tu key en: https://console.anthropic.com/")
            return

        try:
            self.cliente = anthropic.Anthropic(api_key=api_key)
            self.disponible = True
            print("🤖 Módulo IA (Claude) inicializado correctamente")
        except Exception as e:
            print(f"⚠️  Error al inicializar módulo IA: {e}")

    def _preparar_contexto(self, dispositivos: list, resultados_neuronales: list = None) -> str:
        """
        Convierte los datos del escaneo en un texto estructurado
        para enviar a la API.
        """
        resumen = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "total_dispositivos": len(dispositivos),
            "dispositivos": []
        }

        # Mapa de resultados neuronales por IP (si los hay)
        mapa_neuro = {}
        if resultados_neuronales:
            for r in resultados_neuronales:
                mapa_neuro[r.get("ip")] = r

        for d in dispositivos:
            ip = d.get("ip", "N/A")
            entrada = {
                "ip": ip,
                "nombre": d.get("nombre", "Desconocido"),
                "mac": d.get("mac", "No disponible"),
                "fabricante": d.get("fabricante", "Desconocido"),
                "sistema_operativo": d.get("sistema_operativo", "Desconocido"),
                "puertos_abiertos": [
                    f"{p['puerto']}/{p['servicio']}" for p in d.get("puertos", [])
                ]
            }

            # Agregar análisis neuronal si está disponible
            if ip in mapa_neuro:
                n = mapa_neuro[ip]
                entrada["riesgo_neuronal"] = f"{n.get('riesgo', 0):.0%}"
                entrada["etiqueta_riesgo"] = n.get("etiqueta", "BAJO")
                entrada["explicacion_neuronal"] = n.get("explicacion", [])

            resumen["dispositivos"].append(entrada)

        return json.dumps(resumen, ensure_ascii=False, indent=2)

    def generar_informe(self, dispositivos: list, resultados_neuronales: list = None) -> str:
        """
        Genera un informe en lenguaje natural para los dispositivos escaneados.
        Devuelve el texto del informe, o un mensaje de error si no está disponible.
        """
        if not self.disponible:
            return "❌ Módulo IA no disponible. Verificá la instalación y la API key."

        if not dispositivos:
            return "ℹ️  No hay dispositivos para analizar."

        print("\n🤖 Analizando red con IA... ", end="", flush=True)

        contexto = self._preparar_contexto(dispositivos, resultados_neuronales)

        mensaje_usuario = f"""Analizá los siguientes resultados de escaneo de red y generá un informe de seguridad:

{contexto}"""

        try:
            respuesta = self.cliente.messages.create(
                model=self.MODELO,
                max_tokens=600,
                system=self.SYSTEM_PROMPT,
                messages=[
                    {"role": "user", "content": mensaje_usuario}
                ]
            )

            informe = respuesta.content[0].text
            print("✅ listo\n")
            return informe

        except anthropic.AuthenticationError:
            return "❌ Error de autenticación: verificá tu API key en el archivo .env"
        except anthropic.RateLimitError:
            return "⚠️  Límite de uso de la API alcanzado. Intentá en unos minutos."
        except anthropic.APIConnectionError:
            return "❌ Sin conexión a la API de Anthropic. Verificá tu conexión a internet."
        except Exception as e:
            return f"❌ Error al generar informe IA: {e}"

    def hacer_pregunta(self, pregunta: str, dispositivos: list, resultados_neuronales: list = None) -> str:
        """
        Permite hacer una pregunta específica sobre los datos del escaneo.
        Útil para el comando 'preguntar' en la interfaz.
        """
        if not self.disponible:
            return "❌ Módulo IA no disponible."

        if not dispositivos:
            return "ℹ️  No hay datos de escaneo. Ejecutá 'scan' primero."

        contexto = self._preparar_contexto(dispositivos, resultados_neuronales)

        mensaje = f"""Tenés estos datos de la red escaneada:

{contexto}

Pregunta del usuario: {pregunta}

Respondé de forma directa y concisa en español, basándote solo en los datos proporcionados."""

        try:
            respuesta = self.cliente.messages.create(
                model=self.MODELO,
                max_tokens=400,
                system=self.SYSTEM_PROMPT,
                messages=[
                    {"role": "user", "content": mensaje}
                ]
            )
            return respuesta.content[0].text

        except Exception as e:
            return f"❌ Error: {e}"