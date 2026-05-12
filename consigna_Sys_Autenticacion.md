# Sistema de Autenticación

## Consigna
Desarrollar un sistema básico de autenticación cliente-servidor orientado a entornos de redes y administración de sistemas

El proyecto deberá permitir el registro e inicio de sesión de usuarios mediante comunicación por sockets TCP

## Objetivos
- Comprender el funcionamiento de la arquitectura cliente-servidor
- Implementar autenticación básica de usuarios
- Aplicar conceptos de redes y seguridad informática
- Gestionar el intercambio de datos entre cliente y servidor

## Requisitos mínimos
- Crear un servidor de autenticación.
- Crear un cliente capaz de conectarse al servidor.
- Permitir:
  - registro de usuarios
  - inicio de sesión
- Validar credenciales.
- Mostrar mensajes de acceso permitido o denegado.
- Guardar usuarios en un archivo local (.json o .txt).

## Tecnologías sugeridas
- Python
- Sockets TCP
- JSON
- Threading (opcional)

## Funcionalidades opcionales
- Logs de accesos
- Roles de usuario (admin/user)
- Hash de contraseñas
- Interfaz gráfica
- Historial de sesiones

## Sugerencia para la estructura

```txt
Cliente -> Servidor -> Validación -> Respuesta

Tiempo limite: 7 Dias para el desarrollo
