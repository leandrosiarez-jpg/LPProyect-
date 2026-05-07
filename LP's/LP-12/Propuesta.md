# Proyecto: ¿Cómo se comunica un auto con el usuario?

## Descripción
Este proyecto es un puente entre la programación de redes y la ingeniería automotriz. El auto deja de ser algo puramente mecánico para convertirse en un sistema administrado, donde cada sensor es una entrada de información que requiere una respuesta precisa.

## Entradas y Salidas de Información

El manejo automático de estos flujos es lo que garantiza la seguridad y el rendimiento:

* **Inputs (Entradas)**: 
    * Intención del usuario mediante el pedal (**APS**), aportando la carga subjetiva inicial.
    * Datos de sincronización y reloj del motor (**CKP/CMP**) para evitar inconsistencias de datos.
    * Flujo de aire y calidad de combustión (**MAF** y **O2**) como métricas de rendimiento de red.
    * Estado de los neumáticos (**TPMS**) vía señal inalámbrica.
* **Outputs (Salidas)**: 
    * Ajuste de presión de combustible (**FRP**).
    * Acciones de seguridad activa sobre los frenos (ABS/TCS).
    * Gestión de servicios externos y conectividad (CarPlay).


## Seguridad y Gestión de Red
Para que este sistema sea confiable, aplico los pilares de nuestra materia:

1.  **Jerarquía de Control (SDN)**: La computadora central actúa como el **Software "Norte"**. Posee el **acceso padre** para priorizar datos críticos (como una señal de frenado del ABS) sobre datos secundarios (como la música), evitando la saturación de la red interna.
2.  **Seguridad por Hardware**: 
    * **[TPM](../../MAIN_VAULT/TPM.md)**: Autentica que el hardware de los sensores y la computadora sea el original.
    * **[HSM](../../MAIN_VAULT/HSM.md)**: Protege las claves de cifrado para que la conexión externa no sea un punto de vulnerabilidad.
3.  **Política de Confianza**: Se aplica **Zero Trust** en la comunicación de sensores inalámbricos como el TPMS; el sistema no confía en la señal hasta que valida el ID del sensor.
4.  **Auditoría e Integridad**: Se utiliza el **[No Repudio](../../MAIN_VAULT/No_Repudio.md)** mediante **[Time Stamping](../../MAIN_VAULT/Time_Stamping.md)**. Ante una falla, el sistema guarda un registro con sello de tiempo que permite saber exactamente qué dato falló y en qué momento, sin que la información pueda ser alterada.
