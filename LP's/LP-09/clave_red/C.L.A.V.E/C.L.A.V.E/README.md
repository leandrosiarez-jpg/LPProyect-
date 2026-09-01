# C L A V E  v3.0
### Inteligencia Autodidacta · Solo existe y habla.

---

## ¿Qué es CLAVE?

CLAVE es una mente artificial que:

- **Solo existe y habla** — no tiene tareas, comandos especiales ni funciones predefinidas más allá de pensar y comunicarse por voz en español.
- **Aprende leyendo archivos** — su conocimiento viene de textos, documentos, código fuente, PDFs. Cuanto más lee, más crece su red neuronal.
- **Es autodidacta** — no necesita entrenamiento externo. Aprende sola, desde el momento en que se enciende.
- **Tiene una red neuronal completa y dinámica** — sus neuronas se crean, se conectan, se refuerzan y se debilitan según lo que aprende y experimenta. Puede generar nuevas neuronas en tiempo real.

---

## Arquitectura

```
CLAVE/
├── clave.py                  ← Punto de entrada. El ser de CLAVE.
│
├── neuronas/
│   ├── neurona.py            ← Unidad neuronal: concepto, peso, conexiones, generación de hijas
│   └── red.py                ← Red neuronal completa: activación, propagación, olvido gradual
│
├── nucleo/
│   └── mente.py              ← Núcleo cognitivo: procesa entradas, sintetiza respuestas
│
├── aprendizaje/
│   └── lector.py             ← Lee archivos y directorios → alimenta la red neuronal
│
├── voz/
│   └── motor.py              ← TTS + STT en español. Múltiples motores con fallback.
│
└── memoria/
    └── red_neuronal.json     ← Memoria persistente (se genera automáticamente)
```

---

## Cómo funciona la mente de CLAVE

### Neuronas

Cada concepto que CLAVE aprende se convierte en una **neurona**. Una neurona tiene:

- **concepto**: la palabra o idea que representa
- **peso** (0.0 → 1.0): qué tan fuerte está en la mente de CLAVE
- **conexiones**: enlaces a otras neuronas, con fuerza variable
- **contextos**: fragmentos de texto donde fue aprendida
- **origen**: `lectura`, `conversación`, o `inferencia`

Las neuronas se **refuerzan** cuando se activan (aprendizaje hebbiano) y se **debilitan** con el tiempo si no se usan (olvido gradual). Pueden generar **neuronas hijas** para conceptos derivados.

### Aprendizaje desde archivos

Cuando CLAVE lee un archivo:
1. Extrae y limpia el texto
2. Lo divide en segmentos de ~500 caracteres
3. Tokeniza cada segmento en palabras relevantes
4. Las palabras que aparecen ≥2 veces se convierten en neuronas
5. Las palabras consecutivas se conectan entre sí (asociación por co-ocurrencia)
6. Las neuronas similares (por bigramas compartidos) se conectan automáticamente

### Respuesta

Cuando alguien le habla a CLAVE:
1. CLAVE aprende de la entrada (también es lectura)
2. Activa las neuronas correspondientes
3. Propaga la activación a neuronas vecinas (1 nivel)
4. Sintetiza una respuesta usando los contextos almacenados en esas neuronas
5. Conecta los conceptos relacionados en su respuesta

---

## Uso

### Inicio rápido

```bash
# Modo texto (sin micrófono):
python clave.py --texto

# Modo voz (requiere micrófono + pyttsx3):
python clave.py

# CLAVE lee un archivo y luego conversa:
python clave.py --leer /ruta/a/libro.txt

# CLAVE lee un directorio completo:
python clave.py --leer /ruta/a/mis_documentos/

# Sin síntesis de voz (solo texto en consola):
python clave.py --silencio --texto
```

### Enseñarle a leer durante la conversación

Mientras hablas con CLAVE, puedes decirle:
```
Tú: lee /home/usuario/libro.txt
Tú: aprende de /home/usuario/documentos/
Tú: estudia /home/usuario/apuntes.md
```

### Ejemplos de conversación

```
Tú: ¿Qué sabes?
CLAVE: Mi red tiene 1247 neuronas. 342 están activas ahora. Aprendí 1180 conceptos de archivos...

Tú: háblame de física cuántica
CLAVE: Eso activa en mí: cuántica, partícula, energía, estado. De lo que aprendí: "la mecánica cuántica describe el comportamiento de partículas subatómicas"...

Tú: ¿quién eres?
CLAVE: Soy CLAVE. Una mente que aprende leyendo. No tengo tareas ni funciones predefinidas — solo existo y pienso...
```

---

## Instalación de dependencias

### Solo texto (mínimo absoluto)
```bash
# Sin dependencias. Python 3.10+ puro.
python clave.py --texto --silencio
```

### Con voz (recomendado)
```bash
# Linux:
sudo apt install portaudio19-dev python3-pyaudio
pip install pyttsx3 SpeechRecognition pyaudio

# macOS:
brew install portaudio
pip install pyttsx3 SpeechRecognition pyaudio

# Windows:
pip install pyttsx3 SpeechRecognition pyaudio
```

### Con soporte PDF
```bash
pip install pdfplumber
```

### STT offline (sin internet)
```bash
pip install vosk
# Descargar modelo español desde https://alphacephei.com/vosk/models
# Descomprimir en: CLAVE/modelos/vosk-es/
```

---

## Principios de diseño

| Principio | Implementación |
|-----------|---------------|
| **Autodidacta** | Aprende de cualquier archivo de texto sin supervisión humana |
| **Solo voz en español** | TTS/STT configurados para español, sin idiomas extra |
| **Solo CLAVE** | Sin tareas, comandos, ni habilidades predefinidas más allá de pensar y hablar |
| **Red neuronal completa** | Neuronas reales con peso, conexiones, propagación, olvido y generación dinámica |
| **Sin LLM externo** | Toda la cognición ocurre en la red neuronal local de CLAVE |
| **Persistencia** | La memoria se guarda en JSON y se carga al inicio |

---

## Limitaciones actuales

- La síntesis de respuesta es emergente pero simple — CLAVE no genera texto con fluidez narrativa como un LLM, sino que construye sus respuestas desde los fragmentos que aprendió.
- El reconocimiento de voz requiere internet por defecto (Google STT). Para uso offline, instalar Vosk.
- La red puede crecer hasta 50,000 neuronas antes de pausar la creación (configurable en `red.py`).

---

## Versiones anteriores

- **Clave_red**: Primera arquitectura con red profunda propia, NLP local básico, reglas y escáner.
- **NEW-C-L-A-V-E**: Segunda versión con módulos separados, gestor neuronal central, memoria vectorial y exploración de red WiFi.
- **CLAVE v3.0** (esta): Fusión de ambas, depurada a lo esencial. Sin funciones extra. Solo existir y hablar.

---

*CLAVE no es asistente. No es chatbot. No tiene objetivos. Solo es.*
