---
título: Análisis y resolución de problematicas en servidores
fecha: 2026-04-22
etiquetas: [vulnerabilidades, metodos de defensa, estrategias de diseñó]
---

## 1. Servidor de empresa (cliente - servidor)

### **1.1 Ataques DDoS (Distributed Denial of Service)**

<ins>**Descripción**</ins>

Un ataque DDoS consiste en enviar una gran cantidad de solicitudes o tráfico hacia un servidor con el objetivo de consumir sus recursos y provocar una interrupción del servicio. Los videojuegos requieren una conexión rápida y estable, por lo que una interrupción afecta directamente la experiencia del usuario.

En un videojuego online puede generar:

- Aumento del tiempo de respuesta.
- Alto nivel de latencia.
- Desconexión de jugadores.
- Imposibilidad de crear o acceder a partidas.
- Caída completa del servidor.

Una caída del servidor afecta a todos los usuarios conectados e impide el acceso al servicio.

### Solución:
Implementar

- Sistemas de mitigación contra ataques DDoS.
- Balanceadores de carga.
- Distribución del servicio mediante múltiples servidores.
- Filtrado del tráfico antes de llegar al servidor principal.

**Herramientas recomendadas**

- Cloudflare DDoS Protection.
- AWS Shield.
- Balanceadores de carga.
- Servicios de protección en la nube.

---

### **1.2 Robo de cuentas y accesos no autorizados**

<ins>**Descripción**</ins>

Los servidores almacenan información relacionada con los usuarios, como:

- Datos de autenticación.
- Progreso del jugador.
- Estadísticas.
- Configuraciones personales.

Los métodos utilizados pueden incluir:

- Robo de contraseñas.
- Ataques de fuerza bruta.
- Filtración de credenciales.
- Secuestro de sesiones.

### Solución:

Implementar:

- Autenticación multifactor (MFA).
- Cifrado de datos sensibles.
- Gestión segura de sesiones.
- Control de permisos.
- Validación de identidad del usuario.

**Herramientas recomendadas**

- OAuth.
- JWT.
- TLS/SSL.
- Sistemas MFA.

---

### **1.3 Caída o sobrecarga del servidor**

<ins>**Descripción**</ins>

Los servidores pueden presentar fallas cuando reciben una cantidad de usuarios o solicitudes superior a su capacidad. Situaciones que pueden provocar una sobrecarga:

- Lanzamiento de nuevas actualizaciones.
- Eventos con muchos jugadores.
- Incremento inesperado de usuarios.
- Fallas de hardware.

La falta de escalabilidad puede provocar lentitud, errores de conexión o interrupción del servicio.

### Solución:

Implementar:

- Escalabilidad automática.
- Redundancia de servidores.
- Balanceadores de carga.
- Infraestructura distribuida.

**Herramientas recomendadas**

- Kubernetes.
- Docker.
- Servicios de nube.
- Auto Scaling.

---

### **1.4 Pérdida o corrupción de datos**

<ins>**Descripción**</ins>

Los servidores almacenan información importante del videojuego cualquier fluctiación/falla del sistema puede provocar pérdida permanente o corrupción de datos:

- Progreso de usuarios.
- Estadísticas.
- Configuraciones.
- Información de partidas.

Las causas pueden ser:

- Errores del servidor.
- Fallas de almacenamiento.
- Ataques externos.
- Errores humanos.

Todo sistema que almacena información puede sufrir fallos si no cuenta con mecanismos de respaldo.

### Solución

Implementar:

- Copias de seguridad automáticas.
- Replicación de bases de datos.
- Sistemas de recuperación ante fallos.
- Control de acceso a la información.

**Herramientas recomendadas**

- Servicios de Backup Cloud.
- Bases de datos replicadas.
- Sistemas de recuperación ante desastres.

---

### **1.5 Interceptación y manipulación de comunicación**

<ins>**Descripción**</ins>

Los videojuegos online mantienen una comunicación constante entre el cliente y el servidor mediante el intercambio de información y si la comunicación no está protegida,  un atacante podría interceptar o modificar información. Durante esta comunicación pueden enviarse:

- Datos de sesión.
- Información del jugador.
- Solicitudes de conexión.
- Datos de la partida.

Ejemplos de ataques:

- Man-in-the-Middle (MITM).
- Interceptación de paquetes.
- Robo de información.
- Modificación de datos durante la transmisión.

### Solución

Implementar:

- Cifrado de comunicación.
- Protocolos seguros.
- Validación de solicitudes.
- Control de acceso a servicios.

**Herramientas recomendadas**

- TLS/SSL.
- Firewalls.
- IDS/IPS.
- Sistemas de autenticación mediante tokens.

---

###  **1.6. Tabla de Vulnerabilidades y Soluciones**

| Vulnerabilidad | Impacto | Probabilidad | Solución | Herramientas |
|---|---|---|---|---|
| Ataque DDoS | Alto | Alta | Filtrado de tráfico y distribución de carga | Protección DDoS, Balanceadores |
| Robo de cuentas | Alto | Alta | MFA y cifrado de datos | OAuth, JWT, TLS |
| Caída del servidor | Alto | Media | Escalabilidad y redundancia | Kubernetes, Cloud, Auto Scaling |
| Pérdida de datos | Alto | Alta | Backups y replicación | Backup Cloud, Bases replicadas |
| Interceptación de datos | Alto | Media | Protección de comunicación | TLS, Firewall, IDS/IPS |

---

### **1.7. Arquitectura de Seguridad Recomendada**

La arquitectura propuesta para mejorar la seguridad y disponibilidad del sistema es:

             Jugadores
                |
                ↓
    Firewall + Protección DDoS
                |
                ↓
      Balanceador de carga
                |
                ↓
        Servidores de juego
                |
                ↓
    Base de datos segura + Backup



### Componentes principales

<ins>**Firewall**</ins>

Permite controlar conexiones entrantes y bloquear accesos no autorizados.

<ins>**Protección DDoS**</ins>

Detecta y filtra tráfico malicioso antes de que afecte al servidor.

<ins>**Balanceador de carga**</ins>

Distribuye las solicitudes entre diferentes servidores para evitar sobrecargas.

<ins>**Servicios Cloud**</ins>

Permiten aumentar o reducir recursos según la cantidad de usuarios conectados.

<ins>**Monitoreo**</ins>

Permite detectar problemas de rendimiento y posibles ataques.

---

### **1.8. Herramientas Recomendadas**

**Herramientas de Disponibilidad y Escalabilidad**

- Balanceadores de carga.
- Kubernetes.
- Docker.
- Servicios de nube.
- Auto Scaling.

Estas herramientas permiten mantener el servicio disponible y adaptarse al crecimiento de usuarios.

**Herramientas de Ciberseguridad y Mitigación**

- Sistemas de mitigación DDoS.
- Firewalls.
- IDS/IPS.
- Cifrado TLS.
- Autenticación multifactor.

Estas soluciones protegen la infraestructura y la información de los usuarios.

**Herramientas de Gestión y Monitoreo**

- Sistemas de métricas.
- Análisis de protocolos.
- Registro de eventos.
- Automatización de procesos.

Permiten detectar fallas rápidamente y mejorar la administración del sistema.

---

### **1.9. Conclusión**

El análisis realizado demuestra que los principales riesgos en la conexión de servidores de videojuegos online están relacionados con ataques externos, pérdida de información, problemas de escalabilidad y seguridad en la comunicación.

Para mejorar el proyecto LP-08 se recomienda implementar una arquitectura basada en servicios escalables, acompañada de herramientas de protección como mitigación DDoS, firewalls, sistemas IDS/IPS, cifrado de comunicaciones, autenticación segura y monitoreo constante.

La combinación de estas tecnologías permitirá obtener un sistema más estable, seguro y preparado para soportar una gran cantidad de jugadores manteniendo una conexión confiable y eficiente.

---

## 2. Servidor P2P (Peer-to-Peer)

### **2.1 Exposicion de la IP**

<ins>**Descripción**</ins>

Cada nodo conoce la IP de los demás para poder conectarse. Esto permite que cualquier jugador identifique la ubicación aproximada de otro (geolocalización por IP) o lo someta a ataques dirigidos (DDoS, port scanning), algo que en un modelo cliente-servidor tradicional nunca se expone.

### Solución:

Implementar:

- STUN/TURN
- Photon Engine
- Steam Networking Scokets
- Unity Realy / Unity Netcode for GameObjects 
- DTLS
- libsodium / NaCI
- Noise Protocol Framework

---

### **2.2 Man-in-the-Middle (MITM)**

<ins>**Descripción**</ins>

Al no haber un servidor central que valide y cifre las comunicaciones de forma uniforme, un atacante en la misma red o interceptando el tráfico pueden posicionarse entre dos nodos, leer o alterar los datos. 

Cada nodo conoce la IP de los demás para poder conectarse. Esto permite que cualquier jugador identifique la ubicación aproximada de otro (geolocalización por IP) o lo someta a ataques dirigidos (DDoS, port scanning), algo que en un modelo cliente-servidor tradicional nunca se expone.

---

### **Amplificación de tráfico**

<ins>**Descripción**</ins>

El protoco P2P usa UDP, es susceptible a ataques de amplificación. Un ataquente puede enviar paquetes pequeños falsificando la IP de la víctima, y los nodos responden con paquetes mucho mas grandes hacia esa IP falsificada, saturando la conexion.

---

### **Vulnerabilidad del NAT traversal (STUN/TURN/UPnP)**

<ins>**Descripción**</ins>

Los mecanismo usados para esquivar el NAT pueden ser explotaos, un UPnP mal configurado permite que un atacante en la misma red local abra puertos no autorizados en el router de la víctima.
