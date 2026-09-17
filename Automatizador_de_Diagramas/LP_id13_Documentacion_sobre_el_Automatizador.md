  # El automatizador de Diagramas en el proyecto Gummy Wars

  ## 1. Introduccion

  Este documento explica en detalle como funcion el **Automatizador de Diagramas** y de que manera se esta usando para documentar el diseño de **Gummy Wars**, el shooter de plataformas 2D competitivo.


  El objetivo de este documento no es wolo mostrar los diagramas ya generados, sono dejar asentado el razonamiento detras de cada uno, para que cualquier persona del equipo (o una IA a la que se le pida ayuda) pueda entender el criterio usado y seguir extendiendo la documentacion de forma consiente.

  La herramienta esta publicada y disponible sin instalacion en:
  
  🔗 **https://automatizador-de-uml.netlify.app**

  ## 2. ¿Que es el Automatizador?

  El automatizador es una pagina HTML auto contenida que toma un **JSON clave-valor** como entrada y devuelve un **diagrama en SVG** como salida. No conecta con ningún servidor: todo el procesamiento (parseo del JSON, detección de errores, layout del diagrama, exportación) ocurre en el navegador.

  Soporta tres tipos de diagrama, y el criterio para elegir cuál generar es siempre "qué pregunta quiero responder con el dibujo"
  | Modo   | Responde a...                                   | Se usa en este proyecto para... |
  |--------|--------------------------------------------------|----------------------------------|
  | Árbol  | ¿Cómo está organizado el contenido?              | Mapear las secciones del GDD     |
  | Flujo  | ¿Qué pasa primero, y qué pasa después?           | Mapear el ciclo de una partida   |
  | UML    | ¿Qué entidades existen y cómo se relacionan?     | Mapear el modelo de datos/diseño |

