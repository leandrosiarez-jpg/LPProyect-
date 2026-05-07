# Flujo de Datos en el Vehículo

Un auto moderno no se maneja solo con mecánica: se maneja con datos. Cada vez que el conductor pisa el acelerador, frena o simplemente enciende el motor, se dispara una cadena de información que recorre toda la red interna del vehículo. Este archivo es el punto de entrada para entender ese proceso.

## ¿Cómo se organiza el flujo?

El flujo de datos en un vehículo sigue la misma lógica que cualquier red administrada: hay nodos que generan información, un medio por donde viaja, un procesador central que decide qué hacer con ella, y actuadores que ejecutan la respuesta.

```
[Sensores] → [CAN Bus] → [ECU] → [Actuadores]
```

Cada uno de esos eslabones tiene su propia complejidad. Por eso este proyecto los desglosa en archivos separados:

## Archivos del proyecto

| Archivo | ¿Qué explica? |
| :--- | :--- |
| [Sensores_Inputs.md](./Sensores_Inputs.md) | Los endpoints que capturan datos del mundo físico |
| [CAN_Bus.md](./CAN_Bus.md) | El protocolo de red interno que transporta la información |
| [ECU.md](./ECU.md) | El servidor central que procesa y decide |
| [Actuadores_Outputs.md](./Actuadores_Outputs.md) | Las respuestas concretas que el sistema ejecuta |
| [Jerarquia_de_Señales.md](./Jerarquia_de_Señales.md) | Cómo se priorizan los datos en situaciones de conflicto |
| [Protocolos_Seguridad.md](./Protocolos_Seguridad.md) | Zero Trust, TPM, HSM aplicados al vehículo |

## Relación con los conceptos de la materia

El flujo completo input → procesamiento → output es la versión automotriz de lo que estudiamos en [Comunicacion y Documentacion](../../../MAIN_VAULT/Comunicacion_y_Documentacion.md): una señal subjetiva (la intención del conductor) que el sistema transforma en un protocolo objetivo y automatizado.

El objetivo de este proyecto es demostrar que administrar una red de computadoras y administrar un vehículo moderno son, en el fondo, el mismo problema.

**Vínculo al índice:** [Administración de Sistemas y Redes](../../../MAIN_VAULT/Administración_de_Sistemas_y_Redes.md)
