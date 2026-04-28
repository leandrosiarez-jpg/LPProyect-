# RedSegura: Simulador de redes y seguridad 🌐🛡️

**RedSegura** es una Single Page Application (SPA) interactiva diseñada para visualizar el flujo de datos en una red, el comportamiento de los sistemas bajo carga concurrente y la efectividad de las medidas de ciberseguridad ante ataques comunes.

## 📋 Contenidos
1. [Fundamentos de redes](#fundamentos-de-redes)
2. [Arquitectura del sistema](#arquitectura-del-sistema)
3. [Metodología de hacking ético y defensa](#metodología-de-hacking-ético-y-defensa)
4. [Simulación de concurrencia](#simulación-de-concurrencia)
5. [Tecnologías utilizadas](#tecnologías-utilizadas)

---

## 1. Fundamentos de redes

Este proyecto se basa en los conceptos teóricos de [Redes y Conectividad.md](./MAIN%20VAULT/Redes%20y%20Conectividad.md), definiendo los roles principales en la comunicación:

* **Cliente:** Dispositivo que inicia la solicitud.
* **Servidor:** Entidad que procesa la petición. La conexión lógica entre ambos se realiza mediante un [Socket.md](./MAIN%20VAULT/Socket.md).
* **Flujo de datos:** Los paquetes viajan siguiendo los protocolos establecidos en el [Marco Tecnico.md](./MAIN%20VAULT/Marco%20Tecnico.md).

---

## 2. Arquitectura del sistema

Para la construcción de esta herramienta, se han seguido principios de [Comunicacion y Documentacion.md](./MAIN%20VAULT/Comunicacion%20y%20Documentacion.md) para asegurar un código limpio y escalable:

* **Gestión del Sistema:** Inspirado en la [Administración de Sistemas y Redes.md](./MAIN%20VAULT/Administración%20de%20Sistemas%20y%20Redes.md).
* **Interfaz (Frontend):** Simulación de un [Endpoint.md](./MAIN%20VAULT/Endpoint.md) interactivo donde el usuario final interactúa con la red.
* **Lógica (Backend simulado):** Aunque es una SPA, la lógica de respuesta emula procesos de servidor reales.

---

## 3. Metodología de hacking ético y defensa

La seguridad se aborda desde la [Seguridad y Jerarquia.md](./MAIN%20VAULT/Seguridad%20y%20Jerarquia.md), analizando vulnerabilidades y protecciones:

### Fase de ataque (Modo hacker)
El simulador muestra cómo un atacante puede comprometer la [Objetividad.md](./MAIN%20VAULT/Objetividad.md) de los datos mediante interceptación. Se analiza el comportamiento desde una perspectiva técnica, evitando la [Subjetividad.md](./MAIN%20VAULT/Subjetividad.md) en el análisis de riesgos.

### Estrategias de defensa
* **Integridad:** Se utilizan métodos de [Time Stamping.md](./MAIN%20VAULT/Time%20Stamping.md) para validar cuándo se enviaron los datos.
* **Autenticidad:** Aplicación del principio de [No Repudio.md](./MAIN%20VAULT/No%20Repudio.md).
* **Hardware Seguro:** El sistema simula la protección de módulos físicos como el [HSM.md](./MAIN%20VAULT/HSM.md) y el [TPM.md](./MAIN%20VAULT/TPM.md) para el almacenamiento de llaves criptográficas.

---

## 4. Simulación de concurrencia

El manejo de múltiples usuarios simultáneos es crítico y se fundamenta en la [Gestion de Hilos y Procesos.md](./MAIN%20VAULT/Gestion%20de%20Hilos%20y%20Procesos.md).

* **Saturación:** Visualización de qué ocurre cuando los procesos exceden la capacidad del sistema.
* **Optimización:** Se plantean escenarios donde la [Inteligencia Artificial.md](./MAIN%20VAULT/Inteligencia%20Artificial.md) podría ayudar a predecir picos de tráfico y balancear la carga de forma eficiente.

---

## 5. Tecnologías utilizadas

El proyecto utiliza tecnologías estándar descritas en nuestro [Glosario Tecnico.md](./MAIN%20VAULT/Glosario%20Tecnico.md):

| Tecnología | Función |
| :--- | :--- |
| **HTML5** | Estructura base del simulador. |
| **CSS3** | Animaciones de red y diseño visual. |
| **JavaScript** | Motor de simulación y lógica de ciberseguridad. |

---

## 1. Fundamentos de redes

Este proyecto se basa en los conceptos teóricos de [Redes y Conectividad.md](MAIN%20VAULT/Redes%20y%20Conectividad.md), definiendo los roles principales en la comunicación:

* **Cliente:** Dispositivo que inicia la solicitud.
* **Servidor:** Entidad que procesa la petición. La conexión lógica entre ambos se realiza mediante un [Socket.md](MAIN%20VAULT/Socket.md).
