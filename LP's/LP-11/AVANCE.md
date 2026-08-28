# Informe de avance de proyecto: RedSegura

## 1. Resumen ejecutivo
El proyecto RedSegura se define como una Single Page Application (SPA) interactiva orientada a la simulación y visualización técnica de arquitecturas de red, gestión de concurrencia y protocolos de ciberseguridad. El objetivo principal es ofrecer un entorno controlado que permita analizar el comportamiento de los sistemas bajo cargas críticas de tráfico y evaluar la efectividad de diversos mecanismos de defensa ante vectores de ataque comunes.

---

## 2. Marco teórico y componentes del sistema

### A. Arquitectura y flujo de red
El núcleo del simulador modela la comunicación entre nodos mediante abstracciones de red:
* Simulación de sockets: Establecimiento de la conexión lógica bidireccional entre el Cliente (emisor de solicitudes) y el Servidor (procesador de datos), permitiendo visualizar el ciclo de vida de la conexión (apertura, transmisión y cierre).
* Flujo de paquetes: Representación gráfica y lógica del tránsito de unidades de información, mapeando el trayecto de los datos según las reglas de los protocolos base definidos.
* Modelado de endpoints: Exposición de puntos finales de comunicación que actúan como interfaces de interacción dentro de la topología simulada.

### B. Gestión de concurrencia y optimización
Para simular un entorno de producción real, el sistema aborda la problemática del procesamiento simultáneo:
* Modelado de hilos y procesos: Simulación conceptual de cómo el servidor distribuye sus recursos para atender múltiples peticiones en paralelo sin saturar el sistema.
* Lógica de balanceo asistido: Incorporación teórica de algoritmos de optimización para la detección analítica de picos de tráfico, permitiendo una redistribución eficiente de la carga simulada.

### C. Laboratorio de ciberseguridad (Ataque y defensa)
El entorno simula escenarios de riesgo para validar la resiliencia de la infraestructura:
* Fase de ataque: Ejecución controlada de eventos que comprometen la Integridad y la Objetividad de los datos en tránsito.
* Mecanismos de mitigación Proactiva:
  * Time stamping: Inserción de marcas de tiempo para validar la vigencia de los paquetes y neutralizar ataques de repetición (Replay Attacks).
  * No repudio: Garantía de autenticidad mediante el registro inalterable de las transacciones, impidiendo que los actores nieguen su participación.
  * Seguridad anclada en hardware: Simulación lógica de capas de protección basadas en tecnologías criptográficas robustas como HSM (Hardware Security Module) y TPM (Trusted Platform Module) para el resguardo de claves y firmas.

---

## 3. Estado actual del desarrollo

### Arquitectura de documentación base
Se ha consolidado el marco teórico y la estructura de contenidos a través de los siguientes módulos interconectados en el repositorio:
* Redes y conectividad: Fundamentos teóricos de los protocolos de comunicación.
* Socket: especificación de la conexión lógica cliente-servidor.
* Seguridad y jerarquía: Modelos de defensa y niveles de acceso criptográfico.
* Gestión de hilos y procesos: Modelado y lógica de la concurrencia del sistema.

### Definición del stack tecnológico
Se determinó una arquitectura frontend limpia y de alto rendimiento basada en tecnologías web nativas (HTML5, CSS3 y JavaScript), estructurada bajo el patrón de Single Page Application (SPA) para garantizar una experiencia fluida, interactiva y libre de recargas de página durante la visualización de eventos en tiempo real.

---

## 4. Próximos steps
* Diseñar la distribución del panel de control interactivo para el disparo de eventos de carga y ataques.
* Estructurar la consola técnica de eventos que registrará las métricas y alertas del simulador.
* Vincular la lógica de los módulos teóricos con las animaciones de flujo en la interfaz gráfica.
