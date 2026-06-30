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



---

*Stack: Next.js · Node.js · Mermaid.js · Anthropic API · GitHub REST API*
