# Modelo de red de Contenedores
---

Es un estandar que propone Docker donde ha sido adoptado en numerosos proyectos donde Libnetwork trata de ofrecer y integrar en diversos productos.

Las caracteristicas clave de libnetwork es posible por la implementación de CNM.

**Aislamiento de red**.
Trabaja en un entorno donde contiene una configuración de red del contenedor donde funciona como una bateria de red dentro del contendor.

**Punto final**.
Interfaz de red que fue hecha en pares iguales que permiten ubicar en la punta de la interfaz que se encarga de aislar una red mientras la otra red designada garantiza una union de los puntos finales a una sola red.

Pueden existir otros puntos finales que varian en un entorno aislado.


**Red**
Existen conjuntos de puntos finales que identifican formas univoca que se comunican entre si.

**Etiqueta Definida por el usuario**Permite definir etiquetas mediante un indicador llamado *Label* esta etiqueta se transforma y pasan a ser metadatosa entre los controladores o libnetwork. En estas etiquetas permiten un entorno de ejecucion informe sobre las acciones de un controlador.

---

# Interfaz de Red de Contenedores

---
Es una estandarización propuesta en CoreOS con el objetivo de especificación minima para funcionar como un contrato simple entre sus complementos de red y un entorno para ejecutar de contendores como es CNI.

CNI tiene las siguientes Caracteristica.

Usa esquemas JSON para una definicion de netrada y salida deseadas en complemento de Red CNI. Además permite ejecucciónes de a varios complementos en un conteneodr mismo que une redes controladas en diferentes complementos.

El CNI describe la redes en archivos con formatos JSON de configuración y sus intanscias correspondientes para la creación de nuevos espacios con nombres que invocan sus complementos.

Sus complementos admiten dos comandos que se agregan y eliminan interfaces de su red en contenedores desde y hacía sus redes.



