# --- Conceptos Relacionados ---

# --- Redes y Conectividad ---

Este concepto se relaciona porque permite la comunicación entre la PC local y el servidor remoto. 
La conexión se realiza mediante protocolos como TCP/IP, HTTPS o SSH, que hacen posible el envío y recepción de datos.

# --- Socket ---

El socket representa el punto de conexión entre cliente y servidor. 
Es el canal que permite que la computadora del usuario se comunique con el servicio remoto y establezca la transferencia de información.

# --- Gestion de Hilos y Procesos ---

Cuando el usuario ejecuta un comando como git push, se inicia un proceso en la máquina local. 
Ese proceso se comunica con otro proceso activo en el servidor remoto. 
Ambos trabajan al mismo tiempo para completar la conexión.

# --- EndPoint ---

La computadora del usuario funciona como un endpoint, es decir, un punto final de la red. 
El otro endpoint es el servidor remoto, como GitHub. Ambos extremos deben estar conectados correctamente para que el servicio funcione.

# --- Seguridad y Jerarquia ---

La conexión necesita autenticación mediante usuario, correo y permisos. 
También puede utilizar claves SSH para mayor seguridad. 
Esto garantiza que solo personas autorizadas puedan acceder al servicio.

# --- No Repudio ---

Cada acción realizada, como un commit o un push, queda registrada con el nombre del autor. 
Esto evita que alguien pueda negar haber realizado una modificación dentro del sistema.

# --- Time Stamping ---

Cada cambio enviado queda guardado con fecha y hora exacta.
Esto permite llevar un control de versiones y saber cuándo se realizó cada modificación.

# --- Administracion de Sistemas ---

Se necesita una correcta configuración del entorno local, como instalar Git, configurar credenciales y verificar la conexión a internet.
Sin esta administración previa, la conexión no podría realizarse correctamente.

# --- Comunicacion y Documentacion ---

Los commits permiten documentar los cambios realizados dentro del proyecto. 
Esto mejora el trabajo en equipo y facilita el mantenimiento del sistema.
