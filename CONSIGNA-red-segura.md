# RedSegura - Simulador de redes y seguridad

## Descripción del proyecto
**RedSegura** es una Single Page Application (SPA) interactiva diseñada para la visualización técnica de flujos de datos, gestión de concurrencia y protocolos de ciberseguridad. El simulador permite experimentar con el comportamiento de sistemas bajo carga y la efectividad de defensas ante ataques comunes.

---

## Objetivos de la implementación

### Arquitectura y flujo de red
* **Simulación de sockets:** Implementar la conexión lógica entre el Cliente (solicitante) y el Servidor (procesador).
* **Visualización de paquetes:** Representar el trayecto de los datos siguiendo los protocolos definidos en el marco técnico.
* **Endpoints:** Diseñar la interfaz para que funcione como un punto final de comunicación real.

### Gestión de concurrencia
* **Hilos y procesos:** El sistema debe demostrar cómo se administran múltiples solicitudes simultáneas.
* **Optimización con IA:** Implementar lógica de balanceo de carga asistida por algoritmos que detecten picos de tráfico.

### Laboratorio de ciberseguridad
**El simulador debe permitir ejecutar escenarios de hacking ético y aplicar medidas de protección:**

* **Fase de ataque:** Simulación de compromisos a la **Objetividad** y la **Integridad** de la información.
* **Estrategias de defensa:**
    * **Time stamping:** Validación temporal de paquetes para evitar ataques de repetición.
    * **No repudio:** Garantizar la autenticidad y el registro de las transacciones.
    * **Seguridad por hardware:** Simulación de capas de protección basadas en **HSM** (Hardware Security Module) y **TPM** (Trusted Platform Module).

---

## Requerimientos técnicos
* **Lenguajes:** HTML5, CSS3 y JavaScript nativo.
* **Estructura:** SPA (Single Page Application) sin recargas de página.
* **Interfaz:** Panel de control para disparar eventos (ataques/carga) y una consola de eventos técnica.

---

## Estructura de contenidos relacionados
**Para el desarrollo, se deben considerar los siguientes documentos de referencia:**
* [Redes y Conectividad.md](/MAIN_VAULT/Redes_y_Conectividad.md) (Fundamentos teóricos)
* [Socket.md](/MAIN_VAULT/Socket.md) (Conexión lógica)
* [Seguridad y Jerarquia.md](/MAIN_VAULT/Seguridad_y_Jerarquia.md) (Modelos de defensa)
* [Gestion de Hilos y Procesos.md](/MAIN_VAULT/Gestion_de_Hilos_y_Procesos.md) (Lógica de concurrencia)

---
