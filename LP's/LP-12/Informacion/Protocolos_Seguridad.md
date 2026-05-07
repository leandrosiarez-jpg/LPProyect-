# Protocolos de Seguridad en el Vehículo

Un vehículo moderno no es un sistema aislado. Tiene puertos de diagnóstico (OBD-II), conectividad Bluetooth, Wi-Fi, actualizaciones over-the-air y sensores inalámbricos como el TPMS. Cada uno de esos puntos de entrada es un vector de ataque potencial. La seguridad ya no es opcional.

Este archivo aplica los conceptos de [Seguridad y Jerarquia](../../../MAIN_VAULT/Seguridad_y_Jerarquia.md) al entorno automotriz.

---

## Zero Trust aplicado al TPMS

El **TPMS** es el ejemplo más claro de por qué el vehículo necesita una política de **Zero Trust**. Cada rueda emite señales inalámbricas con su presión y temperatura. El problema: un vehículo externo en la misma frecuencia podría, en teoría, enviar señales falsas al sistema.

La solución es exactamente la que describe [Seguridad y Jerarquia](../../../MAIN_VAULT/Seguridad_y_Jerarquia.md): el sistema no confía en ninguna señal por defecto. Cada sensor TPMS tiene un **ID único** programado en la ECU durante la fabricación. El vehículo solo acepta señales de los sensores cuyo ID reconoce y descarta todo lo demás.

- **Política**: No se confía en la señal por su frecuencia ni por su formato, sino por su identidad verificada.
- **Equivalente en redes**: Autenticación basada en atributos específicos, no en dirección IP genérica.

---

## TPM en el vehículo

El **[TPM](../../../MAIN_VAULT/TPM.md)** (Trusted Platform Module) tiene su equivalente en los módulos de control modernos. Cada ECU de gama alta incluye un chip de seguridad soldado a su placa que almacena claves criptográficas únicas.

Su función principal es garantizar que el software que corre en la [ECU](./ECU.md) es el original y no fue modificado. Si alguien intenta flashear firmware no autorizado, el chip detecta que la firma digital no coincide y rechaza la actualización.

- **Aplicación práctica**: Protección contra modificaciones no autorizadas del software del motor (tuning ilegal, manipulación de odómetros).
- **Equivalente en redes**: Autenticación de hardware en el [Endpoint](../../../MAIN_VAULT/Endpoint.md) local.

---

## HSM para comunicaciones externas

Las actualizaciones de software over-the-air (OTA) y la conectividad con servidores del fabricante requieren cifrado. Para eso, los vehículos modernos incorporan un **[HSM](../../../MAIN_VAULT/HSM.md)** (Hardware Security Module) que gestiona las claves de cifrado de forma aislada del resto del sistema.

Si el módulo detecta un intento de extracción física o lógica de las claves, puede invalidarlas automáticamente, exactamente como describe el archivo de [HSM](../../../MAIN_VAULT/HSM.md).

- **Aplicación práctica**: Protección de las claves que autentican las actualizaciones OTA y las comunicaciones con la infraestructura del fabricante.
- **Riesgo que mitiga**: Un atacante que intercepte el tráfico entre el vehículo y el servidor no puede descifrar ni modificar el contenido sin las claves, que nunca salen del HSM.

---

## No repudio y auditoría de fallas

Cuando la ECU registra un código de falla (DTC), ese registro lleva una marca temporal que no puede ser alterada. Esto implementa el concepto de [No Repudio](../../../MAIN_VAULT/No_Repudio.md) con [Time Stamping](../../../MAIN_VAULT/Time_Stamping.md): ante una disputa legal (accidente, garantía, inspección técnica), el fabricante o el técnico pueden demostrar exactamente qué ocurrió, cuándo y con qué valores de sensor.

- **Ejemplo**: Si un vehículo sufre un accidente y el conductor alega que los frenos fallaron, el registro de la ECU puede demostrar si el ABS intervino, qué presión tenían los frenos y a qué velocidad iba el vehículo en los segundos previos.

---

## Puerto OBD-II: el acceso físico más vulnerable

El puerto **OBD-II** (On-Board Diagnostics) es un conector estándar presente en todos los vehículos modernos que permite a herramientas externas leer y escribir datos en la ECU. Es indispensable para el diagnóstico, pero también es el punto de entrada más accesible para un atacante con acceso físico al vehículo.

Las medidas de seguridad aplicadas sobre OBD-II incluyen autenticación de herramientas (solo equipos certificados pueden ejecutar comandos de escritura) y logs de acceso con marca temporal, reforzando el [No Repudio](../../../MAIN_VAULT/No_Repudio.md).

---

## Relación con otros archivos

- Los endpoints que necesitan protección son los [Sensores_Inputs.md](./Sensores_Inputs.md), especialmente el TPMS.
- La [ECU.md](./ECU.md) es el activo más crítico a proteger.
- El medio de transporte que se asegura es el [CAN_Bus.md](./CAN_Bus.md).
