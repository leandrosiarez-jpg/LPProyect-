# Modelo de Red
---

Son plataformas de contenedores mas usados con Docker & Kubernenetes. Estos mismos siguen un modelo de red distinto siendo.

- **Ninguno**
es el tipo de conexión de red mas simple siendo simplemente una interfaz con bucle invertido. Este tipo de contenedor no puede comunicarse con una red Externa.

- **Puente**
Este tipo es una red interna para un host que autoriza la comunicación de diferentes contenedores que use el mismo host.

- **Host**
Se crea un contenedor que existe en un espacio de redes y un host que se pueda conectar en una misma conexión de red a alta velocidad.

- **Superposiciones**
Uno o mas contenedores se pueden conectar a 2 redes que esten encima de la otra y entre varios puntos aislandolos mutuamente evitando comunicarse a un puente local.

- **Capas subyacentes**
Se maneja por interfaces al host para el uso de maquinas virtuales o contenedores con la ejecución del host.
