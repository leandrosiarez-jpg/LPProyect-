# CAN Bus: La Red Interna del Vehículo

Cuando entendí que un auto tiene una red interna de comunicaciones, todo lo de la materia empezó a tener más sentido. El **CAN Bus** (Controller Area Network) es exactamente eso: el protocolo que conecta todos los sensores, módulos y actuadores del vehículo entre sí, sin necesidad de que cada uno tenga un cable directo a la ECU.

Es, en términos de redes, el equivalente al switch y los [sockets](../../../MAIN_VAULT/Socket.md) de una red local.

---

## ¿Qué es el CAN Bus?

- **Definición**: Protocolo de comunicación serial diseñado para que múltiples dispositivos electrónicos se comuniquen entre sí en tiempo real sin un servidor central intermediando cada mensaje.
- **Arquitectura**: Todos los nodos (sensores y módulos) están conectados al mismo par de cables trenzados. Cualquier nodo puede emitir un mensaje y todos los demás lo reciben; cada uno decide si ese mensaje le corresponde o no.
- **Velocidad**: Opera entre 125 Kbps y 1 Mbps según la red del vehículo (baja velocidad para carrocería, alta velocidad para motor y frenos).

---

## Comparativa con conceptos de red

| Concepto automotriz | Equivalente en redes |
| :--- | :--- |
| CAN Bus (el cable) | Medio físico / backbone de la red |
| Mensaje CAN con ID | Paquete con dirección de destino |
| ECU principal | Servidor / nodo SDN Norte |
| Sensor o módulo | [Endpoint](../../../MAIN_VAULT/Endpoint.md) / terminal |
| ID de mensaje prioritario | QoS (Quality of Service) |

---

## Cómo viaja un mensaje en el CAN Bus

1. Un sensor detecta un cambio (por ejemplo, el APS registra que el conductor pisó el acelerador).
2. Convierte esa variación en una señal eléctrica y la encapsula en un **frame CAN**: un paquete con un ID de mensaje, los datos y bits de verificación de errores.
3. El frame viaja por el bus. Todos los nodos lo reciben simultáneamente.
4. Cada nodo lee el ID del mensaje y decide si debe procesarlo o ignorarlo.
5. La ECU, que escucha todos los mensajes relevantes, recibe el dato y ejecuta su lógica.

Este mecanismo es análogo al flujo que describe [Comunicacion y Documentacion](../../../MAIN_VAULT/Comunicacion_y_Documentacion.md): los datos viajan desde los endpoints hasta el servidor a través de un canal de transporte estructurado.

---

## Arbitraje: cómo se resuelven los conflictos

Si dos nodos intentan enviar un mensaje al mismo tiempo, el CAN Bus tiene un mecanismo de **arbitraje por prioridad de ID**: el mensaje con el ID de número más bajo gana el bus automáticamente. El otro nodo detecta la colisión y espera.

Esto es el equivalente automotriz de los **locks y semáforos** que describe [Gestion de Hilos y Procesos](../../../MAIN_VAULT/Gestion_de_Hilos_y_Procesos.md): el sistema garantiza que los procesos críticos no se interrumpan entre sí ni pierdan datos.

La lógica completa de qué mensajes tienen prioridad sobre cuáles se desarrolla en [Jerarquia_de_Señales.md](./Jerarquia_de_Señales.md).

---

## Limitaciones y seguridad

El CAN Bus fue diseñado para la confiabilidad, no para la seguridad. En su versión original, cualquier nodo de la red puede enviar cualquier mensaje sin autenticación. Esto es un problema serio en vehículos modernos que admiten conexiones externas (OBD-II, Bluetooth, conectividad celular).

Las soluciones de seguridad aplicadas sobre el CAN Bus se explican en [Protocolos_Seguridad.md](./Protocolos_Seguridad.md).
