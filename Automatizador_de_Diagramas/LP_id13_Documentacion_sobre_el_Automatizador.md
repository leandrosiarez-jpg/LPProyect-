# El automatizador de Diagramas en el proyecto Gummy Wars

## 1. Introducción

Este documento explica en detalle como función el **Automatizador de Diagramas** y de que manera se esta usando para documentar el diseño de **Gummy Wars**, el shooter de plataformas 2D competitivo.

El objetivo de este documento no es solo mostrar los diagramas ya generados, sono dejar asentado el razonamiento detrás de cada uno, para que cualquier persona del equipo (o una IA a la que se le pida ayuda) pueda entender el criterio usado y seguir extendiendo la documentación de forma consiente.

La herramienta esta publicada y disponible sin instalación en:
  
🔗 **https://automatizador-de-uml.netlify.app**

## 2. ¿Que es el Automatizador?

El automatizador es una pagina HTML auto contenida que toma un **JSON clave-valor** como entrada y devuelve un **diagrama en SVG** como salida. No conecta con ningún servidor: todo el procesamiento (parseo del JSON, detección de errores, layout del diagrama, exportación) ocurre en el navegador.
 Soporta tres tipos de diagrama, y el criterio para elegir cuál generar es siempre "qué pregunta quiero responder con el dibujo"
| Modo   | Responde a...                                   | Se usa en este proyecto para... |
|--------|--------------------------------------------------|----------------------------------|
| Árbol  | ¿Cómo está organizado el contenido?              | Mapear las secciones del GDD     |
| Flujo  | ¿Qué pasa primero, y qué pasa después?           | Mapear el ciclo de una partida   |
| UML    | ¿Qué entidades existen y cómo se relacionan?     | Mapear el modelo de datos/diseño |

### 2.1  Detección automática de modo

El automatizador no obliga  declarar el tipo de diagrama: lo infiere mirando la forma del JSON.

  1. Si ningún valor de primer nivel es un objeto con la clave `"type"` →
   se dibuja como **Árbol**.
  2. Si al menos un valor tiene `"type"` pero ninguno vale `"class"` → se
   dibuja como **Flujo**.
  3. Si al menos un valor tiene `"type": "class"` → se dibuja como **UML**.

Esto es importante porque significa que **el mismo formato de entrada (un objeto JSON)** sirve para los tres casos: no hay que aprender tres sintaxis distintas, solo hay que saber que claves usar en cada caso

### 2.2 Validación

Antes de mostrar el dibujo, el Automatizador revisa el JSON y separa los problemas en dos categorias:

- **Errores** (bloquean el render): la causa más común es una relación que
  apunta a un nodo que no existe en el JSON (por ejemplo, una clase que
  declara `"extends": "Vehiculo"` pero `"Vehiculo"` nunca se definió como
  nodo). También es error si la raíz del JSON no es un objeto clave-valor.
- **Avisos** (no bloquean, pero el nodo se dibuja distinto): por ejemplo un
  nodo en modo Flujo/UML sin `"type"`, o con un `"type"` no reconocido. Se
  dibuja igual, como nodo genérico con borde punteado.

  Esto es relevante para el equipo porque significa que el Automatizador **no permite documentar relaciones "fantasmas"**: si en el diagrama de Gummy Wars alguien agrega `"defiende": "Trinchera"` pero nunca definió el nodo `"Trinchera"`, el Automatizador lo va a frenar con un error en vez de dibujar una flecha que apunta a la nada. Sirve como una forma barata de detectar inconsistencias en el diseño a medida que crece el documento.

## 3. Los tres diagramas aplicados a Gummy Wars
A partir del Game Design Document se armaron tres JSON, uno por cada modo, cada uno mirando el proyecto desde un ángulo distinto. Los tres archivos están adjuntos junto a este documento:
