Contenedores de red.
---

---
# ¿Que consiste?

Son interconexiónes de contenedores que permiten la comunicación con otros contendores o un host para la repartición de recursos y datos.

Se crea zonas de aislamiento para permitir un gran numero de contenedores que se comunican de una forma eficente y segura. Esta se propone por varios estandares con la intención de regular la redes de contenedores, entre ellos esta el modelo de Red de contenedores llamado (CNM) y una interfaz de red de contenedores apodado (CNI).
---

---
# Modelos de red
Las plataformas de contenedores mas concuridos son Docker y Kubernetes. Estos siguen los siguentes modelos siendo.

- Ninguno. Es un tipo de conexión de red mas sencillo siendo una interfaz de bucle invertido, es decir que el contenedor no se comunica a una red externa.

- Puente. Es un tipo de red interna para el host que permite una comunicación entre diferentes contenedores del mismo host

- Host. Se realiza un contenedor que comparte su espacio de nombres de red y el host. Esto puede posiblitar una conexion de red de alta velocidad.

- Superposiciones. Este asegura que los contenedores se conecten a 2 redes superpuestas en diferentes puntos aislandose entre si para no comunicarse a través de un puente local

- Capas subyacentes. Muestra las interfaces del host para maquinas virtuales o contedores que se ejecuten en el host.

---

---
#  Estandarización de contenedores.

Es un controlador o complemento para la gestion de redes y interfaces para una conectividad entre los contenedores y su red. Se asigna una dirección de ip para las interfaces de redes para los contenedores. Esto estandariza a las redes para proporcionar una interfaza o el uso de una API que se fefina para establecer comunicación entre entornso de ejecucción y complementacion de red.

Existe diversos metodos de estandarización para los contenedores. Esto permite separar la gestion de red para el entorno.
---


---
