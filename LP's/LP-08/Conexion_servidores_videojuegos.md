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
