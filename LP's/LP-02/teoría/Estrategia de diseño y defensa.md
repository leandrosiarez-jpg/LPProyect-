## Estrategias de diseño y defensa
----
### **1. Garantizar la disponabilidad del sistema**

El diseño debe <u>asegurar</u> que los datos y servicios esten accesibles y utilizables siempre que los usuarios autrizados los necesiten. Es necesario implementar:
- **Redundancia y Blanaceo de Carga:**
Se deben implementar soluciones que distribuyan el tráfico entre diferentes servidores para evitar la sobrecarga de un solo recurso.

- **Capacidad de Escalado:**
El sistema debe estar diseñado para escalar dinámicamente. Esto permite que la infraestructura crezca en respuesta a aumentos repentinos en el número de usuarios o en el tráfico, asegurando que la operación sea continua.

----

### **2. Protección contra el Agotamiento de Recuros:**

Una vulnerabilidad crítica en sistemas multiusuario es el agotamiento de recursos, donde un exceso de peticiones (ya sea por uso legítimo masivo o por ataques Dos/DDos) ralentiza o bloquea la aplicación. Para prevenirlo, el diseño debe incliur:
- **Sistemas de mitigación de DDoS:**
Servicios especializados que detectan y flitran el tráfico malicioso antes de que llegue a los sistemas críticos, permitiendo que el tráfico normal de los usuarios fluya sin interrupciones.

- **Firewalls e IDS/IPS:**
Configurar sistemas de detección y prevención de intrusos para bloquear patrones de ataque conocidos que busquen inhabilitar la comunicación entre dispositivos.

---

### **3. Implementación de Seguridad en Capas**
Para entorno donde la continuidad es vital, se recomienda una seguridad en capa que incliuye:
- **Listas de Control de Acceso (ACL):**
Para gestionar quién puede acceder a qué recursos de red.

- **Mecanismos de Autenticación Robustos:**
Para aegurar que el acceso simultáneo sea solo por parte de personal autorizado.

- **Cifrado de Comunicaciones:**
Aplicar criptografía en la transmisión de datos para que el uso compartido de la red no comprometa la confidencialidad ni la integridad de la información.

---

### **4. Gestión y Monitoreo Conitnuo**

Un sistema bien diseñado requiere una gestión proactiva para mantenerse funcional:

- **Monitoreo de Red:**
Observar el tráfico de red de forma constante para identificar actividades anómalas o cuellos de botello.

- **Automatización de Controles:**
El empleo de modelops que automaticen y centralicen la gestión de los controles de seguridad mejora la eficiencia operativa y la respuesta ante incidentes.

- **Planes de Contingencia y Backups:**
Establecer estrategias preparadas para responder a emergencias y asegurar la continuidad del negocio en caso de fallos sistémicos.
