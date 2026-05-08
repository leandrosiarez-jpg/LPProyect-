# Seguridad_y_Jerarquia

## Control de Acceso

- **RBAC (Role-Based Access Control)**  
  Restringe el acceso a sistemas según el rol funcional del usuario.

- **Zero Trust**  
  Política de seguridad donde no se confía en nadie por defecto.  
  - **Configuración**: Se basa en **ID** y atributos específicos, no en direcciones IP o roles genéricos.  
  - **Implementación**: Se gestiona a través de un **Nodo Norte** que controla el flujo de información.

## Administración de Red

- **Jerarquía**  
  Estructura que divide la red en capas para limitar permisos.

- **Validación de Hardware**  
  Uso de **[TPM](./TPM.md)** en dispositivos finales y **[HSM](./HSM.md)** para la gestión de claves críticas.

- **BIOS**  
  El administrador puede restringir el acceso mediante bloqueos desde la BIOS.

**Vínculo al índice:** [Administracion_de_Sistemas_y_Redes](./Administracion_de_Sistemas_y_Redes.md)