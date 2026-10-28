# GummyWars (Godot)

Shooter 2D de vista lateral por equipos, en pixel art: soldados de gomita de **USA** contra **Vietnam** sobre un mapa de caramelo. Partidas de 4 contra 4 (los lugares vacíos los ocupan bots), al mejor de 3 rondas, con interludio de construcción y tienda antes de cada ronda. Se juega solo contra bots o en red local.

Hecho en **Godot 4.7** con GDScript.

## Cómo probarlo

1. Instalar [Godot 4.7](https://godotengine.org/download) (versión estándar, no hace falta la de .NET).
2. Clonar esta branch:
   ```bash
   git clone -b GummyWars-Godot https://github.com/leandrosiarez-jpg/LPProyect-.git GummyWars
   ```
3. Abrir Godot, elegir **Importar** y seleccionar `GummyWars/project.godot`. La primera vez tarda unos segundos en importar los sprites.
4. Ejecutar con **F5**.

En el menú:

- **JUGAR VS BOTS**: partida local contra bots.
- **ALOJAR (LAN)**: abre una partida en esta computadora para que otros se unan.
- **UNIRSE (LAN)**: se conecta a una partida escribiendo la IP del anfitrión.

Después se elige equipo y clase para desplegarse.

## Controles

| Acción | Tecla |
| --- | --- |
| Moverse | A / D o flechas |
| Saltar | Espacio, W o flecha arriba |
| Disparar | Clic izquierdo |
| Disparo alternativo | Clic derecho |
| Recargar | R |
| Granada (dona explosiva) | G |
| Modo construcción | B |
| Tienda | T |
| Listo (acortar el interludio) | F |
| Tabla de puntajes | Tab |
| Pausa | M o Esc |

## Jugar en red local

- Un jugador elige **ALOJAR (LAN)**. Los demás eligen **UNIRSE (LAN)** y escriben la IP local del anfitrión (por ejemplo `192.168.0.10`; en Windows se ve con `ipconfig`).
- Usa el puerto **UDP 42069** y admite hasta 8 jugadores.
- La primera vez que se aloja, Windows pregunta por el firewall: hay que permitir el acceso en redes privadas.
- Para jugar por internet, el anfitrión tiene que abrir el puerto UDP 42069 en su router.

El anfitrión es autoritativo: decide daño, muertes, puntajes y fases. Los demás envían sus pedidos (moverse, disparar, construir, comprar) y reciben el estado de la partida.

## Cómo se juega

Cada partida tiene hasta 3 rondas y gana el primer equipo con 2 victorias.

1. **Interludio (60 s):** las barreras separan a los equipos. Cada jugador recibe 12 bloques para fortificar su zona y puede comprar en la tienda. Si todos marcan "Listo", empieza antes.
2. **Ronda (5 min):** se juega la misión de la ronda. Si se acaba el tiempo, gana el equipo con más progreso.
3. **Fin de ronda:** se reparte la paga y el comandante comenta el resultado.

| Misión | Objetivo |
| --- | --- |
| Asesinato | Eliminar al oficial enemigo y proteger al propio |
| Rey de la colina | Controlar la colina del centro |
| Intercepción | Interceptar 3 señales de radio |
| Robo de bandera | Robar la bandera enemiga y llevarla a la base 2 veces |
| Demolición | Destruir el depósito enemigo |

| Clase | Vida | Arma inicial | Otras armas |
| --- | --- | --- | --- |
| Soldado | 100 | Fusil de cerrojo | Escopeta, M60, francotirador |
| Pyro | 120 | Lanzallamas | Lanzanapalm, escopeta |

Se gana dinero por bajas, tiros a la cabeza, objetivos y rondas, y se gasta en la tienda: armas, chaleco, botas, cargadores, granadas y bloques extra.

## Estructura del proyecto

| Carpeta | Contenido |
| --- | --- |
| `scenes/main.tscn` | Única escena; todo lo demás se arma por código desde `scripts/main.gd` |
| `scripts/core/` | Autoloads: constantes (`GC`), balance (`Data`), red (`Net`), estado replicado (`MatchState`), señales del servidor, referencias globales (`G`) y sprites |
| `scripts/server/` | Sistemas que corren solo en el anfitrión: partida, equipamiento, personajes, combate, construcción, navegación, misiones, bots e intercom |
| `scripts/client/` | Controladores de cada jugador: entrada, cámara, réplica de personajes, proyectiles, efectos, sonido, misiones, construcción y color |
| `scripts/game/` | Clases compartidas: personaje (`Gummy`), su dibujo, mapa (`MapGrid`) y cálculos de combate |
| `scripts/ui/` | Menú, HUD, tienda, tabla de puntajes, intercom, resultados y fuente pixel |
| `data/` | Mapa "Frente del Caramelo" y textos de misiones |
| `assets/sprites/` | Sprites PNG |
| `tools/` | Verificación automática |

### Unidades

El balance se escribe en **studs** (unidad de diseño) y segundos; en pantalla 1 stud = 8 px y cada celda de la grilla mide 32 px. El eje Y de Godot va hacia abajo; las conversiones están en `GC.studs_to_px()` y `GC.px_to_studs()`.

### Red

`Net.request(acción, args)` envía un pedido al anfitrión, que lo atiende con `Net.register_handler()`. El anfitrión responde con `Net.broadcast(evento, datos)` o `Net.send_to(peer_id, evento, datos)`, y todos escuchan `Net.event_received`. `MatchState` replica cada 0,1 s solo lo que cambió, y manda una copia completa a quien recién entra. En modo solo se usa `OfflineMultiplayerPeer`, así que el código es el mismo en los tres modos.

## Pruebas

Se pueden correr sin abrir el editor, con el ejecutable de Godot (la variable `GODOT` apunta a él):

```bash
GODOT=/ruta/a/Godot_v4.7-stable_console sh tools/check.sh 5 net
```

| Argumento | Qué hace |
| --- | --- |
| `--check` | Compila todos los scripts y avisa si alguno tiene errores |
| `--autotest=N` | Juega N segundos solo, como Soldado de USA, y muestra la fase alcanzada |
| `--shots=carpeta` | Junto con `--autotest`, guarda una captura cada 2 s |
| `--nettest=host` / `--nettest=client` | Anfitrión y participante en 127.0.0.1: prueba conexión, despliegue y movimiento |

Los argumentos van después de `--`, por ejemplo: `godot --headless --path . -- --autotest=10`.

## Pendiente

- Cinemáticas de introducción y de final de partida (hoy se muestra una pantalla de resultados).
- Grano, viñeta y barras de cine.
- Guardado de progreso y cuentas.
