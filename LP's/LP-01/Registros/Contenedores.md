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

---
# Casos de uso de Kubernetes.

- 1° Utilización de aplicaciones a gran escala.
Uno de los usos del Kubernetes se ve relacionado con sitios web que contenga un alto trafico además de que las apps que usan **Cloud Computing** reciben millones de solicitudes de usuario a diarío siendo una ventaja importante para el uso de Kubernete. Así mismo su implementación en las apps en la nube a gran escala para realizar un autoescalado. Para así mismo ajustarse automaticamente en los cambios para la demanda con una rapidez y eficancia en un tiempo relativamente corto de inactividad. 

Además de que es forma continua y respondiendo a los cambios en los patrones del trafico web así ayudando a mantener ciertca cantidad de recrusos en la carga de trabajo y así sin aprovisionamiento excesivo o corto.

- 2° Computación de alto rendimiento.
En los sectores del gobierno como la ciencia, finanzas y ingenieria dependera en una gran medida para la tecnologia para procesar los calculos complejos donde el HPC se llega a utilizar potentes procesadores que se encarga a un ritmo alto para la toma de decisiónes con datos en los cual es se automizatizan en un comercio bursatil.

- 3° El uso de IA y el machine Learning.
Se utiliza para crear y implementar un sistmea donde se requiere enormes volumenes de datoss y procesos complejos los cuales una computadora necesita un alto rendimiento y un analisis de gran datos en los cuales. Se implementa en un machine Learning en Kubernetes para facilitar en organizaciones de automatizacion sobre la gestion y el escaldao de los ciclos de vida para reducir su necesidad de intervenicion manual.

Siendo un ejemplo en la cual la plataforma se orquesta para automatizar en diferentes partes en los flujos donde el trabajo se debe de mantener predictivo en la IA y la ml en donde se incluye en sus comprobaciónes en el estado de salud y su planificación de recursos.

- 4° Gestión de microservicios.
Esto ofrece un enfoque moderno en la arquictectura nativa en donde cada aplicacion se compone en numerosos componentes o servicios mas pequeños que se interconectan e implementan de una forma independiente. Se suele incluir en un servicio de pedido o pago incluso de envio o atención al cliente. En esto el servicio se tiene su propia API rest en donde los demas servicios se utilizen para comunicarse con el.

Se diseña con el fin de gestionar la complejidad donde implicaba la gestion de componentes independientes que pueden ejecutar en simultaneadad en una arquictectura de microservicios siendo un ejemplo una caracteristica de alta disponiblidad donde se integre en Kubernete para garantizar la operación continua en un posible caso de fallo en donde se puede autoreparar en kubernetes se activa en una app de contendores o componentes.

- 5° Implementación de hibridos y multinube.
En Kubernetes esta diseñado de ta lforma que se utilize en cualquier lugar para facilitar las organizaciónes de migración de apps en u entorno local dentro de una nube hibrida o multinubes. Con Kubernetes estandarizo una forma de migración que proporciona a los desarroladores de software con comandos integrados para la implementación de una forma eficaz dentro de las apps. Siendo que puede introducir dstintos cambios en apps para ampliar o reducirlas en función de necesidades dentro del entorno. En el caso de Kubernete ofrece una portabildiad para distintos entornos locales en la nube para detallar una infraesctructura en apps para la eliminación en la necesidad de dependencias de applicaciones especificas dentro de la plataforma facilitando un traslado entre distintos proveedores con un meno esfuerzo en los datos centrales.

- 6° DevOps empresariales.
se enfoca en la actualización e implementación de applicaciones rapidamente donde se vuelve fundamental para el exito del negició, con Kubernetes da cierta facilidada a los equipos desarrolladores como el mantenimiento de los sistemas de Software para una incrementación en la agildidad general o la interfaz de la Api de Kubernetez. Donde permite en los desarroladores de software o otras partes que son intereses de DevOps. como sería Acceso, implementación, actualizacion y la optimizac ion para los ecosistemas de contenedores.

En un caso de CI/CD se significa en Integración continua (CI) y Entrega Continua (CD) en la cual se convirtio en un aspecto clave en el desarrollo del software. Con CI Y CD agiliza la codificacación en las pruebas y implementacion de las aplicaciones proporcionadas pro el equipo siendo que un unico repositorio se pueda almacenar el trabajo y las herramientas que se pueda automatizar para la combinación y así probar el codigo de forma coherente y así garantizando su funcionamiento.

Con Kubernetes desempeña un papel importante en donde CI/CD nativas de una nube al automatizar donde la implementación de contendores donde su entorno de infraesctructura de la nube para garantizar en un uso eficiente de los recursos.

---
