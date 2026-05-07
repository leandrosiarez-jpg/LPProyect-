## **Analisis de vulnerabilidades**
#### (diagrama de Luca Bonamaison)

El diagrama esta bien estructurado y refleja de manera lógica el flujo de operación y defensa de un sistema en red, integrando correctamente varios de los conceptos clave presentes en las fuentes.

---

### **Defensa de la Disponibilidad y Control de Carga (Nodos E a I)**

El diagrama acierta al incluir la gestión de concurrencia y la sincronización para evitar conflictos, el agotamiento de recursos esta correctamente gestionado al implementar redundancia y balanceo de ccarga para distribuir el trafico y evitar que un solo recurso se vea sobrepasado.

---

### **Detección de Ataques por Saturacion (Nodo K)**

En una situación de alta carga, es fundamental distinguir el tráfico legítimo de un ataque DoS o DDoS.

- **Moniteoreo activo:** se sugiere el uso de Sistemas de Detección de Intrusiones (IDS) como Snort u OSSEC para analizar el tráfico en tiempo real e identificar patrones de ataque antes de que el sistema colapse


---

### **Aplicación de Defensas y Capacidad de Respuesta (Nodos O a T)**

Ante una carga inusual que resulte en un ataque, el diseño debe ser proactivo:

- **Validación de acceso:** los mecanismos de autenticación robustos y los controles de acceso son la primera línea de defensa para garantizar que solo personal autorizado utilice los recursos.

- **Escalabilidad:** capacidad de escalado, diseñado para que la infraestructura crezca dinámicamente ante aumentos repentinos de tráfico.

- **Restaurar integridad:** En caso de que la carga logre comprometer algún dato, los registros de auditoría (Logs) y las verificaciones regulares son esenciales para detectar y corregir modificaciones no autorizadas.

---

### **Registro y Auditoría Final (Nodo V)**

El nodo de Logs al final del proceso es un pilar de la seguridad:

- **Monitoreo y Verificación:** : Las fuentes indican que los registros detallados de las actividades permiten monitorear y verificar eventos, lo cual es crítico para el análisis posterior a un incidente de saturación.

---
---

Sugerencia:
Al ser debido a una situacion general, se sufgiere la integración de soluciones basadas en la nube, defensas aptas para filtrar el tráfico malicioso antes de que llegue a tu infraestructura principal, permitiendo que el tráfico normal fluya sin interrupciones.
