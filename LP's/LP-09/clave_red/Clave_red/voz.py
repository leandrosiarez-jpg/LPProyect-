# voz.py - Sistema de voz de C.L.A.V.E.

import pyttsx3
import threading

class SistemaVoz:
    def __init__(self):
        self.engine = None
        self.activo = True
        self._inicializar()
    
    def _inicializar(self):
        try:
            self.engine = pyttsx3.init()
            
            # Configurar velocidad y volumen
            self.engine.setProperty('rate', 145)
            self.engine.setProperty('volume', 0.9)
            
            # Buscar voz en español
            voices = self.engine.getProperty('voices')
            for voice in voices:
                if 'spanish' in voice.name.lower() or 'es' in str(voice.languages).lower() or 'zira' in voice.name.lower():
                    self.engine.setProperty('voice', voice.id)
                    break
            
            print("🗣️ Sistema de voz inicializado")
        except Exception as e:
            print(f"⚠️ Error al inicializar voz: {e}")
            self.engine = None
    
    def decir(self, texto):
        """Convierte texto a voz en un hilo separado"""
        if not self.activo or not self.engine or not texto:
            print(f"📝 C.L.A.V.E. (texto): {texto}")
            return
        
        def hablar():
            try:
                print(f"🗣️ C.L.A.V.E.: {texto}")
                self.engine.say(texto)
                self.engine.runAndWait()
            except:
                pass
        
        hilo = threading.Thread(target=hablar)
        hilo.daemon = True
        hilo.start()
    
    def activar(self):
        self.activo = True
        self.decir("Voz activada")
    
    def desactivar(self):
        self.activo = False
        if self.engine:
            self.engine.stop()
        print("🔇 Voz desactivada")
    
    def cambiar_velocidad(self, velocidad):
        """Cambia velocidad de voz (100-200)"""
        if self.engine:
            self.engine.setProperty('rate', velocidad)
            self.decir(f"Velocidad cambiada a {velocidad}")