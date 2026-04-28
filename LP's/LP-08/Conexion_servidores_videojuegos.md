# Conexion de Servidores y Videojuegos Online 1: Introduccion
## ¿Que pasa cuando juego una partida online?
La conexion ocurre una vez el jugador inicia el juego y el cliente del mismo envia una solicitud al servidor.
Una vez llega, el servidor acepta la solicitud y asigna al jugador a una sesion/partida. A partir de ahi hay un intercambio de
datos constante; El cliente envia datos acerca de las acciones del jugador y el servidor actualiza constantemente el estado del
juego acordemente. Todo ocurre en milisegundos y dependiendo de la velocidad/precision requerida, necesitara protocolos de red
tales como TCP o UDP.
## ¿Que hacen los Servidores?
A la hora de jugar una partida, los servidores deben cumplir muchisimas funciones al mismo tiempo. Por un lado, deben asegurarse
de la sincronicidad de los jugadores para que haya un terreno justo (En especial en juegos competitivos). Por otro, tambien se
encargan de que los jugadores no introduzcan trampas, cheats o exploits. Es el apartado de ciberseguridad en los videojuegos. 
Son los responsables de la persistencia en la sesion, es decir, los que guardan el progreso o estadisticas de la experiencia.
Y por ultimo se hacen cargo de que haya una escalabilidad estable. Actualmente muchos videojuegos online son capaces de llegar
hasta los 100 jugadores en una sola partida, asi que el servidor debe asegurarse de escalar y funcionar correctamente con tales 
dimensiones.
## Tipos de Servidores
Hay muchisimos tipos de servidores distintos dependiendo la epoca, recursos y tipo de videjuego que lo requiera. Abajo listare los mas comunes.
- **Servidor Dedicado**: El servidor es una maquina independiente en la que ningun jugador juega directamente, unicamente se encarga
de la logica del juego. Los jugadores se conectan como clientes. Es consistentemente estable y dificil de hackear, pero muy costoso
de mantener y requiere centros de datos.
- **Servidor de Jugador "Listen"**: Un jugador crea la partida y su computadora funciona como el servidor al que los demas jugadores se conectan. Es facil de implementar y no requiere infraestructura externa, pero si el host tiene mala conexion esto se ve reflejado en el rendimiento de todos los demas jugadores. Por otro lado, el host suele tener ventajas notables en comparacion a los demas jugadores (Menos latencia) y la partida enteramente depende de que el host no decida irse.
- **Peer-To-Peer (P2P)**: No hay servidor central, todos los jugadores se conectan directamente entre si. Es muy barato y tambien escalable (En teoria), pero es muy vulnerable a trampas, dificil de sincronizar y presenta varios problemas de conexion.
- **Servidor en la nube**: Son servidores dedicados distribuidos globalmente. El juego asigna al jugador al servidor mas cercano y los servidores escalan automaticamente segun la cantidad de jugadores. Tiene menos latencia, gran escalabilidad y alta disponibilidad de forma global. Los costos de estos servidores varian bastante y es muy complejo tecnicamente hablando.
