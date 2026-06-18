# Resumen LP-12 — La Red Interna del Vehículo

**Idea central**

Un vehículo moderno es una red de computadoras. Cada sensor es un endpoint, cada señal es un paquete de datos, y la ECU es el servidor central. Este proyecto demuestra que administrar una red y administrar un auto son, en el fondo, el mismo problema.

---

## Componentes principales

### Sensores / Inputs
| Sensor | Función en red |
|---|---|
| APS | Convierte la subjetividad del conductor en dato objetivo |
| CKP / CMP | Clock del sistema, evita inconsistencias de datos |
| MAF | Monitor de "ancho de banda" de aire |
| O2 / Lambda | ACK de confirmación de combustión |
| FRP | Mantiene objetividad constante de presión |
| ECT | Monitor de estado del hardware |
| TPMS | Endpoints inalámbricos por rueda |
| ABS / TCS | Controladores de tráfico en tiempo real |

### CAN Bus (transporte)
- Red interna del vehículo, equivalente a un switch + sockets
- Todos los nodos comparten el mismo canal, cada uno filtra los mensajes que le corresponden
- Arbitraje por ID: el mensaje con ID más bajo gana ante colisiones (equivalente a locks/semáforos)
- Limitación: no tiene autenticación nativa → requiere capas de seguridad adicionales

### ECU (servidor central)
- Equivalente al nodo Norte del modelo SDN
- Corre múltiples rutinas en paralelo con distintas frecuencias
- Registra códigos de falla (DTC) con timestamp → No Repudio

### Actuadores / Outputs
- Inyectores, bobinas, bomba FRP, moduladores ABS, pantalla HMI
- Muchos trabajan con sensor de retroalimentación → lazo cerrado (equivalente al handshake)

---

## Jerarquía de señales

| Prioridad | Señales | Equivalente en redes |
|---|---|---|
| Alta | ABS, Airbag, CKP/CMP | Procesos críticos, no interrumpibles |
| Media | APS→inyectores, MAF+O2 | Procesos con lock activo |
| Baja | TPMS, CarPlay, climatizador | Procesos diferibles |

La ECU puede limitar potencia o ignorar pedidos del conductor si detecta estado crítico → acceso padre sobre toda la red.

---

## Seguridad

| Concepto | Aplicación en el vehículo |
|---|---|
| Zero Trust | TPMS: solo acepta señales de sensores con ID registrado |
| TPM | Chip en la ECU que valida que el firmware es original |
| HSM | Gestiona claves de cifrado para actualizaciones OTA |
| No Repudio + Time Stamping | DTCs con marca temporal, no alterables |
| Puerto OBD-II | Vector de ataque físico más accesible, requiere autenticación de herramientas |

---

## Conexión con el MAIN_VAULT

El proyecto referencia directamente: Subjetividad, Objetividad, Endpoint, Socket, Gestión de Hilos y Procesos, Redes y Conectividad, Seguridad y Jerarquía, No Repudio, Time Stamping, TPM, HSM, Comunicación y Documentación.
