```mermaid
flowchart TD

A[Inicio] --> B[Usuario accede al sistema]

B --> C[Cliente envia solicitud]
C --> D[Servidor recibe datos]

D --> E{Multiples usuarios?}

E -- No --> F[Procesar solicitud normal]
E -- Si --> G[Gestionar concurrencia]

G --> H[Sincronizacion de procesos]
H --> I[Evitar conflictos de datos]

I --> J[Procesar solicitud]
F --> J

J --> K{Ataque detectado?}

K -- No --> L[Respuesta al cliente]
K -- Si --> M[Fase de ataque]

M --> N[Analisis de vulnerabilidad]

N --> O[Aplicar defensas]

O --> P[Time Stamping]
O --> Q[No Repudio]
O --> R[Validacion de acceso]
O --> S[Proteccion hardware TPM HSM]

P --> T[Restaurar integridad]
Q --> T
R --> T
S --> T

T --> L

L --> U[Mostrar resultado al usuario]

U --> V[Registro de actividad Logs]

V --> W[Fin]
