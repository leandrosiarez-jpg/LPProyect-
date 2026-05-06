# Actuadores como Outputs del Vehículo

Si los [sensores](Sensores_Inputs.md) son los inputs, los actuadores son los outputs: el punto donde la decisión de la [ECU](ECU.md) se convierte en acción física. Un actuador recibe una señal eléctrica y la transforma en movimiento, presión, calor o luz.

En términos de red, son los dispositivos de salida: ejecutan la orden y, en muchos casos, confirman que la ejecutaron correctamente mediante un sensor de retroalimentación.

---

## ¿Qué hace un actuador en términos de red?

Un actuador es el extremo receptor del flujo de datos. No genera información por sí mismo (eso es tarea de los sensores), pero muchos actuadores trabajan en par con un sensor que verifica su acción. Esa retroalimentación cierra el ciclo y convierte al sistema en un **lazo cerrado**, equivalente al handshake de confirmación en protocolos de red.

---

## Principales actuadores y sus outputs

### Inyectores de combustible
- **Reciben**: Señal de pulso de la ECU (duración en microsegundos).
- **Ejecutan**: Abren y cierran una válvula para inyectar exactamente la cantidad de combustible calculada.
- **Retroalimentación**: El sensor O2 confirma si la cantidad fue correcta en el ciclo siguiente.
- **Analogía**: Son como paquetes de datos enviados con un payload exacto. El sensor Lambda es el ACK.

### Bobinas de encendido
- **Reciben**: Señal de disparo sincronizada con la posición del cigüeñal (CKP).
- **Ejecutan**: Generan la chispa en el momento preciso para encender la mezcla.
- **Retroalimentación**: El sensor de detonación (knock sensor) detecta si el encendido fue prematuro.

### Bomba de alta presión (FRP)
- **Reciben**: Señal de ajuste de la ECU cuando la presión cae fuera del rango objetivo.
- **Ejecutan**: Aumentan o reducen la presión en el riel de combustible.
- **Analogía con redes**: Es un sistema que busca la [Objetividad](../MAIN_VAULT/Objetividad.md) constante, manteniendo un valor consistente para que el resto del sistema opere sin variaciones.

### Moduladores ABS/TCS
- **Reciben**: Señal de intervención de la ECU de frenos cuando detecta bloqueo o pérdida de tracción.
- **Ejecutan**: Modulan la presión hidráulica de forma independiente en cada rueda (pueden frenar una rueda y liberar otra en milisegundos).
- **Prioridad**: Son outputs de máxima jerarquía. Ninguna señal de confort o entretenimiento puede interferir con ellos.

### Pantalla y alertas (HMI)
- **Reciben**: Datos de estado de múltiples sensores (TPMS, ECT, nivel de combustible).
- **Ejecutan**: Traducen datos técnicos en información comprensible para el conductor.
- **Analogía**: Son la capa de presentación del sistema, equivalente a la interfaz de usuario en una aplicación de red.

---

## El ciclo completo: del input al output

```
Sensor (input) → CAN Bus (transporte) → ECU (procesamiento) → Actuador (output) → Sensor de retroalimentación → ECU
```

Este ciclo continuo es la base del funcionamiento del vehículo. No es lineal: ocurre en paralelo para decenas de sistemas al mismo tiempo, gestionado por la lógica de prioridades que describe [Jerarquia_de_Señales.md](Jerarquia_de_Señales.md).

**Vínculo al índice:** [Administración de Sistemas y Redes](../MAIN_VAULT/Administración_de_Sistemas_y_Redes.md)
