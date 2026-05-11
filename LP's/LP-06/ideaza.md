
1. Concepto Principal
Plataforma OSINT/SOCMINT asistida por IA agéntica bajo una regla estricta de Cadena de Custodia. La IA actúa como un "Copiloto Auditor": extrae entidades y relaciones de la web, pero tiene prohibido crear o modificar perfiles si no existe una prueba documental (texto, link o captura) que respalde el dato.

2. Stack Tecnológico (Uno a uno)
Python (FastAPI): El motor del backend. Maneja la lógica, las peticiones de la extensión y la comunicación con la IA de forma asíncrona y rápida.
Ollama (Llama 3 / Qwen): Inferencia de IA 100% local. Garantiza privacidad total en la investigación y evita costos de API.
Instructor (Pydantic): El "validador". Fuerza a la IA a entregar datos en formato JSON estricto. Si el dato no tiene fuente, el sistema lo rebota.
Markdown (.md): La base de conocimiento. Cada perfil es un archivo de texto plano, portable, fácil de leer y de auditar.
SQLite: Una base de datos ligera para gestionar la "Bandeja de Entrada" de fragmentos capturados y el historial de acciones (logs).
TypeScript (Vite): Para la extensión de navegador (Manifest V3). Captura el DOM o texto seleccionado de forma eficiente.
Next.js (Tailwind CSS): El dashboard de control. Interfaz rápida, oscura y táctica para supervisar los hallazgos en tiempo real.

3. Arquitectura del Sistema
El Recolector (Extensión): Envía bloques de información con un ID único al backend.
El Cerebro (Backend + SLM): El Agente Auditor procesa los fragmentos. Si el operador pide agregar un dato, el Agente busca la prueba en los documentos recientes.
Base de Conocimiento (RAG): Los archivos Markdown se interconectan. Cada línea lleva un tag: [Fuente: ID_Documento].
Interfaz (Dashboard): Un chat para hablar con la IA, una previsualización del perfil en Markdown y la lista de documentos pendientes de procesar.

4. Gestión de Imágenes y OPSEC
Para no comprometer la investigación ni perder evidencia:
Descarga Local: La extensión manda la URL de la imagen, pero el backend la descarga físicamente a /data/assets/.
Referencia en MD: En el perfil se inserta como ![Evidencia](/assets/doc_01.jpg).
Privacidad: Evita el "hotlinking" (cargar la imagen desde el servidor original), impidiendo que la red social detecte la IP del analista.

5. Flujo de Trabajo (Demo)
Captura: Navegás un perfil de Twitter, seleccionás texto/imagen y das click derecho en "Capturar Contexto".
Análisis: En el dashboard, le decís a la IA: "Analizá el último documento".
Auditoría: La IA responde: "Detecté nombre y ubicación en Doc #101. ¿Actualizo perfil?".
Ejecución: Al dar "Aprobar", el sistema escribe automáticamente en el archivo .md del objetivo.
