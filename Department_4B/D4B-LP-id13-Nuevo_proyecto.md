# Department 4.B

## Documentacion tecnica del proyecto

**Version documentada:** Alpha 1.9.1.6
**Actualizacion:** 10/08 (continuacion de la entrada del 16/07)

> Este documento continua la documentacion original del 16/07 (Alpha 0.3), incorporando todo lo relevado directamente del codigo fuente actual del juego (`Department_4B_Alpha_1_9_1_6.html`). Las secciones marcadas como *"Nuevo desde Alpha 0.3"* resumen lo agregado en las versiones intermedias.

---

## 1. Acerca del proyecto

Department 4.B es un videojuego de terror psicologico desarrollado integramente con HTML, CSS y JavaScript, centrado en la exploracion, la narrativa ambiental y la tension emocional, dejando de lado elementos tradicionales del genero como el combate, los enemigos o los jumpscares.

El jugador controla a **Niko**, un protagonista que vive solo en un departamento (4.B). A lo largo de varios dias debera completar tareas cotidianas mientras el entorno comienza a cambiar de forma cada vez mas inquietante. El objetivo principal del proyecto sigue siendo generar incomodidad a traves de:

- diseno del escenario
- sonido
- repeticion
- deterioro psicologico del protagonista

El juego corre integramente en un unico archivo HTML autocontenido, ejecutable desde cualquier navegador moderno sin necesidad de motores de videojuegos, sin build step y sin dependencias externas.

### Confirmacion sobre el uso de assets

Un dato relevante detectado en el codigo: **el proyecto no usa imagenes ni sprites externos**. Todo el arte (personajes, mobiliario, iconos del inventario, efectos) se dibuja de forma procedural sobre un `<canvas>` mediante Canvas 2D API (`fillRect`, paths, etc.), en una grilla logica de 320x180 px con `image-rendering:pixelated`. Esto confirma y profundiza el punto de "Pixel Art" listado como tecnologia en la version anterior de este documento: no son archivos `.png`, sino pixel art generado por codigo.

---

## 2. Arquitectura y Sistemas

La arquitectura modular descripta en la version anterior se mantiene y se confirma en el codigo real, organizada en bloques separados por comentarios de seccion dentro de un unico `<script>`. Se identificaron los siguientes sistemas, agrupando los ya documentados con los que aparecieron en versiones posteriores a la Alpha 0.3.

### Sistemas ya documentados (confirmados en el codigo)

| Sistema | Rol | Notas de implementacion |
|---|---|---|
| Administrador de dias (Day Manager) | Controla el avance temporal y la progresion dia a dia | `advanceDay()`, `startChapter()`; `MAX_DAY = 14` |
| Administrador de objetivos (Objective Manager) | Gestiona el objetivo dinamico mostrado en el HUD | `setObjective()` / `completeObjective(forDay, texto)`, con guarda anti doble disparo (`objectiveCompletedForDay`) |
| Controlador del jugador (Player Controller) | Movimiento y acciones de Niko | `tryMove()`, manejo de teclado (`keys{}`) |
| Sistema de interaccion | Interaccion con objetos del escenario | `nearestObject()`, `promptIcon` contextual |
| Sistema de dialogos | Conversaciones y textos narrativos, con retratos y elecciones | modulo `Dialogue` (Alpha 1.0); soporta `Dialogue.choice` desde Alpha 1.4.0 |
| Administrador de habitaciones y del edificio | Explora el departamento y, desde el Dia 4, el edificio completo | `SCENES{}` + `buildLobby(key, opts)` para 5 pisos identicos en estructura |
| Sistema de eventos | Secuencias guionizadas y cambios ambientales progresivos | `applyDayNChanges()`, triggers por dia (por ejemplo `triggerDay12MaraEncounter()`) |
| Sistema de audio | Ambientacion sonora sintetizada | Web Audio API (`AudioContext`), sonido 100% generado por codigo, sin archivos de audio |
| Administrador de escenas y transiciones (Fade) | Cambio entre escenas con fundido | confirmado, sigue activo en todas las transiciones de dia/escena |

### Sistemas nuevos desde la Alpha 0.3 (no estaban en la documentacion original)

| Sistema | Descripcion | Desde |
|---|---|---|
| Sistema de Capitulos (`CHAPTERS`) | Menu de seleccion de capitulo con desbloqueo progresivo por dia jugado; persistencia de progreso via query param `?unlocked=N` (sin `localStorage`) | presente en la estructura actual; Capitulo II siempre desbloqueado |
| Sistema de dinero (`MONEY`) | Presupuesto semanal chico, monedas olvidadas coleccionables, gasto en el kiosko de la calle | Alpha 1.3.6 |
| Sistema de inventario (`Inventory`) | Ventana de items estilo RPG Maker, con iconos dibujados por codigo (llave oxidada, llave gris, reliquia, nota, objeto de historia) | posterior a Alpha 1.0, expandido en versiones intermedias |
| NPCs con agenda propia | El encargado del edificio (`BUILDING_MANAGER_SCHEDULE`) y la vecina Mara, cada uno con posiciones y tareas segun el dia | desde Capitulo II (Dia 8) en adelante |
| Estado emocional de Niko (`nikoState`) | Pequena huella persistente que dejan las elecciones de dialogo sobre el animo/comportamiento del protagonista | desde el sistema de dialogos con choices |
| Menu principal ampliado | Pantalla de inicio con seleccion de capitulo, configuracion (volumen, reduccion de movimiento) y creditos, navegable por teclado | confirmado en el codigo actual |
| Accesibilidad (`reduceMotion`) | Configuracion que atenua efectos de camara/temblor para jugadores sensibles a ellos | `settings = { volume, reduceMotion }` |
| Menu de desarrollador / Day Select oculto | Panel oculto (`Ctrl+H`) para saltar a cualquier dia durante testing; no visible ni accesible desde la UI normal | herramienta interna de QA, no forma parte de la experiencia final |

### Relacion con UML

Se mantiene vigente lo senalado en la version anterior: la arquitectura modular (escenas, sistemas independientes, estado por dia) sigue siendo apta para representarse mediante diagramas UML de casos de uso, clases, secuencia, actividades, estados y componentes. La incorporacion del sistema de capitulos y del estado por dia (`dayNState`) suma naturalmente candidatos a diagramas de estados (uno por capitulo/dia) y de secuencia (por ejemplo, la secuencia completa del apagon del Dia 10, dividida en 4 partes).

---

## 3. Linea narrativa y contenido implementado

La version actual del codigo (Alpha 1.9.1.6) implementa contenido jugable hasta el **Dia 14**, organizado en capitulos. Esto es un salto grande respecto de la Alpha 0.3 documentada originalmente, que solo listaba funcionalidades base sin detallar dias especificos.

### Capitulo I

- **Dia 1**: primer dia en el departamento; rutina introductoria.
- **Dia 2**: el departamento no se reconstruye; se muta sutilmente (primeros cambios ambientales).
- **Dia 3**: el bano puede desaparecer a mitad de un loop de pasillo.
- **Dia 4**: el edificio se abre por primera vez (5 pisos), aparece el ascensor.
- **Dia 5**: escena del sofa; el departamento vuelve a un estado "normal", sin la actividad activa del Dia 3.
- **Dia 6**: "La llave".
- **Dia 7**: "Abrir esa puerta" — secuencia final de la Alpha / cierre del Capitulo I.

### Capitulo II

- **Dia 8**: "Outside" — primer dia fuera del departamento; aparecen dinero, kiosko y exterior del edificio.
- **Dia 9**: "Above" — el jugador llega a la azotea y dispara una escena guionizada propia.
- **Dia 10**: "No Light" (4 partes) — corte de luz en el edificio, busqueda del encargado, y regreso de la luz.
- **Dia 11**: "Enough" (6 partes) — primera confrontacion emocional fuerte.
- **Dia 12**: "Quiet" (5 partes) — dia deliberadamente opuesto al Dia 11: nada pasa.
- **Dia 13**: "Loop" (6 partes) — incluye panico, la escena de la baranda en la azotea y un falso despertar.
- **Dia 14**: "The Key" (6 partes) — cierre del Capitulo III/arco actual; el edificio "desaparece", duplicacion de NPCs fuera de lugar, y un cierre silencioso con un teaser de "Dia 15".

> **Nota:** en el codigo, el Dia 14 se referencia tanto como cierre de un arco narrativo ("Chapter III closing out" en los comentarios) como parte del Capitulo II en el menu de seleccion (`CHAPTERS` solo define I, II, III, IV y V como entradas de menu — el contenido de dias 9 a 14 se pliega dentro de esas entradas sin item propio de menu). Convendria unificar la nomenclatura de capitulos en la proxima actualizacion de esta documentacion.

### Escenarios implementados

| Escenario | Detalle |
|---|---|
| Dormitorio | 2m x 2m; incluye un coleccionable de capitulo oculto y dinero olvidado (relevante desde Dia 8) |
| Pasillo interno + bano | 5m x 1m; el bano puede quedar inaccesible desde el Dia 3 |
| Living / cocina / comedor | 4m x 3m; zona de sofa y TV, zona de cocina y zona de comedor separadas |
| Edificio (5 pisos) | Layout identico entre pisos con una diferencia ambiental sutil por piso; ascensor, dos escaleras, puertas de departamentos (solo una funcional: 4.B) |
| Azotea | Disponible desde el Dia 9; acceso por escalera propia desde el Dia 10 cuando el ascensor deja de funcionar |
| Exterior / vereda | Calle frente al edificio, con kiosko; introducido en el Capitulo II |

---

## 4. Tecnologias utilizadas

Se confirma y actualiza la lista de tecnologias respecto de la version anterior:

- HTML5 (documento unico y autocontenido)
- CSS3 (HUD, menus, dialogo, pantallas de inventario y configuracion)
- JavaScript (Vanilla, sin frameworks ni bundlers)
- Canvas 2D API — todo el arte (pixel art) se genera por codigo, no hay archivos de imagen
- Web Audio API — audio ambiental y efectos sintetizados por codigo, sin archivos de audio
- Persistencia de progreso via query string (`URLSearchParams` + `history.replaceState`), sin uso de `localStorage`/`sessionStorage`

---

## 5. Estado actual del proyecto

**Version actual:** Alpha 1.9.1.6 (documentada previamente como Alpha 0.3)

### Funcionalidades implementadas (acumulado)

- Menu principal con seleccion de capitulo, configuracion y creditos
- Movimiento del jugador y sistema de interaccion
- Sistema de dialogos con retratos, paginado y elecciones (`Dialogue.choice`)
- Progresion por dias (1 a 14) con estado propio por dia (`dayNState`)
- Objetivos dinamicos por dia, con guarda anti doble disparo
- Transiciones con fundido (Fade)
- Exploracion del departamento y del edificio (5 pisos)
- Exploracion de azotea y exterior (Capitulo II)
- Eventos guionizados multi-parte (por ejemplo, Dia 10 en 4 partes, Dia 13 en 6 partes)
- Cambios ambientales progresivos y secuencias de terror psicologico
- Sistema de dinero e inventario
- NPCs con agenda por dia (encargado del edificio, vecina Mara, vecina del 3er piso)
- Estado emocional persistente del protagonista (`nikoState`)
- Configuracion de accesibilidad (volumen, reduccion de movimiento)
- Menu de desarrollador oculto para seleccion de dia (herramienta de QA, `Ctrl+H`)

### Desarrollo futuro

Segun lo relevado en los propios comentarios del codigo, el Dia 14 termina con un teaser de "Dia 15" sin desarrollar aun, lo que confirma que la linea narrativa continua abierta mas alla del contenido actualmente implementado. La arquitectura sigue disenada para agregar nuevas habitaciones, pisos, objetos interactivos y dias sin modificar los sistemas existentes, favoreciendo la escalabilidad y la reutilizacion de codigo, tal como se establecia en la version anterior de este documento.

---

## 6. Conclusion tecnica (actualizada)

Department 4.B confirma en su implementacion real los principios de arquitectura de software modular planteados desde el inicio del proyecto. La incorporacion de un sistema de capitulos, dinero, inventario, NPCs con agenda propia y un estado emocional persistente del protagonista amplia significativamente el alcance respecto de la Alpha 0.3, sin abandonar en ningun momento el enfoque original: un juego narrativo e inmersivo construido enteramente con tecnologias web, sin motores de videojuegos, y documentable de forma clara mediante UML.

### Referencias

- [MDN Web Docs - HTML](https://developer.mozilla.org/es/docs/Web/HTML)
- [MDN Web Docs - Web Audio API](https://developer.mozilla.org/es/docs/Web/API/Web_Audio_API)
- [MDN Web Docs - Canvas API](https://developer.mozilla.org/es/docs/Web/API/Canvas_API)
- [O.M.G. - UML](https://www.omg.org/spec/UML/2.5.1/About-UML)
