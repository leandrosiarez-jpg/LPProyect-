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
# Gestion de rendimiento.

Resulta en un desafio importante para la propia gestion de conteneodres para los datos de red para implementarlo, monitorearlo y documentarlo para comprobar el rendimiento de la red. Se le conoce como una gestión de rendimiento llamado (NPM) Como estos puntos de acceso virutales o fisicas para maquinas virutales o cuyo cargo de trabajo fisico se pueda generar datos de red y captura de paquetes para las propias aplicaciones de servidores. Ya sea del tipo virtual o fisico siendo claros y definidos como estaticos. Esta gestión resulta en una instancia dinamica o efimera podría llegar a ser mas compleja cuya garantia se requiere de la aplicación donde no se pueda redirigir el trafico. en una instancia donde no existen. Siendo de manera que puedan ser preciso mientras llega conservar el trafico mismo de lso datos cumpliendo con la normativa establecida.

Los proveedores de NPM pueden permitir entornos de conteneodres de diversas formas siendo:

La dirección del trafico a intermediarios de paquetes de la red o dispositivos de la captura sobre la interfaz de comunicaciónes. (CNI)

Para la captura del trafico en diferentes contenedores sobre la proxy. para la recopilación continua de datos de una baja demanda.

---

---
# Modelo de Red Docker.

El modelo de Docker llega a utilizar por defecto a una red puente virutal que define un host y una red priviada para realizar coneciónes para contenedores. Por  cadea conteneor se le asigna una ip privada en una dirección. 

En un caso se le asignara los puertos del host a diferentes puertos de contedor que se rediriga al trafico para llegar a los nodos de docker. en esto se vuelve responsablidad del administrador para evitar conflictos de puertos entre contenedores de la propia gestion de redes de kubernetes siendo diferente.

---

--- 
# Red de Kubernetes.

Es una infraesctructura de red que permite la comunicacion y su escalabildiada en la seguridad para el acceso externo en las aplicaciones con contenedores.

Se vuelve una red compleja implicando que la comunicacion entre todos los componentes princiapales existan en el interior siend olos pdos, nodos, contendores y servicios mismos. Estos son como el trafico externo del cluster.

Los componentes unfamentales que conforman la arquictectura son:

**Cluster**
Es un conjunto de maquinas fisicas o virtuales (nodos) que funcionan juntas para ejecutar aplicaciones en contenedores. Esto conforma al cluster en base a la arquictectura.

**Nodos maestros**
Representan un unico host informatico, que puede ser una maquina virtual o fisica. Estos pueden alojar componentes dle plano de control de Kubernetes y responsables de programar y escalar en las aplicaciones. Estos pueden gestionar todos los recursos informaticos, ya sean de red, almacenitamiento de un cluster. El nodo maestro intenta ayudar a las aplciaciones y servicios en los contendores para que implementen por igual.

**Nodos de trabajo**
Son responsables para la ejeccución de los contendores y la realización de cualquier trabajado asginado bajo por el nodo maestro. Estos pueden alojar contendores de aplicaciones para agrupar en pods.

**Vainas**
Los pods pueden er grupso de uno o mas contenedores, ya sea como linux o Docker. Estos pueden compartir mismos recursos informaticos y red. Son undiades de implementación de cluster que pueden funcionar como unidades de escalabilidad.

---

---
# El funcionamiento de Kubernetes en las redes.
Su creación es para la ejeccución de sistmeas distribuidos en un plano de red distribuido en un cluster de maquinas para proporcionar interconectividad entre los componentes ne las redes de cluster de kubernetes para estos crean un entorno perfecto en los cuales datos puedan moverse de forma libre y eficiente. 

Estos caracterica distintiva de las redes de Kubernetes en su estrctura de red plana. El cual puede definirse como componentes uqe se conectan sin depender de un hardware de forma independientemente de los pods de un cluster. Para comunicarse con lso demas dispositivos independientemente del nodo para ejecutar. en la red plana ofrece un modo eficaz para compartir recursos y eliminar la misma necesidad de asignación de puertos de forma dinamica.

---
