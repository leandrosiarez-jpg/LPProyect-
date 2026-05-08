# clave_definitiva.py - VERSIÓN ACTUALIZADA con IA local completa

from escaner import EscanerRed
from voz import SistemaVoz
from exportador import Exportador
from interfaz import Interfaz
from memoria import Memoria
from nlp_local import ClasificadorNLP
from reglas import SistemaDecision

class CLAVE:
    def __init__(self):
        self.escaner     = EscanerRed()
        self.voz         = SistemaVoz()
        self.exportador  = Exportador()
        self.memoria     = Memoria()             # ← Fase 1
        self.nlp         = ClasificadorNLP()     # ← Fase 2
        self.decision    = SistemaDecision()     # ← Fases 3 y 4
        self.interfaz    = None
        self.version     = "IA LOCAL 2.0"
    
    def iniciar(self):
        print("=" * 70)
        print("🧠 C.L.A.V.E. - IA Local v2.0")
        print("=" * 70)
        
        # Mostrar resumen de la sesión anterior
        resumen = self.memoria.resumen_sesion_anterior()
        if resumen:
            print(resumen)
        
        # Modo NLP: el usuario puede escribir en lenguaje natural
        print("\n💬 Modo lenguaje natural activado.")
        print("   Podés escribir 'escanear la red' en vez de 'scan'")
        print("   Escribí 'debug_nlp on' para ver qué entiende la IA")
        
        self.voz.decir("C L A V E versión I A local iniciada")
        
        self.interfaz = Interfaz(self)
        self.interfaz.iniciar()
    
    def procesar_input_libre(self, texto: str, debug: bool = False) -> tuple:
        """
        Intenta interpretar texto libre con el NLP.
        Devuelve (comando, args) o (None, []) si no entiende.
        """
        return self.nlp.procesar_input(texto, modo_debug=debug)
    
    def cerrar(self):
        self.memoria.cerrar_sesion()
        self.voz.decir("Cerrando C L A V E")
        print("👋 C.L.A.V.E. cerrada")

if __name__ == "__main__":
    clave = CLAVE()
    clave.iniciar()