"""
CLAVE - Voz

CLAVE solo existe hablando. Este módulo maneja:
- Síntesis de voz (TTS) en español
- Reconocimiento de voz (STT) en español

Estrategia de fallback automática:
  TTS: pyttsx3 → gTTS → solo texto
  STT: SpeechRecognition (Google) → Vosk (offline) → solo texto
"""

import os
import sys
import threading
import queue
import time
import json
from typing import Optional, Callable, Any


# ─── TTS (Text-to-Speech) ─────────────────────────────────────────────────────

class VozSalida:
    """
    Motor de síntesis de voz para CLAVE.
    Habla siempre en español.
    """

    def __init__(self, log_fn: Optional[Callable] = None):
        self._log = log_fn or print
        self._motor = None
        self._cola = queue.Queue()
        self._activo = True
        self._inicializar()
        self._hilo = threading.Thread(target=self._worker, daemon=True)
        self._hilo.start()

    def _inicializar(self):
        """Intenta inicializar pyttsx3 primero, luego gTTS."""
        try:
            import pyttsx3
            motor = pyttsx3.init()
            # Configurar voz en español
            voices = motor.getProperty('voices')
            voz_es = None
            for v in voices:
                if 'spanish' in v.name.lower() or 'es' in v.id.lower() or 'español' in v.name.lower():
                    voz_es = v.id
                    break
            if voz_es:
                motor.setProperty('voice', voz_es)
            motor.setProperty('rate', 165)
            motor.setProperty('volume', 0.95)
            self._motor = ('pyttsx3', motor)
            self._log("[VOZ] Motor: pyttsx3")
            return
        except Exception:
            pass

        try:
            from gtts import gTTS
            import pygame
            pygame.mixer.init()
            self._motor = ('gtts', None)
            self._log("[VOZ] Motor: gTTS + pygame")
            return
        except Exception:
            pass

        self._motor = ('texto', None)
        self._log("[VOZ] Sin motor de voz. Solo texto.")

    def hablar(self, texto: str):
        """Agrega texto a la cola de voz."""
        if texto.strip():
            self._cola.put(texto.strip())

    def _worker(self):
        """Hilo que procesa la cola de voz."""
        while self._activo:
            try:
                texto = self._cola.get(timeout=0.5)
                self._sintetizar(texto)
            except queue.Empty:
                continue

    def _sintetizar(self, texto: str) -> None:
        tipo, motor = self._motor

        if tipo == 'pyttsx3' and motor is not None:
            try:
                motor.say(texto)
                motor.runAndWait()
            except Exception as e:
                self._log(f"[VOZ] Error pyttsx3: {e}")

        elif tipo == 'gtts':
            try:
                from gtts import gTTS
                import pygame
                import tempfile
                tts = gTTS(text=texto, lang='es', slow=False)
                with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as f:
                    nombre = f.name
                tts.save(nombre)
                pygame.mixer.music.load(nombre)
                pygame.mixer.music.play()
                while pygame.mixer.music.get_busy():
                    time.sleep(0.05)
                os.unlink(nombre)
            except Exception as e:
                self._log(f"[VOZ] Error gTTS: {e}")

        # 'texto': no hace nada (ya se mostró por log)

    def desactivar(self):
        """Desactiva la síntesis de voz sin detener el hilo."""
        self._motor = ('texto', None)

    def detener(self):
        self._activo = False
        if self._motor and self._motor[0] == 'pyttsx3':
            try:
                self._motor[1].stop()
            except Exception:
                pass


# ─── STT (Speech-to-Text) ─────────────────────────────────────────────────────

class VozEntrada:
    """
    Motor de reconocimiento de voz para CLAVE.
    Escucha en español.
    """

    def __init__(self, log_fn: Optional[Callable] = None):
        self._log = log_fn or print
        self._motor = None
        self._reconocedor = None
        self._micro = None
        self._inicializar()

    def _inicializar(self):
        """Intenta inicializar SpeechRecognition."""
        try:
            import speech_recognition as sr
            self._reconocedor = sr.Recognizer()
            self._reconocedor.energy_threshold = 300
            self._reconocedor.pause_threshold = 0.8
            self._reconocedor.dynamic_energy_threshold = True
            self._motor = 'sr'
            self._log("[OÍDO] Motor: SpeechRecognition")
        except ImportError:
            self._motor = 'texto'
            self._log("[OÍDO] Sin reconocimiento de voz. Modo texto.")

    def escuchar(self, timeout: float = 5.0) -> Optional[str]:
        """
        Escucha del micrófono y retorna texto, o None si no captó nada.
        """
        if self._motor == 'texto':
            return None

        audio = None
        try:
            import speech_recognition as sr
            with sr.Microphone() as fuente:  # type: ignore
                self._log("[OÍDO] Escuchando...")
                self._reconocedor.adjust_for_ambient_noise(fuente, duration=0.3)
                audio = self._reconocedor.listen(fuente, timeout=timeout, phrase_time_limit=int(15))

        except Exception as e:
            self._log(f"[OÍDO] Error capturando audio: {e}")
            return None

        if audio is None:
            return None

        # Intentar reconocimiento
        try:
            import speech_recognition as sr
            texto = self._reconocedor.recognize_google(audio, language="es-ES")
            self._log(f"[OÍDO] Captado: {texto}")
            return texto
        except Exception as e_sr:  # type: ignore
            import speech_recognition as sr
            if isinstance(e_sr, sr.UnknownValueError):  # type: ignore
                return None
            elif isinstance(e_sr, sr.RequestError):  # type: ignore
                # Sin internet: intentar Vosk offline
                return self._reconocer_vosk(audio)
            else:
                self._log(f"[OÍDO] Error de reconocimiento: {e_sr}")
                return None

    def _reconocer_vosk(self, audio: Any) -> Optional[str]:
        """Fallback offline con Vosk."""
        try:
            from vosk import Model, KaldiRecognizer
            modelo_path = "modelos/vosk-es"
            if not os.path.exists(modelo_path):
                return None
            modelo = Model(modelo_path)
            rec = KaldiRecognizer(modelo, 16000)
            datos = audio.get_wav_data(convert_rate=16000, convert_width=2)
            rec.AcceptWaveform(datos)
            resultado = json.loads(rec.Result())
            return resultado.get("text") or None
        except Exception:
            return None

    def tiene_microfono(self) -> bool:
        return self._motor == 'sr'


# ─── Motor de voz unificado ───────────────────────────────────────────────────

class MotorVoz:
    """
    Interfaz unificada de voz para CLAVE.
    Combina entrada y salida.
    """

    def __init__(self, log_fn: Optional[Callable] = None):
        self._log = log_fn or print
        self.salida = VozSalida(log_fn=self._log)
        self.entrada = VozEntrada(log_fn=self._log)
        self.modo_voz = self.entrada.tiene_microfono()

    def hablar(self, texto: str):
        """CLAVE habla el texto dado."""
        self.salida.hablar(texto)

    def escuchar(self, timeout: float = 5.0) -> Optional[str]:
        """Escucha del micrófono. Retorna texto o None."""
        return self.entrada.escuchar(timeout)

    def detener(self):
        self.salida.detener()
