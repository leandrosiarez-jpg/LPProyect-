# ECU: El Servidor Central del Vehículo

La **ECU** (Engine Control Unit) es la computadora principal del motor. Recibe datos de todos los sensores, los procesa en tiempo real y decide qué órdenes enviar a los actuadores. En términos de redes, opera exactamente como un servidor central con acceso privilegiado a todos los endpoints de la red.

---

## Rol de la ECU en la arquitectura del vehículo

Si el [CAN Bus](./CAN_Bus.md) es el medio de transporte, la ECU es el destino final de los datos críticos. No es el único módulo inteligente del vehículo (hay módulos para la transmisión, los frenos, la carrocería), pero es el de mayor jerarquía para todo lo relacionado con el motor.

Su posición en la arquitectura es equivalente al **Software "Norte"** del modelo [SDN](../../../MAIN_VAULT/Redes_y_Conectividad.md): posee acceso padre sobre los actuadores del motor y puede priorizar, limitar o anular señales según el estado del sistema.

---

## ¿Qué procesa la ECU?

| Input recibido | Decisión que toma | Output que genera |
| :--- | :--- | :--- |
| Señal del APS (posición del pedal) | Calcular demanda de torque | Señal de apertura de inyectores |
| Pulsos de CKP/CMP | Determinar el momento exacto de inyección y encendido | Disparo sincronizado de inyectores y bobinas |
| Dato del MAF (flujo de aire) | Calcular la cantidad de combustible necesaria | Tiempo de apertura del inyector (pulso de inyección) |
| Temperatura del ECT | Ajustar mezcla en frío, proteger el motor en calor | Enriquecimiento de mezcla o limitación de potencia |
| Señal del O2 (Lambda) | Evaluar si la combustión fue eficiente | Corrección del pulso de inyección en el siguiente ciclo |
| Presión del FRP | Verificar consistencia del sistema de combustible | Ajuste de la bomba de alta presión |

---

## La ECU como sistema de gestión de procesos

La ECU no ejecuta una sola tarea: corre múltiples rutinas en paralelo, cada una con su propia frecuencia de actualización. Algunas se ejecutan cada pocos milisegundos (control de inyección), otras cada cientos de milisegundos (diagnóstico de sensores).

Esta concurrencia genera exactamente el tipo de conflictos que describe [Gestion de Hilos y Procesos](../../../MAIN_VAULT/Gestion_de_Hilos_y_Procesos.md): si dos rutinas necesitan el mismo dato al mismo tiempo, el sistema debe resolver cuál tiene prioridad. Esa lógica se desarrolla en [Jerarquia_de_Señales.md](./Jerarquia_de_Señales.md).

---

## Objetividad del sistema

La ECU es el punto donde la [Subjetividad](../../../MAIN_VAULT/Subjetividad.md) del conductor se convierte definitivamente en [Objetividad](../../../MAIN_VAULT/Objetividad.md). La intención de acelerar llega como un voltaje variable; la ECU la transforma en un pulso de inyección con una duración exacta, medida en microsegundos. No hay interpretación: hay protocolo.

---

## Diagnóstico y no repudio

La ECU registra códigos de falla (DTC - Diagnostic Trouble Codes) cada vez que detecta un valor fuera de rango. Estos registros tienen marca temporal y no pueden ser alterados sin herramientas específicas, lo que los convierte en un mecanismo de [No Repudio](../../../MAIN_VAULT/No_Repudio.md) con [Time Stamping](../../../MAIN_VAULT/Time_Stamping.md): ante una falla, el sistema puede decir exactamente qué sensor falló, qué valor reportó y en qué momento.

---

## Relación con otros archivos

- Los datos que recibe la ECU los generan los [Sensores_Inputs.md](./Sensores_Inputs.md).
- Los datos viajan por el [CAN_Bus.md](./CAN_Bus.md).
- Las órdenes que emite van a los [Actuadores_Outputs.md](./Actuadores_Outputs.md).
- La seguridad de su hardware la garantizan los protocolos de [Protocolos_Seguridad.md](./Protocolos_Seguridad.md).
