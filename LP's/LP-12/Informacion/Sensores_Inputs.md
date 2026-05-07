# Sensores como Inputs del Vehículo

Los sensores son los [endpoints](../../../MAIN_VAULT/Endpoint.md) del vehículo. Son el punto exacto donde el mundo físico se convierte en dato digital: temperatura, presión, posición, velocidad. Sin ellos, la ECU no tiene información para procesar y el sistema no puede responder.

## ¿Qué hace un sensor en términos de red?

Un sensor cumple el mismo rol que cualquier terminal en una red: genera datos y los pone a disposición del servidor central. Lo interesante es que la mayoría de esos datos nacen de algo subjetivo (la intención del conductor o las condiciones del entorno) y el sistema los tiene que convertir en señales objetivas y procesables.

Esto es exactamente la dinámica que describe el archivo de [Subjetividad](../../../MAIN_VAULT/Subjetividad.md): el input del usuario es ambiguo por naturaleza, y el sistema debe mitigarlo para operar con precisión.

---

## Tabla de Sensores Principales

| Sensor | Sigla | Dato que genera | Naturaleza del dato |
| :--- | :--- | :--- | :--- |
| Accelerator Pedal Sensor | APS | Voltaje proporcional a la posición del pedal | Analógico / subjetivo |
| Crankshaft Position Sensor | CKP | Pulsos de posición del cigüeñal | Digital / sincronización |
| Camshaft Position Sensor | CMP | Posición del árbol de levas | Digital / sincronización |
| Mass Air Flow | MAF | Flujo de aire en gramos por segundo | Analógico / métrica de rendimiento |
| Engine Coolant Temperature | ECT | Temperatura del refrigerante en °C | Analógico / estado del hardware |
| Oxygen / Lambda | O2 | Porcentaje de oxígeno en el escape | Analógico / retroalimentación |
| Fuel Rail Pressure | FRP | Presión actual en el riel de combustible | Analógico / consistencia |
| Tire Pressure Monitoring System | TPMS | Presión y temperatura por rueda | Inalámbrico / endpoint remoto |
| Anti-lock Braking / Traction Control | ABS/TCS | Velocidad angular de cada rueda | Digital / seguridad activa |

---

## Categorías de sensores por función de red

### Sensores de sincronización
**CKP y CMP** marcan el ritmo del sistema. Funcionan como el "clock" de la red: sin ellos, los procesos de inyección y encendido no pueden coordinarse. Un desfase en estas señales genera lo que en [Gestion de Hilos y Procesos](../../../MAIN_VAULT/Gestion_de_Hilos_y_Procesos.md) llamamos inconsistencia de datos.

### Sensores de carga subjetiva
**APS** es el caso más claro de [Subjetividad](../../../MAIN_VAULT/Subjetividad.md) en el sistema: el pie del conductor no ejerce siempre la misma fuerza, no tiene la misma velocidad, no es lineal. El sensor convierte esa variación humana en un voltaje que la ECU puede interpretar de forma consistente.

### Sensores de retroalimentación
**O2 y FRP** cierran el ciclo. No solo generan datos: confirman si la acción anterior fue correcta. Son el mecanismo de "acuse de recibo" del sistema, equivalente al ACK en protocolos de red.

### Endpoints inalámbricos
**TPMS** es el caso más interesante desde el punto de vista de redes. Cada rueda transmite su estado de forma inalámbrica, lo que introduce un problema de autenticación: ¿cómo sabe el sistema que esa señal viene de sus propias ruedas y no de un vehículo externo? Esto se resuelve con los protocolos que describe [Protocolos_Seguridad.md](./Protocolos_Seguridad.md).

---

## Flujo del dato desde el sensor

Una vez que el sensor genera su señal, esa información viaja por la red interna del vehículo hacia la ECU. Ese camino lo explica [CAN_Bus.md](./CAN_Bus.md).

**Vínculo al índice:** [Administración de Sistemas y Redes](../../../MAIN_VAULT/Administración_de_Sistemas_y_Redes.md)
