# Gestion_de_Hilos_y_Procesos

## Definición

- **Hilo (Thread)**  
  Unidad mínima de ejecución que un sistema operativo puede gestionar.

- **Naturaleza**  
  Son procesos secuenciales que pueden percibirse como simultáneos o "semi-paralelos" para el usuario.

## Conflictos de Memoria

- **Inconsistencia de Datos**  
  Error que ocurre cuando dos hilos intentan modificar el mismo espacio de memoria al mismo tiempo.

- **Escritura**  
  Si el hilo A y B incrementan un valor sin sincronización, uno puede "pisar" el trabajo del otro, perdiendo actualizaciones.

## Mecanismos de Sincronización

- **Locks (Bloqueos)**  
  Detienen otros hilos para que uno solo complete su tarea, evitando saturación en procesos críticos.

- **Semáforos**  
  Aseguran que las tareas no sean interrumpidas hasta su finalización para evitar colapsos.


**Vínculo al índice:** [Administracion_de_Sistemas_y_Redes](./Administracion_de_Sistemas_y_Redes.md)