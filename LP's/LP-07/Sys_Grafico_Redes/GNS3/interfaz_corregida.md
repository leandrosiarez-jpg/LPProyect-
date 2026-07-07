# Interfaz de GNS3: Componentes y Jerarquía del Sistema

## ¿Qué es la interfaz de GNS3?
La interfaz de GNS3 es el entorno gráfico (GUI) que funciona como el panel de control del sistema. Su objetivo es permitir al usuario interactuar, configurar y administrar las simulaciones de manera centralizada.

## Componentes Principales y su Rol en el Sistema

### Barra de menús
Ubicada en la parte superior. Representa el nivel más alto de la **jerarquía** de control del software. Permite gestionar las directrices globales del sistema (proyectos, preferencias del servidor, administración de dispositivos).

### Barra de herramientas
Contiene los accesos rápidos para las acciones operacionales esenciales: iniciar, pausar o detener los flujos del sistema (dispositivos y simulaciones).

### Panel de dispositivos (Catálogo de Objetos)
Ubicado a la izquierda. Contiene los componentes de red (routers, switches, firewalls) disponibles para ser integrados. En el contexto de control de accesos, aquí se configuran los **Objetos** que posteriormente restringirán o permitirán acciones de los **Sujetos**.

### Área de trabajo (Entorno del Sistema)
El espacio principal donde se diseña la topología de red mediante Drag & Drop. Aquí se definen los límites del sistema y las relaciones (enlaces de red) entre los diferentes subsistemas.

### Consola
El canal directo para interactuar con la línea de comandos (CLI) de los dispositivos. Es la herramienta principal para que el administrador (un **Sujeto** con un **Rol** específico - RBAC) ejecute **Acciones** (leer, escribir, modificar) sobre el sistema.

### Barra de estado
Ubicada en la parte inferior. Muestra la retroalimentación del sistema en tiempo real: uso de recursos, estado del servidor local y telemetría de la simulación.

---

## Interfaz y el Control de Acceso (RBAC / ABAC)
La interfaz de GNS3 refleja cómo interactúan los componentes según las directrices de seguridad de las redes reales que emula:
* **Jerarquía de Control:** No todos los usuarios de la red tienen el mismo acceso. A través de las consolas de la interfaz, se puede configurar si un dispositivo validará el acceso según el rol del usuario (**RBAC** como Administrador, Operador o Alumno) o según múltiples variables como la IP de origen y la hora del día (**ABAC**).
