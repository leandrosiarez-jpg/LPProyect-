>[!CAUTION]
> La suplantación de ip es ilegal cuando se usa para engañar o causar daño. Has sido advertido. 

## IP Spoofing (Suplantación de IP)

El IP Spoofing consiste en la creación de paquetes de protocolo de Internet ([IP](IPs.md)) con una dirección de origen falsa con el objetivo de ocultar la identidad del remitente o suplantar a otro sistema informático.

## Tipos de Spoofing

- <h3>Spoofing para Ocultación (Decoy Scan)</h3>

Nmap no solo permite suplantar una IP, sino mezclar tu IP real con muchas falsas para que el administrador de red no sepa quién es el verdadero atacante.

*Comando*: nmap -D RND:10 target (Usa 10 IPs aleatorias como señuelos).

- <h3>Spoofing Total (Identidad Suplantada)</h3>

Se usa para que el objetivo crea que el escaneo proviene de una máquina específica (por ejemplo, un servidor de confianza dentro de su red).

*Comando*: nmap -S <IP_Falsa> -e <Interfaz> -Pn <target>.

>[!NOTE] 
>Para que esto funcione, Nmap requiere el parámetro -Pn (no hacer ping), ya que el ping de respuesta nunca te llegaría.