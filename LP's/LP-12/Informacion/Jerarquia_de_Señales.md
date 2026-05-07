# Jerarquía de Señales en el Vehículo

Un vehículo moderno procesa decenas de señales al mismo tiempo. No todas tienen el mismo peso: una señal de frenado de emergencia no puede esperar a que termine de procesarse la solicitud de cambiar la canción. El sistema necesita una jerarquía clara para saber qué datos atender primero.

Esto es exactamente lo que estudia [Gestion de Hilos y Procesos](../../../MAIN_VAULT/Gestion_de_Hilos_y_Procesos.md) aplicado al mundo automotriz.

---

## Los tres niveles de prioridad

### Prioridad Alta: seguridad activa
Son las señales que, si se demoran o se pierden, pueden resultar en un accidente. El sistema las atiende primero, siempre, sin excepciones.

- **ABS / TCS**: Control de frenos y tracción en situaciones de emergencia.
- **Airbag**: Señal de disparo ante impacto (tiempo de respuesta menor a 30 ms).
- **Señales de sincronización CKP/CMP**: Sin ellas el motor se detiene.

Estas señales tienen asignados los **IDs más bajos** en el [CAN Bus](./CAN_Bus.md), lo que garantiza que ganen el arbitraje automáticamente ante cualquier colisión de mensajes.

### Prioridad Media: gestión del motor
Son las señales que mantienen el motor funcionando de forma eficiente. Se ejecutan en ciclos continuos y no pueden interrumpirse sin generar inconsistencias.

- **APS → inyectores**: El ciclo de aceleración debe completarse sin cortes.
- **MAF + O2 → corrección de mezcla**: Si se interrumpe, el siguiente ciclo de combustión usa datos desactualizados.
- **ECT → ajuste de mezcla**: Crítico en arranque en frío.

El mecanismo equivalente en sistemas operativos es el **lock**: mientras un proceso crítico de media prioridad está en ejecución, el sistema bloquea modificaciones sobre los mismos datos para evitar que otro hilo los "pise".

### Prioridad Baja: confort y conectividad
Son señales que mejoran la experiencia del conductor pero cuya demora no compromete la seguridad ni el funcionamiento del motor.

- **TPMS**: Alerta de presión de neumáticos (no es inmediata, se actualiza cada pocos segundos).
- **CarPlay / Android Auto**: Conectividad con el teléfono del usuario.
- **Climatizador automático**: Ajuste de temperatura de cabina.
- **Luces de tablero no críticas**: Indicadores de servicio o mantenimiento.

---

## Analogía con RBAC y SDN

La jerarquía de señales del vehículo funciona como el **RBAC (Role-Based Access Control)** que describe [Seguridad y Jerarquia](../../../MAIN_VAULT/Seguridad_y_Jerarquia.md): cada señal tiene un "rol" que define qué nivel de acceso tiene al procesador central y con qué urgencia debe ser atendida.

La [ECU](./ECU.md) actúa como el **nodo Norte del SDN**: tiene visibilidad sobre toda la red y puede priorizar, demorar o descartar mensajes según el estado del sistema. Si detecta que la temperatura del motor está en zona crítica (ECT), puede limitar la potencia incluso si el conductor está pisando el acelerador a fondo.

---

## Conflictos y resolución

Cuando dos señales de igual prioridad compiten simultáneamente, el sistema aplica una lógica de **semáforo**: la primera en llegar bloquea el recurso hasta terminar, y la segunda espera en cola. Esto evita la inconsistencia de datos que ocurriría si ambas modificaran los mismos parámetros al mismo tiempo.

Un ejemplo concreto: si el sensor de detonación (knock) y el sensor O2 reportan correcciones contradictorias al mismo ciclo de inyección, la ECU aplica tablas de prioridad predefinidas para resolver cuál corrección se aplica primero.

---

## Relación con otros archivos

- Las señales que compiten provienen de [Sensores_Inputs.md](./Sensores_Inputs.md).
- El medio donde ocurre el arbitraje inicial es el [CAN_Bus.md](./CAN_Bus.md).
- La ECU que ejecuta la lógica de prioridades está en [ECU.md](./ECU.md).

**Vínculo al índice:** [Administración de Sistemas y Redes](../../../MAIN_VAULT/Administración_de_Sistemas_y_Redes.md)
