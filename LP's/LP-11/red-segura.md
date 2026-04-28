# RedSegura: Simulador de redes y seguridad

**RedSegura** es una Single Page Application (SPA) interactiva diseñada para visualizar el flujo de datos en una red, el comportamiento de los sistemas bajo carga concurrente y la efectividad de las medidas de ciberseguridad ante ataques comunes.

## Contenidos
1. [Fundamentos de redes](#1-fundamentos-de-redes)
2. [Arquitectura del sistema](#2-arquitectura-del-sistema)
3. [Metodología de hacking ético y defensa](#3-metodología-de-hacking-ético-y-defensa)
4. [Simulación de concurrencia](#4-simulación-de-concurrencia)
5. [Tecnologías utilizadas](#5-tecnologías-utilizadas)

---

## 1. Fundamentos de redes

Para entender este proyecto, primero definimos los roles principales en la comunicación digital:

* **Cliente:** Es el dispositivo (laptop, móvil) que inicia una solicitud de recursos o servicios. En **RedSegura**, se representa como la interfaz de usuario que envía datos.
* **Servidor:** Es la entidad (torre de servidor) que espera solicitudes, las procesa y envía una respuesta. Es el "cerebro" que gestiona la lógica y los datos.

### El flujo de datos
En la simulación, verás cómo un **"paquete"** viaja desde el cliente al servidor. Este proceso representa el protocolo HTTP/HTTPS básico donde la información se fragmenta para ser transportada.

---

## 2. Arquitectura del sistema

El diseño se centra en la interactividad visual:
* **Frontend interactivo:** Uso de formularios para enviar "datos" y disparar animaciones CSS.
* **Simulación de backend:** Implementación de lógica en JavaScript mediante `setTimeout` y `Promises` para replicar la latencia del servidor sin necesidad de una base de datos real.

---

## 3. Metodología de hacking ético y defensa

El simulador permite alternar entre un estado de vulnerabilidad y un estado protegido para observar la **Metodología de hacking**:

### Fase de ataque (Modo hacker)
1.  **Reconocimiento:** El atacante identifica el punto final del servidor.
2.  **Escaneo:** Búsqueda de puertos o formularios vulnerables (ej. Inyección).
3.  **Acceso:** Intento de interceptar el paquete o saturar el sistema (Fuerza Bruta).

### Estrategias de defensa
Podrás activar módulos de seguridad en tiempo real:
* **Cifrado (Encryption):** Los datos del paquete se vuelven ilegibles durante el trayecto.
* **Firewall:** Bloquea peticiones maliciosas detectadas por patrones sospechosos.

> **Nota:** Si la defensa está activa, la animación de ataque mostrará un "bloqueo", garantizando que el servidor permanezca íntegro.

---

## 4. Simulación de concurrencia

Uno de los mayores retos en redes es el manejo de múltiples usuarios simultáneos.

* **Simulación masiva:** El botón "Simular 100 usuarios" genera ráfagas de peticiones.
* **Saturación:** Si el tráfico supera el umbral definido en el código JS, el servidor cambiará visualmente (ej. color rojo) para indicar estrés.
* **Balanceo de carga:** Explicación visual de cómo se redistribuiría el tráfico para evitar la caída del sistema.

---

## 5. Tecnologías utilizadas

El proyecto está construido puramente con tecnologías web estándar para facilitar su despliegue en cualquier navegador:

| Tecnología | Función |
| :--- | :--- |
| **HTML5** | Estructura semántica de la interfaz y componentes. |
| **CSS3** | Diseño responsivo y animaciones de paquetes (`keyframes`). |
| **JavaScript** | Lógica de simulación, manejo de eventos y estados de seguridad. |

---

