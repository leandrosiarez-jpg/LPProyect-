# 29/06

# Teoría completa — Generador UML Automático con IA y GitHub

---

## 1. UML — El lenguaje que vas a generar

UML (*Unified Modeling Language*) es un estándar ISO para modelar sistemas de software visualmente. Tiene 14 tipos de diagramas divididos en dos familias:

**Diagramas estructurales** — muestran *qué existe* en el sistema: clases, objetos, componentes, paquetes. El más común es el **class diagram**, que modela entidades con atributos, métodos y relaciones.

| Relación | Sintaxis Mermaid | Significado |
|---|---|---|
| Herencia | `Animal <\|-- Dog` | Dog extiende Animal |
| Implementación | `Vehicle <\|.. Car` | Car implementa Vehicle |
| Composición | `House *-- Room` | Room no existe sin House |
| Agregación | `Team o-- Player` | Player puede existir sin Team |
| Dependencia | `Order ..> Product` | Order usa Product |

**Diagramas de comportamiento** — muestran *qué hace* el sistema en el tiempo:

- **Sequence diagram** — mensajes entre actores a lo largo del tiempo, con líneas de vida verticales.
- **Activity diagram** — flujo de control con bifurcaciones, loops y decisiones (un flowchart formal).
- **State diagram** — cómo un objeto cambia de estado en respuesta a eventos (máquina de estados finita).
- **Use case diagram** — relaciones entre actores externos y funcionalidades del sistema.

> **Concepto clave:** UML no es solo sintaxis gráfica — es **semántica formal**. Una flecha con punta hueca significa herencia. Una flecha con rombo lleno significa composición. Si la IA genera mal el tipo de flecha, el diagrama miente sobre la arquitectura.

---

# 01/07
## Stack final del proyecto

| Parte | Tecnología | Por qué |
|---|---|---|
| Frontend | Next.js + TailwindCSS | Un solo proyecto, API routes incluidas |
| Base de datos | Supabase (PostgreSQL) | Gratis, tiene SDK para JS, panel visual, no necesita servidor propio |
| Diagramas | Mermaid.js | Renderiza en el browser, nativo en GitHub |
| IA | Anthropic API | Genera la sintaxis Mermaid |
| GitHub | REST API | Lee branches del equipo, hace commits automáticos |
| Historial | Supabase (tabla `diagrams`) | Persistente, accesible por todo el equipo |

# 06/07
# UML Generator — Progreso del proyecto
**Fecha:** 6 de julio de 2026

---

## Estado actual

```
✅ package.json
✅ .env.local
✅ .env.example
✅ .gitignore

✅ lib\language-detector.js
✅ lib\mermaid-validator.js
✅ lib\prompt-builder.js
✅ lib\supabase-client.js
✅ lib\github-client.js

✅ app\api\generate\route.js

⬜ app\api\github\push\route.js
⬜ app\api\github\browse\route.js
⬜ app\api\history\route.js
⬜ app\page.js
⬜ app\layout.js
```

---

## Configuración del entorno

### Herramientas instaladas
- Node.js v24.18.0
- Git v2.55.0 (Windows)
- Visual Studio Code

### Ubicación del proyecto
```
D:\uml-generator
```

### Librerías instaladas
```
next, react, react-dom, mermaid, @supabase/supabase-js,
@anthropic-ai/sdk, tailwindcss, postcss, autoprefixer, zustand
```

---

## Archivos creados

### `package.json`
Configuración del proyecto con los scripts `dev`, `build` y `start` para Next.js.

### `.env.local`
Variables de entorno reales (no se sube a GitHub):
- `ANTHROPIC_API_KEY`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `GITHUB_TOKEN`

### `.env.example`
Plantilla de variables de entorno para compartir con el equipo sin exponer las keys reales.

### `.gitignore`
Archivos ignorados por Git:
- `.env.local`
- `node_modules`
- `.next`

---

## Base de datos — Supabase

### Proyecto
- **Nombre:** uml-generator
- **URL:** https://hvcepekrtqvldgvxbycp.supabase.co
- **Region:** South America (São Paulo)

### Tabla `diagrams`
```sql
create table diagrams (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc', now()),
  user_github text not null,
  repo text,
  branch text,
  language text,
  diagram_type text,
  input_code text,
  mermaid_code text not null,
  github_url text
);
```

---

## Archivos de `/lib`

### `language-detector.js`
Detecta el lenguaje de programación de un archivo en 3 capas:
1. Por extensión (`.js`, `.py`, `.java`, `.cpp`, etc.)
2. Por patrones en el contenido (palabras reservadas, tokens)
3. Sugiere el tipo de diagrama más apropiado

### `mermaid-validator.js`
Valida el texto generado por la IA en 3 capas:
1. Extrae el bloque mermaid con regex
2. Verifica que la sintaxis sea válida
3. Verifica que el tipo de diagrama coincida con lo pedido

Si falla devuelve el error exacto para el sistema de retry.

### `prompt-builder.js`
Construye el system prompt para la IA. Tiene dos funciones:
- `buildInitialPrompt` — para el primer intento
- `buildRetryPrompt` — incluye el error del intento anterior como contexto

### `supabase-client.js`
Maneja la base de datos. Tres funciones:
- `saveDiagram` — guarda un diagrama nuevo
- `getHistory` — trae el historial del equipo
- `getDiagramById` — trae un diagrama específico

### `github-client.js`
Maneja la comunicación con GitHub API. Tres funciones:
- `listFiles` — lista archivos de código de una branch
- `getFileContent` — lee el contenido de un archivo
- `commitDiagram` — hace el commit automático del diagrama generado

---

## Archivos de `/app/api`

### `api\generate\route.js`
Endpoint principal `POST /api/generate`. Flujo:
1. Recibe código + tipo de diagrama
2. Detecta el lenguaje
3. Llama a la IA (Anthropic claude-sonnet-4-6)
4. Valida el resultado
5. Si falla hace retry con el error como contexto (máx. 3 intentos)
6. Guarda en Supabase
7. Devuelve el diagrama generado

---

## Pendiente

| Archivo | Descripción |
|---|---|
| `app\api\github\push\route.js` | Commit automático a GitHub |
| `app\api\github\browse\route.js` | Leer branches de otros miembros del equipo |
| `app\api\history\route.js` | Traer historial desde Supabase |
| `app\page.js` | Frontend principal |
| `app\layout.js` | Layout de Next.js |

---

## Stack del proyecto

| Parte | Tecnología |
|---|---|
| Frontend | Next.js + TailwindCSS |
| Base de datos | Supabase (PostgreSQL) |
| Diagramas | Mermaid.js |
| IA | Anthropic API (claude-sonnet-4-6) |
| GitHub | REST API |
| Estado global | Zustand |

---

*Continuación del proyecto pendiente — próxima sesión arranca con `app\api\github\push\route.js`*
