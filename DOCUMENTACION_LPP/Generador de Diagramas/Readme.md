# Automatizador de diagramas

Convierte un JSON clave-valor en un diagrama — **árbol**, **flujo** o **UML** — renderizado en SVG, directamente en el navegador. Sin backend, sin dependencias, un solo archivo HTML.

🔗 **Probalo acá:** [automatizador-damian-dubanced.vibehost.space](https://automatizador-damian-dubanced.vibehost.space)

## ¿Qué hace?

Pegás (o cargás) un JSON con estructura clave-valor y la herramienta detecta automáticamente qué tipo de diagrama representa mejor esos datos:

| Modo | Cuándo se usa | Ejemplo de uso |
|---|---|---|
| **Árbol** | Jerarquías simples, sin la clave `type` | Categorías, estructuras de carpetas, organigramas |
| **Flujo** | Nodos con `type`: `start`, `end`, `process`, `decision` | Procesos, algoritmos, diagramas de flujo con decisiones |
| **UML** | Nodos con `type: "class"` | Clases, atributos, métodos, herencia |

El modo también se puede forzar manualmente desde la interfaz (Auto / Árbol / Flujo / UML).

## Funcionalidades

- **Detección automática de modo** a partir de la forma del JSON.
- **Validación en vivo**: errores (relaciones a nodos inexistentes) y avisos (nodos sin `type` o con `type` no reconocido) se muestran en paneles separados.
- **Barra de pipeline** que refleja en tiempo real la etapa del procesamiento: Entrada → Parser → Validación → Modelo → Motor.
- **Ejemplos precargados** para los tres modos, y carga de archivos `.json` propios.
- **Descarga del diagrama** generado como `.svg` o `.png` (2x de resolución).
- **Pantalla previa** con instrucciones y un botón para descargar el `SKILL.md` del proyecto, pensado para pasárselo a un asistente de IA y que genere el JSON en el formato correcto.

## Formato de entrada

### Árbol
```json
{
  "Cocina": {
    "Entradas": ["Ensalada", "Sopa"],
    "Postres": { "Frío": "Helado", "Caliente": "Tarta tibia" }
  }
}
```

### Flujo
```json
{
  "Inicio": { "type": "start", "next": "Validar" },
  "Validar": { "type": "decision", "true": "Guardar", "false": "Error" },
  "Guardar": { "type": "process", "next": "Fin" },
  "Error": { "type": "process", "next": "Fin" },
  "Fin": { "type": "end" }
}
```

### UML
```json
{
  "Usuario": {
    "type": "class",
    "attributes": ["nombre", "email"],
    "methods": ["iniciarSesion()"]
  },
  "Administrador": {
    "type": "class",
    "attributes": ["nivelAcceso"],
    "methods": ["gestionarUsuarios()"],
    "extends": "Usuario"
  }
}
```

Reglas completas de formato y casos límite: ver [`SKILL.md`](./SKILL.md).

## Uso local

No requiere instalación ni build. Basta con abrir el archivo en el navegador:

```bash
git clone <este-repo>
cd <este-repo>
open diagram-automator.html   # o doble clic en el archivo
```

## Estructura del repo

```
.
├── diagram-automator.html   # la herramienta completa (HTML + CSS + JS, un solo archivo)
├── SKILL.md                 # guía de formato para asistentes de IA
└── README.md
```

## Tecnología

Vanilla JavaScript (sin frameworks ni build tools), SVG generado por DOM, un solo archivo autocontenido. Desplegado con [VibeHost](https://vibehost.com).
