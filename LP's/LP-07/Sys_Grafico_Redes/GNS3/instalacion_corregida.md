# Instalación y Configuración de GNS3

## Requisitos para la Instalación (Límites del Sistema)
Para que el sistema de GNS3 funcione de manera óptima, el hardware del equipo anfitrión (entorno) debe cumplir con ciertos límites mínimos:

* Procesador de 64 bits
* 4 GB de RAM (Se recomiendan 8 GB o más para evitar la saturación del sistema)
* Conexión a internet
* VirtualBox o VMware (Opcional, para integrar subsistemas basados en Máquinas Virtuales)
* 1 GB de espacio en disco
* Habilitar la virtualización (VT-x/AMD-V) en la BIOS (Requisito de hardware crítico)

## Sistemas Operativos Compatibles
* Windows
* Linux
* MacOS

## Pasos de Instalación
1. Verificar que el equipo cumpla con los requisitos mínimos de hardware.
2. Ingresar a la página oficial de GNS3.
3. Descargar la versión correspondiente al sistema operativo.
4. Ejecutar el instalador.
5. Aceptar los permisos (**Control de Acceso a nivel de Sistema Operativo - MAC**: El sistema operativo valida los atributos del instalador antes de permitir cambios).
6. Seleccionar los componentes a instalar.
7. Finalizar la instalación.
8. Abrir GNS3 y completar la configuración inicial.

## Configuración Inicial y Estructura Jerárquica
Al iniciar el software se definen las jerarquías de procesamiento:
* **Seleccionar el servidor local (Local GNS3 Server):** Define el núcleo del sistema que procesará la simulación.
* **Configurar VirtualBox o VMware:** Integra hipervisores externos como subsistemas.
* **Verificar el funcionamiento del servidor local:** Asegura que el canal de comunicación esté activo.
* **Importar las imágenes IOS:** Cargar los sistemas operativos reales (los **Atributos del Objeto** que definirán qué comandos y capacidades de red tendrá el dispositivo).
* **Crear un proyecto de prueba:** Validación empírica del éxito del sistema.

## Verificación de la Instalación
Para comprobar la homeostasis (estabilidad) del sistema recién instalado, se crea un proyecto nuevo, se añade un dispositivo (objeto) y se inicia la simulación. Si el dispositivo corre sin errores, los subsistemas están correctamente interrelacionados y listos para operar.
