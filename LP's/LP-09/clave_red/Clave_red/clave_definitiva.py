# clave_definitiva.py - C.L.A.V.E. EDICIÓN DEFINITIVA
# Ejecutar este archivo para iniciar C.L.A.V.E.

from escaner import EscanerRed
from voz import SistemaVoz
from exportador import Exportador
from interfaz import Interfaz
import time

class CLAVE:
    def __init__(self):
        self.escaner = EscanerRed()
        self.voz = SistemaVoz()
        self.exportador = Exportador()
        self.interfaz = None
        self.version = "DEFINITIVA 1.0"
        self.comandos = {
            "scan": "Escanear toda la red",
            "scan_rapido": "Escanear rápido (solo ping)",
            "scan_profundo": "Escanear + puertos + MAC",
            "scan_rango": "Escanear rango específico (ej: scan_rango 10.160.7.1 10.160.7.50)",
            "info": "Info detallada de un IP",
            "puertos": "Escanear puertos de un IP",
            "mac": "Obtener MAC y fabricante de un IP",
            "ping": "Hacer ping a un IP",
            "todos_puertos": "Escanear TODOS los puertos (65535) de un IP",
            "gateway": "Mostrar gateway predeterminado",
            "mi_ip": "Mostrar mi IP local",
            "iptype": "Detectar tipo de red (pública/privada)",
            "so": "Intentar detectar sistema operativo",
            "dispositivos_tipo": "Filtrar por tipo de dispositivo",
            "export_json": "Exportar resultados a JSON",
            "export_csv": "Exportar a CSV",
            "export_txt": "Exportar a TXT",
            "ver_historial": "Ver escaneos anteriores guardados",
            "comparar": "Comparar dos escaneos (ver nuevos/desaparecidos)",
            "monitorear": "Monitorear red continuamente (cada X segundos)",
            "watch": "Observar si un IP específico aparece/desaparece",
            "scan_wifi": "Escanear redes WiFi cercanas",
            "conectar_wifi": "Conectarse a una red WiFi (con contraseña)",
            "dispositivos_por_fabricante": "Listar dispositivos por fabricante",
            "top_10_puertos": "Mostrar puertos más comunes en la red",
            "analizar": "Análisis completo de seguridad",
            "informe": "Generar informe detallado HTML",
            "ayuda": "Mostrar todos los comandos",
            "salir": "Cerrar C.L.A.V.E."
        }
    
    def iniciar(self):
        print("=" * 70)
        print(f"🧠 C.L.A.V.E. - Conciencia Lógica Autónoma de Visión y Exploración")
        print(f"📡 Versión {self.version} - Scanner de Red Definitivo")
        print("=" * 70)
        print("\n💡 Escribí 'ayuda' para ver TODOS los comandos disponibles")
        print("💬 C.L.A.V.E. puede hablar. Escribí 'voz_on' o 'voz_off' para controlar")
        print("-" * 70)
        
        self.voz.decir("C L A V E versión definitiva iniciada")
        
        self.interfaz = Interfaz(self)
        self.interfaz.iniciar()

if __name__ == "__main__":
    clave = CLAVE()
    clave.iniciar()