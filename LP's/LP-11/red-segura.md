# RedSegura: Simulador de redes y seguridad

**RedSegura** es una Single Page Application (SPA) interactiva diseñada para visualizar el flujo de datos en una red, el comportamiento de los sistemas bajo carga concurrente y la efectividad de las medidas de ciberseguridad ante ataques comunes.

## Contenidos
1. [Fundamentos de redes](#fundamentos-de-redes)
2. [Arquitectura del sistema](#arquitectura-del-sistema)
3. [Metodología de hacking ético y defensa](#metodologia-de-hacking-etico-y-defensa)
4. [Simulación de concurrencia](#simulacion-de-concurrencia)
5. [Tecnologías utilizadas](#tecnologias-utilizadas)

---

## Fundamentos de redes

Este proyecto se basa en los conceptos teóricos de [Redes y Conectividad.md](../../MAIN_VAULT/Redes_y_Conectividad.md), definiendo los roles principales en la comunicación:

* **Cliente:** Dispositivo que inicia la solicitud.
* **Servidor:** Entidad que procesa la petición. La conexión lógica entre ambos se realiza mediante un [Socket.md](../../MAIN_VAULT/Socket.md).
* **Flujo de datos:** Los paquetes viajan siguiendo los protocolos establecidos en el [Marco Tecnico.md](../../MAIN_VAULT/Marco_Tecnico.md).

---

## Arquitectura del sistema

Para la construcción de esta herramienta, se han seguido principios de [Comunicacion y Documentacion.md](../../MAIN_VAULT/Comunicacion_y_Documentacion.md):

* **Gestión del Sistema:** Inspirado en la [Administración de Sistemas y Redes.md](../../MAIN_VAULT/Administración_de_Sistemas_y_Redes.md).
* **Interfaz (Frontend):** Simulación de un [Endpoint.md](../../MAIN_VAULT/Endpoint.md).
* **Lógica:** Implementación basada en el [Marco Tecnico.md](../../MAIN_VAULT/Marco_Tecnico.md).

---

## Metodología de hacking ético y defensa

La seguridad se aborda desde la [Seguridad y Jerarquia.md](../../MAIN_VAULT/Seguridad_y_Jerarquia.md):

### Fase de ataque
El simulador muestra cómo un atacante puede comprometer la [Objetividad.md](../../MAIN_VAULT/Objetividad.md) de los datos. Se analiza el comportamiento técnico evitando la [Subjetividad.md](../../MAIN_VAULT/Subjetividad.md).

### Estrategias de defensa
* **Integridad:** Se utilizan métodos de [Time Stamping.md](../../MAIN_VAULT/Time_Stamping.md).
* **Autenticidad:** Aplicación del principio de [No Repudio.md](../../MAIN_VAULT/No_Repudio.md).
* **Hardware Seguro:** Simulación de protección basada en [HSM.md](../../MAIN_VAULT/HSM.md) y [TPM.md](../../MAIN_VAULT/TPM.md).

---

## Simulacion de concurrencia

Manejar múltiples usuarios requiere una correcta [Gestion de Hilos y Procesos.md](../../MAIN_VAULT/Gestion_de_Hilos_y_Procesos.md).

* **Optimización:** Escenarios donde la [Inteligencia Artificial.md](../../MAIN_VAULT/Inteligencia_Artificial.md) ayuda al balanceo de carga.

---

## Tecnologias utilizadas

| Tecnología | Función |
| :--- | :--- |
| **HTML5 / CSS3 / JS** | Desarrollo del simulador interactivo. |

