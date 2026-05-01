# Redes_y_Conectividad

## Comparativa de Arquitecturas

| Característica | Peer-to-Peer (P2P) | Centralizada |
| :--- | :--- | :--- |
| **Estructura** | Dispositivos conectados entre sí sin servidor central. | Estructura jerárquica con administrador central. |
| **Ventajas** | Más seguro contra denegación de servicio (DoS). | Mayor seguridad contra ataques externos directos. |

## Arquitectura de Software

- **SDN (Software Defined Networking)**  
  Arquitectura que utiliza controladores de software para dirigir el tráfico de la red.  
  - **Jerarquía**: Se define como el **Software "Norte"** de la infraestructura.  
  - **Alcance**: Posee **acceso padre** a todas las terminales de la red para centralizar el control y la visibilidad.

## Componentes Técnicos

- **API**  
  Lógica creada para que una aplicación o computadora se comunique con otra.

- **Servidor**  
  Lugar donde se almacena información; la solicita a través de los **[Endpoint](./Endpoint.md)**.

- **Switch**  
  Dispositivo por donde pasa la información para facilitar la conexión.

- **Conexión**  
  La información viaja a través de los **[Socket](./Socket.md)** hasta llegar al servidor.

**Vínculo al índice:** [Administracion_de_Sistemas_y_Redes](./Administracion_de_Sistemas_y_Redes.md)