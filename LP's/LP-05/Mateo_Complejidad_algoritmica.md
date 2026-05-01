# Complejidad Algorítmica, Hardware de Servicios y Modelo de Backend

# Complejidad Algorítmica

La complejidad algorítmica es la forma de medir cuánto tiempo o memoria necesita un programa para ejecutarse según la cantidad de datos que procesa.

Se representa normalmente con la notación Big O (O).

# Ejemplos
O(1) → tiempo constante (siempre tarda igual)
O(n) → tiempo lineal (a más datos, más tiempo)
O(n²) → tiempo cuadrático (mucho más lento con muchos datos)
O(log n) → tiempo logarítmico (muy eficiente)

Esto sirve para elegir algoritmos más rápidos y eficientes, sobre todo en sistemas grandes.

# Manejo de Hardware de Servicios y sus Limitaciones

El manejo de hardware de servicios se refiere a cómo un servidor utiliza sus recursos físicos para funcionar correctamente.

# Recursos principales
CPU → procesa instrucciones
RAM → guarda datos temporales
Disco → almacena información
Red → permite la comunicación entre equipos
# Limitaciones
Poca RAM puede hacer lento el sistema
CPU saturada genera demoras
Disco lento afecta bases de datos
Mala conexión de red produce cortes o latencia

Por eso es importante optimizar el uso de recursos y evitar sobrecargas en los servidores.

# Modelo de Backend para Gestionar el Acceso al Procesamiento

Un backend es la parte de un sistema que trabaja "por detrás", procesando datos y controlando accesos.

Un modelo de backend que gerencie el acceso al procesamiento puede incluir los siguientes componentes:

# 1. Servidor de solicitudes

Recibe peticiones de usuarios o sistemas.

Ejemplo: Un usuario inicia sesión o consulta datos.

# 2. Controlador

Decide qué hacer con esa solicitud.

Ejemplo: Verifica permisos o redirige al servicio correcto.

# 3. Cola de procesos

Organiza tareas para evitar saturar el servidor.

Ejemplo: Si muchos usuarios solicitan reportes al mismo tiempo, se procesan por turnos.

# 4. Base de datos

Guarda información permanente del sistema.

# 5. Monitor de recursos

Controla el uso de CPU, RAM y el rendimiento general del servidor.

# Conclusión

La complejidad algorítmica ayuda a que los programas sean más eficientes.

El control del hardware evita problemas de rendimiento.

Y un buen backend permite administrar correctamente el procesamiento y acceso a los servicios, mejorando la estabilidad y velocidad del sistema.
