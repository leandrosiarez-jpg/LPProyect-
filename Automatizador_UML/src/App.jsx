import React, { useState, useMemo, useRef } from "react";

/* ============================================================================
   ARQUITECTURA
   ENTRADA (texto/archivo) -> PARSER (JSON.parse) -> VALIDACIÓN ->
   MODELO INTERNO (nodos + relaciones) -> MOTOR DE REPRESENTACIÓN
   (árbol | flujo | uml). Cada capa es independiente y genérica: no hay
   ningún nombre de los ejemplos del enunciado hardcodeado en la lógica.
   ============================================================================ */

const KNOWN_FLOW_TYPES = ["start", "end", "process", "decision"];

/* ---------------------------------------------------------------------------
   2/3. INTERPRETACIÓN + MODELO INTERNO
   Nodo      { id, name, type, attributes[], methods[] }
   Relación  { from, to, type }   (type = la clave original: "next","true",
                                    "extends", o "hierarchy" para árboles)
--------------------------------------------------------------------------- */

function detectMode(data) {
  const values = Object.values(data);
  const hasTypedEntry = values.some(
    (v) => v && typeof v === "object" && !Array.isArray(v) && "type" in v
  );
  if (!hasTypedEntry) return "tree";
  const hasClass = values.some(
    (v) => v && typeof v === "object" && v.type === "class"
  );
  return hasClass ? "uml" : "flow";
}

function buildTreeModel(data) {
  const nodes = new Map();
  const relations = [];
  const errors = [];

  const getNode = (name) => {
    if (!nodes.has(name)) {
      nodes.set(name, { id: name, name, type: "tree", attributes: [], methods: [] });
    }
    return nodes.get(name);
  };

  function walk(key, value) {
    getNode(key);
    if (Array.isArray(value)) {
      value.forEach((item, idx) => {
        if (item && typeof item === "object") {
          const leafName = `${key} #${idx + 1}`;
          getNode(leafName);
          relations.push({ from: key, to: leafName, type: "hierarchy" });
          walk(leafName, item);
        } else {
          const leafName = String(item);
          getNode(leafName);
          relations.push({ from: key, to: leafName, type: "hierarchy" });
        }
      });
    } else if (value && typeof value === "object") {
      Object.entries(value).forEach(([childKey, childValue]) => {
        getNode(childKey);
        relations.push({ from: key, to: childKey, type: "hierarchy" });
        walk(childKey, childValue);
      });
    } else if (value !== null && value !== undefined) {
      const leafName = String(value);
      getNode(leafName);
      relations.push({ from: key, to: leafName, type: "hierarchy" });
    }
  }

  try {
    Object.entries(data).forEach(([key, value]) => walk(key, value));
  } catch (e) {
    errors.push("Error al recorrer la estructura: " + e.message);
  }

  return { nodes: [...nodes.values()], relations, errors, warnings: [] };
}

function buildTypedModel(data) {
  const nodes = new Map();
  const relations = [];
  const errors = [];
  const warnings = [];

  const getNode = (name) => {
    if (!nodes.has(name)) {
      nodes.set(name, { id: name, name, type: null, attributes: [], methods: [] });
    }
    return nodes.get(name);
  };

  Object.entries(data).forEach(([key, value]) => {
    const node = getNode(key);
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      warnings.push(`"${key}" no tiene una definición de objeto válida; se generará como nodo genérico.`);
      return;
    }
    const t = value.type;
    node.type = t || null;
    if (!t) {
      warnings.push(`El nodo "${key}" no declara "type"; se representará como nodo genérico.`);
    }

    if (t === "class") {
      node.attributes = Array.isArray(value.attributes) ? value.attributes.map(String) : [];
      node.methods = Array.isArray(value.methods) ? value.methods.map(String) : [];
      Object.entries(value).forEach(([propKey, propVal]) => {
        if (["type", "attributes", "methods"].includes(propKey)) return;
        if (typeof propVal === "string") {
          relations.push({ from: key, to: propVal, type: propKey });
        }
      });
    } else {
      if (t && !KNOWN_FLOW_TYPES.includes(t)) {
        warnings.push(`El tipo "${t}" del nodo "${key}" no es un tipo reconocido; se dibujará como nodo genérico.`);
      }
      Object.entries(value).forEach(([propKey, propVal]) => {
        if (propKey === "type") return;
        if (typeof propVal === "string") {
          relations.push({ from: key, to: propVal, type: propKey });
        } else if (Array.isArray(propVal)) {
          propVal.forEach((v) => {
            if (typeof v === "string") relations.push({ from: key, to: v, type: propKey });
          });
        }
      });
    }
  });

  const validRelations = [];
  relations.forEach((r) => {
    if (!nodes.has(r.to)) {
      errors.push(`La relación "${r.from}" → "${r.to}" (${r.type}) referencia un nodo inexistente.`);
    } else if (!nodes.has(r.from)) {
      errors.push(`La relación desde "${r.from}" referencia un nodo de origen inexistente.`);
    } else {
      validRelations.push(r);
    }
  });

  return { nodes: [...nodes.values()], relations: validRelations, errors, warnings };
}

function processInput(jsonText, modeOverride) {
  if (!jsonText || !jsonText.trim()) {
    return { stage: "entrada", errors: [], warnings: [], nodes: [], relations: [], mode: null };
  }

  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (e) {
    return {
      stage: "parser",
      errors: [`JSON inválido: ${e.message}`],
      warnings: [],
      nodes: [],
      relations: [],
      mode: null,
    };
  }

  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return {
      stage: "validacion",
      errors: ["La raíz del JSON debe ser un objeto clave-valor, no un arreglo ni un valor simple."],
      warnings: [],
      nodes: [],
      relations: [],
      mode: null,
    };
  }

  const detected = detectMode(data);
  const mode = modeOverride === "auto" ? detected : modeOverride;

  try {
    const model = mode === "tree" ? buildTreeModel(data) : buildTypedModel(data);
    return {
      stage: model.errors.length ? "validacion" : "motor",
      mode,
      detected,
      nodes: model.nodes,
      relations: model.relations,
      errors: model.errors,
      warnings: model.warnings,
    };
  } catch (e) {
    return {
      stage: "modelo",
      errors: [`Error interno al construir el modelo: ${e.message}`],
      warnings: [],
      nodes: [],
      relations: [],
      mode,
    };
  }
}

/* ---------------------------------------------------------------------------
   MOTOR DE REPRESENTACIÓN — LAYOUTS
--------------------------------------------------------------------------- */

function layoutTree(nodes, relations) {
  const NODE_W = 150,
    NODE_H = 46,
    H_GAP = 26,
    V_GAP = 84;
  const childrenMap = {};
  const hasParent = new Set();
  relations.forEach((r) => {
    (childrenMap[r.from] = childrenMap[r.from] || []).push(r.to);
    hasParent.add(r.to);
  });
  const roots = nodes.filter((n) => !hasParent.has(n.id)).map((n) => n.id);
  const positions = {};
  let cursorX = 0;
  const visiting = new Set();

  function layoutNode(id, depth) {
    if (visiting.has(id)) {
      // ciclo: se corta para evitar recursión infinita
      positions[id] = { x: cursorX, y: depth * V_GAP };
      cursorX += NODE_W + H_GAP;
      return positions[id].x;
    }
    visiting.add(id);
    const children = (childrenMap[id] || []).filter((c) => !positions[c]);
    if (children.length === 0) {
      positions[id] = { x: cursorX, y: depth * V_GAP };
      cursorX += NODE_W + H_GAP;
    } else {
      const childXs = children.map((c) => layoutNode(c, depth + 1));
      const minX = Math.min(...childXs),
        maxX = Math.max(...childXs);
      positions[id] = { x: (minX + maxX) / 2, y: depth * V_GAP };
    }
    visiting.delete(id);
    return positions[id].x;
  }

  const effectiveRoots = roots.length ? roots : nodes.map((n) => n.id);
  effectiveRoots.forEach((r) => {
    if (!positions[r]) layoutNode(r, 0);
  });
  nodes.forEach((n) => {
    if (!positions[n.id]) {
      positions[n.id] = { x: cursorX, y: 0 };
      cursorX += NODE_W + H_GAP;
    }
  });

  const xs = Object.values(positions).map((p) => p.x);
  const ys = Object.values(positions).map((p) => p.y);
  const minX = Math.min(...xs, 0);
  Object.values(positions).forEach((p) => {
    p.x += -minX + 20;
    p.y += 20;
  });
  const width = Math.max(...xs) - minX + NODE_W + 40;
  const height = Math.max(...ys, 0) + NODE_H + 40;

  return { positions, width, height, nodeW: NODE_W, nodeH: NODE_H };
}

function layoutFlow(nodes, relations) {
  const NODE_W = 160,
    NODE_H = 58,
    H_GAP = 70,
    V_GAP = 90;
  const incoming = {};
  nodes.forEach((n) => (incoming[n.id] = 0));
  relations.forEach((r) => (incoming[r.to] = (incoming[r.to] || 0) + 1));

  let starts = nodes.filter((n) => n.type === "start").map((n) => n.id);
  if (starts.length === 0) starts = nodes.filter((n) => incoming[n.id] === 0).map((n) => n.id);
  if (starts.length === 0 && nodes.length) starts = [nodes[0].id];

  const childrenMap = {};
  relations.forEach((r) => (childrenMap[r.from] = childrenMap[r.from] || []).push(r));
  relations.forEach((r) => {
    childrenMap[r.from] = childrenMap[r.from] || [];
  });

  const level = {};
  const queue = starts.map((s) => ({ id: s, lvl: 0 }));
  let guard = 0;
  while (queue.length && guard < 5000) {
    guard++;
    const { id, lvl } = queue.shift();
    if (level[id] !== undefined && level[id] <= lvl) continue;
    level[id] = lvl;
    (childrenMap[id] || []).forEach((r) => queue.push({ id: r.to, lvl: lvl + 1 }));
  }
  nodes.forEach((n) => {
    if (level[n.id] === undefined) level[n.id] = 0;
  });

  const levels = {};
  nodes.forEach((n) => (levels[level[n.id]] = levels[level[n.id]] || []).push(n.id));

  const positions = {};
  Object.keys(levels)
    .map(Number)
    .sort((a, b) => a - b)
    .forEach((lvl, li) => {
      levels[lvl].forEach((id, i) => {
        positions[id] = { x: i * (NODE_W + H_GAP), y: li * (NODE_H + V_GAP) };
      });
    });

  const xs = Object.values(positions).map((p) => p.x);
  const ys = Object.values(positions).map((p) => p.y);
  Object.values(positions).forEach((p) => {
    p.x += 20;
    p.y += 20;
  });
  const width = Math.max(...xs, 0) + NODE_W + 40;
  const height = Math.max(...ys, 0) + NODE_H + 40;

  return { positions, width, height, nodeW: NODE_W, nodeH: NODE_H };
}

function layoutUML(nodes) {
  const NODE_W = 230,
    GAP_X = 70,
    GAP_Y = 60;
  const cols = Math.max(1, Math.ceil(Math.sqrt(nodes.length || 1)));
  const rows = Math.ceil(nodes.length / cols) || 1;
  const heightOf = (n) => 40 + Math.max(n.attributes.length, 1) * 20 + Math.max(n.methods.length, 1) * 20 + 26;

  const rowHeights = new Array(rows).fill(0);
  nodes.forEach((n, i) => {
    const row = Math.floor(i / cols);
    rowHeights[row] = Math.max(rowHeights[row], heightOf(n));
  });
  const rowY = [0];
  for (let i = 1; i < rows; i++) rowY[i] = rowY[i - 1] + rowHeights[i - 1] + GAP_Y;

  const positions = {};
  nodes.forEach((n, i) => {
    const row = Math.floor(i / cols),
      col = i % cols;
    positions[n.id] = { x: col * (NODE_W + GAP_X) + 20, y: rowY[row] + 20, h: heightOf(n) };
  });

  const width = cols * (NODE_W + GAP_X) + 40;
  const height = (rowY[rows - 1] || 0) + rowHeights[rows - 1] + 60;
  return { positions, width, height, nodeW: NODE_W };
}

/* ---------------------------------------------------------------------------
   COMPONENTES DE DIBUJO (SVG)
--------------------------------------------------------------------------- */

const MODE_COLOR = { tree: "#6fcf97", flow: "#7aa7ff", uml: "#e3a45f" };

function ArrowDefs({ color, id }) {
  return (
    <marker id={id} viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill={color} />
    </marker>
  );
}

function TreeCanvas({ nodes, relations }) {
  const layout = useMemo(() => layoutTree(nodes, relations), [nodes, relations]);
  const { positions, width, height, nodeW, nodeH } = layout;
  const color = MODE_COLOR.tree;

  return (
    <svg width={Math.max(width, 300)} height={Math.max(height, 200)} style={{ display: "block" }}>
      <defs>
        <ArrowDefs color="#4a5568" id="arrow-tree" />
      </defs>
      {relations.map((r, i) => {
        const p = positions[r.from],
          c = positions[r.to];
        if (!p || !c) return null;
        const x1 = p.x + nodeW / 2,
          y1 = p.y + nodeH;
        const x2 = c.x + nodeW / 2,
          y2 = c.y;
        const midY = (y1 + y2) / 2;
        return (
          <path
            key={i}
            d={`M ${x1} ${y1} C ${x1} ${midY}, ${x2} ${midY}, ${x2} ${y2}`}
            fill="none"
            stroke="#3d4454"
            strokeWidth="1.6"
          />
        );
      })}
      {nodes.map((n) => {
        const p = positions[n.id];
        if (!p) return null;
        return (
          <g key={n.id} transform={`translate(${p.x},${p.y})`}>
            <rect
              width={nodeW}
              height={nodeH}
              rx="8"
              fill="#1b2029"
              stroke={color}
              strokeWidth="1.4"
            />
            <text
              x={nodeW / 2}
              y={nodeH / 2}
              textAnchor="middle"
              dominantBaseline="central"
              fontFamily="'IBM Plex Sans', sans-serif"
              fontSize="13"
              fill="#e7eaf1"
            >
              {truncate(n.name, 18)}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

function FlowCanvas({ nodes, relations, warnings }) {
  const layout = useMemo(() => layoutFlow(nodes, relations), [nodes, relations]);
  const { positions, width, height, nodeW, nodeH } = layout;
  const color = MODE_COLOR.flow;
  const nodeById = useMemo(() => Object.fromEntries(nodes.map((n) => [n.id, n])), [nodes]);

  return (
    <svg width={Math.max(width, 300)} height={Math.max(height, 200)} style={{ display: "block" }}>
      <defs>
        <ArrowDefs color={color} id="arrow-flow" />
      </defs>
      {relations.map((r, i) => {
        const p = positions[r.from],
          c = positions[r.to];
        if (!p || !c) return null;
        const x1 = p.x + nodeW / 2,
          y1 = p.y + nodeH;
        const x2 = c.x + nodeW / 2,
          y2 = c.y;
        const midY = (y1 + y2) / 2;
        const isBranch = r.type === "false";
        return (
          <g key={i}>
            <path
              d={`M ${x1} ${y1} C ${x1} ${midY}, ${x2} ${midY}, ${x2} ${y2}`}
              fill="none"
              stroke={isBranch ? "#e3826f" : color}
              strokeWidth="1.6"
              markerEnd="url(#arrow-flow)"
            />
            {r.type !== "hierarchy" && (
              <text
                x={(x1 + x2) / 2}
                y={midY - 4}
                textAnchor="middle"
                fontFamily="'JetBrains Mono', monospace"
                fontSize="10.5"
                fill="#9aa5b8"
              >
                {r.type}
              </text>
            )}
          </g>
        );
      })}
      {nodes.map((n) => {
        const p = positions[n.id];
        if (!p) return null;
        return (
          <g key={n.id} transform={`translate(${p.x},${p.y})`}>
            <FlowShape node={n} w={nodeW} h={nodeH} color={color} />
          </g>
        );
      })}
    </svg>
  );
}

function FlowShape({ node, w, h, color }) {
  const label = truncate(node.name, 16);
  const textEl = (
    <text
      x={w / 2}
      y={h / 2}
      textAnchor="middle"
      dominantBaseline="central"
      fontFamily="'IBM Plex Sans', sans-serif"
      fontSize="12.5"
      fill="#e7eaf1"
    >
      {label}
    </text>
  );

  if (node.type === "start" || node.type === "end") {
    return (
      <>
        <rect width={w} height={h} rx={h / 2} fill="#1b2029" stroke={color} strokeWidth="1.6" />
        {textEl}
      </>
    );
  }
  if (node.type === "decision") {
    const cx = w / 2,
      cy = h / 2;
    const points = `${cx},0 ${w},${cy} ${cx},${h} 0,${cy}`;
    return (
      <>
        <polygon points={points} fill="#1b2029" stroke={color} strokeWidth="1.6" />
        {textEl}
      </>
    );
  }
  if (node.type === "process") {
    return (
      <>
        <rect width={w} height={h} rx="4" fill="#1b2029" stroke={color} strokeWidth="1.6" />
        {textEl}
      </>
    );
  }
  // tipo desconocido / genérico
  return (
    <>
      <rect width={w} height={h} rx="4" fill="#1b2029" stroke="#5a6272" strokeDasharray="5,4" strokeWidth="1.4" />
      {textEl}
      {node.type && (
        <text x={w / 2} y={h - 8} textAnchor="middle" fontFamily="'JetBrains Mono', monospace" fontSize="9" fill="#6b7382">
          type: {node.type}
        </text>
      )}
    </>
  );
}

function UMLCanvas({ nodes, relations }) {
  const layout = useMemo(() => layoutUML(nodes), [nodes]);
  const { positions, width, height, nodeW } = layout;
  const color = MODE_COLOR.uml;

  const centerOf = (id) => {
    const p = positions[id];
    if (!p) return null;
    return { x: p.x + nodeW / 2, y: p.y + p.h / 2, box: p };
  };

  return (
    <svg width={Math.max(width, 300)} height={Math.max(height, 200)} style={{ display: "block" }}>
      <defs>
        <ArrowDefs color={color} id="arrow-uml" />
      </defs>
      {relations.map((r, i) => {
        const a = centerOf(r.from),
          b = centerOf(r.to);
        if (!a || !b) return null;
        return (
          <g key={i}>
            <line
              x1={a.x}
              y1={a.y}
              x2={b.x}
              y2={b.y}
              stroke={color}
              strokeWidth="1.4"
              strokeDasharray={r.type === "extends" || r.type === "implements" ? "6,4" : undefined}
              markerEnd="url(#arrow-uml)"
            />
            <text
              x={(a.x + b.x) / 2}
              y={(a.y + b.y) / 2 - 4}
              textAnchor="middle"
              fontFamily="'JetBrains Mono', monospace"
              fontSize="10"
              fill="#9aa5b8"
            >
              {r.type}
            </text>
          </g>
        );
      })}
      {nodes.map((n) => {
        const p = positions[n.id];
        if (!p) return null;
        const attrs = n.attributes.length ? n.attributes : ["—"];
        const methods = n.methods.length ? n.methods : ["—"];
        const headerH = 32;
        const attrH = attrs.length * 20 + 10;
        return (
          <g key={n.id} transform={`translate(${p.x},${p.y})`}>
            <rect width={nodeW} height={p.h} fill="#1b2029" stroke={color} strokeWidth="1.4" />
            <text
              x={nodeW / 2}
              y={headerH / 2}
              textAnchor="middle"
              dominantBaseline="central"
              fontFamily="'JetBrains Mono', monospace"
              fontWeight="600"
              fontSize="13"
              fill="#e7eaf1"
            >
              {truncate(n.name, 20)}
            </text>
            <line x1="0" y1={headerH} x2={nodeW} y2={headerH} stroke={color} strokeWidth="1" />
            {attrs.map((a, i) => (
              <text
                key={i}
                x="12"
                y={headerH + 18 + i * 20}
                fontFamily="'JetBrains Mono', monospace"
                fontSize="11.5"
                fill="#c3c9d6"
              >
                {truncate(a, 26)}
              </text>
            ))}
            <line x1="0" y1={headerH + attrH} x2={nodeW} y2={headerH + attrH} stroke={color} strokeWidth="1" />
            {methods.map((m, i) => (
              <text
                key={i}
                x="12"
                y={headerH + attrH + 18 + i * 20}
                fontFamily="'JetBrains Mono', monospace"
                fontSize="11.5"
                fill="#c3c9d6"
              >
                {truncate(m, 26)}
              </text>
            ))}
          </g>
        );
      })}
    </svg>
  );
}

function truncate(str, n) {
  return str.length > n ? str.slice(0, n - 1) + "…" : str;
}

/* ---------------------------------------------------------------------------
   EJEMPLOS (solo para demostrar el uso — no forman parte de la lógica)
--------------------------------------------------------------------------- */

const EXAMPLES = {
  arbol: {
    label: "Árbol · Programación",
    json: {
      Programación: { Frontend: "HTML", Backend: "Python" },
    },
  },
  arbol2: {
    label: "Árbol · otro dominio",
    json: {
      Cocina: {
        Entradas: ["Ensalada", "Sopa"],
        Postres: { Frío: "Helado", Caliente: "Tarta tibia" },
      },
    },
  },
  flujo: {
    label: "Flujo · Validación",
    json: {
      Inicio: { type: "start", next: "Validar" },
      Validar: { type: "decision", true: "Guardar", false: "Error" },
      Guardar: { type: "process", next: "Fin" },
      Error: { type: "process", next: "Fin" },
      Fin: { type: "end" },
    },
  },
  uml: {
    label: "UML · Usuario",
    json: {
      Usuario: {
        type: "class",
        attributes: ["nombre", "email"],
        methods: ["iniciarSesion()"],
      },
      Administrador: {
        type: "class",
        attributes: ["nivelAcceso"],
        methods: ["gestionarUsuarios()"],
        extends: "Usuario",
      },
    },
  },
};

/* ---------------------------------------------------------------------------
   BARRA DE PIPELINE (refleja la arquitectura real en tiempo real)
--------------------------------------------------------------------------- */

const STAGES = [
  { key: "entrada", label: "ENTRADA" },
  { key: "parser", label: "PARSER" },
  { key: "validacion", label: "VALIDACIÓN" },
  { key: "modelo", label: "MODELO" },
  { key: "motor", label: "MOTOR" },
];

function stageIndex(result) {
  if (!result.mode && result.stage === "entrada") return -1;
  if (result.stage === "parser") return 0;
  if (result.stage === "validacion") return result.errors.length ? 1 : 2;
  if (result.stage === "modelo") return 2;
  if (result.stage === "motor") return 4;
  return -1;
}

function PipelineBar({ result }) {
  const active = stageIndex(result);
  const color = result.mode ? MODE_COLOR[result.mode] : "#5a6272";
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
      {STAGES.map((s, i) => (
        <React.Fragment key={s.key}>
          <div
            style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: 10.5,
              letterSpacing: "0.06em",
              padding: "5px 9px",
              borderRadius: 5,
              border: `1px solid ${i <= active ? color : "#2a2f3a"}`,
              color: i <= active ? color : "#5a6272",
              background: i <= active ? color + "14" : "transparent",
              transition: "all 200ms ease",
            }}
          >
            {s.label}
          </div>
          {i < STAGES.length - 1 && (
            <div style={{ color: i < active ? color : "#2a2f3a", fontSize: 12, transition: "color 200ms" }}>→</div>
          )}
        </React.Fragment>
      ))}
      {result.mode && (
        <>
          <div style={{ color: active >= 4 ? color : "#2a2f3a", fontSize: 12 }}>→</div>
          <div
            style={{
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: 10.5,
              letterSpacing: "0.06em",
              padding: "5px 9px",
              borderRadius: 5,
              border: `1px solid ${color}`,
              color: "#10131a",
              background: color,
              fontWeight: 600,
            }}
          >
            {result.mode.toUpperCase()}
          </div>
        </>
      )}
    </div>
  );
}

/* ---------------------------------------------------------------------------
   APP PRINCIPAL
--------------------------------------------------------------------------- */

export default function DiagramAutomator() {
  const [jsonText, setJsonText] = useState(JSON.stringify(EXAMPLES.arbol.json, null, 2));
  const [modeOverride, setModeOverride] = useState("auto");
  const fileInputRef = useRef(null);

  const result = useMemo(() => processInput(jsonText, modeOverride), [jsonText, modeOverride]);

  const handleFile = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => setJsonText(String(ev.target.result));
    reader.readAsText(file);
    e.target.value = "";
  };

  const loadExample = (key) => {
    setJsonText(JSON.stringify(EXAMPLES[key].json, null, 2));
    setModeOverride("auto");
  };

  const canRender = result.mode && result.nodes.length > 0 && result.errors.length === 0;

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "#10131a",
        color: "#e7eaf1",
        fontFamily: "'IBM Plex Sans', sans-serif",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;500;600&display=swap');
        * { box-sizing: border-box; }
        textarea::placeholder { color: #4a5568; }
        button { cursor: pointer; font-family: 'IBM Plex Sans', sans-serif; }
        ::-webkit-scrollbar { width: 10px; height: 10px; }
        ::-webkit-scrollbar-thumb { background: #2a2f3a; border-radius: 6px; }
      `}</style>

      <header
        style={{
          padding: "18px 26px",
          borderBottom: "1px solid #21262f",
          display: "flex",
          flexDirection: "column",
          gap: 12,
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", flexWrap: "wrap", gap: 10 }}>
          <div>
            <div style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 11, color: "#6b7382", letterSpacing: "0.08em" }}>
              KEY-VALUE → DIAGRAMA
            </div>
            <h1 style={{ margin: "2px 0 0", fontSize: 20, fontWeight: 600 }}>Automatizador de diagramas</h1>
          </div>
        </div>
        <PipelineBar result={result} />
      </header>

      <div style={{ flex: 1, display: "flex", minHeight: 0 }}>
        {/* PANEL IZQUIERDO: ENTRADA */}
        <div
          style={{
            width: 380,
            minWidth: 380,
            borderRight: "1px solid #21262f",
            display: "flex",
            flexDirection: "column",
            padding: 18,
            gap: 14,
            overflowY: "auto",
          }}
        >
          <div>
            <div style={{ fontSize: 11.5, color: "#8a93a6", marginBottom: 8, fontWeight: 500 }}>EJEMPLOS</div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
              {Object.entries(EXAMPLES).map(([key, ex]) => (
                <button
                  key={key}
                  onClick={() => loadExample(key)}
                  style={{
                    fontSize: 11.5,
                    padding: "6px 10px",
                    borderRadius: 6,
                    border: "1px solid #2a2f3a",
                    background: "#171b24",
                    color: "#c3c9d6",
                  }}
                >
                  {ex.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
              <div style={{ fontSize: 11.5, color: "#8a93a6", fontWeight: 500 }}>ENTRADA (JSON key-value)</div>
              <div style={{ display: "flex", gap: 6 }}>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  style={{ fontSize: 11, padding: "4px 8px", borderRadius: 5, border: "1px solid #2a2f3a", background: "transparent", color: "#8a93a6" }}
                >
                  Cargar archivo
                </button>
                <button
                  onClick={() => setJsonText("")}
                  style={{ fontSize: 11, padding: "4px 8px", borderRadius: 5, border: "1px solid #2a2f3a", background: "transparent", color: "#8a93a6" }}
                >
                  Limpiar
                </button>
              </div>
              <input ref={fileInputRef} type="file" accept=".json,application/json" onChange={handleFile} style={{ display: "none" }} />
            </div>
            <textarea
              value={jsonText}
              onChange={(e) => setJsonText(e.target.value)}
              placeholder='{ "Nodo": { "type": "process", "next": "OtroNodo" } }'
              spellCheck={false}
              style={{
                width: "100%",
                height: 340,
                background: "#0d1015",
                border: "1px solid #21262f",
                borderRadius: 8,
                color: "#e7eaf1",
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: 12.5,
                padding: 12,
                resize: "vertical",
                lineHeight: 1.5,
              }}
            />
          </div>

          <div>
            <div style={{ fontSize: 11.5, color: "#8a93a6", marginBottom: 8, fontWeight: 500 }}>TIPO DE REPRESENTACIÓN</div>
            <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
              {["auto", "tree", "flow", "uml"].map((m) => (
                <button
                  key={m}
                  onClick={() => setModeOverride(m)}
                  style={{
                    fontSize: 11.5,
                    padding: "6px 10px",
                    borderRadius: 6,
                    border: `1px solid ${modeOverride === m ? "#7aa7ff" : "#2a2f3a"}`,
                    background: modeOverride === m ? "#7aa7ff1a" : "#171b24",
                    color: modeOverride === m ? "#7aa7ff" : "#c3c9d6",
                    fontWeight: modeOverride === m ? 600 : 400,
                  }}
                >
                  {m === "auto" ? "Auto" : m === "tree" ? "Árbol" : m === "flow" ? "Flujo" : "UML"}
                </button>
              ))}
            </div>
          </div>

          {(result.errors.length > 0 || result.warnings.length > 0) && (
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {result.errors.length > 0 && (
                <div style={{ border: "1px solid #7a3535", background: "#2a1616", borderRadius: 8, padding: 10 }}>
                  <div style={{ fontSize: 11, color: "#ff8a8a", fontWeight: 600, marginBottom: 4 }}>ERRORES</div>
                  {result.errors.map((e, i) => (
                    <div key={i} style={{ fontSize: 11.5, color: "#ffb3b3", lineHeight: 1.5 }}>
                      • {e}
                    </div>
                  ))}
                </div>
              )}
              {result.warnings.length > 0 && (
                <div style={{ border: "1px solid #6b5a20", background: "#211d10", borderRadius: 8, padding: 10 }}>
                  <div style={{ fontSize: 11, color: "#f2c94c", fontWeight: 600, marginBottom: 4 }}>AVISOS</div>
                  {result.warnings.map((w, i) => (
                    <div key={i} style={{ fontSize: 11.5, color: "#e0cf94", lineHeight: 1.5 }}>
                      • {w}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* PANEL DERECHO: DIAGRAMA */}
        <div style={{ flex: 1, overflow: "auto", padding: 24, display: "flex", alignItems: "flex-start" }}>
          {canRender ? (
            <div style={{ border: "1px solid #21262f", borderRadius: 10, background: "#12151c", padding: 16 }}>
              {result.mode === "tree" && <TreeCanvas nodes={result.nodes} relations={result.relations} />}
              {result.mode === "flow" && <FlowCanvas nodes={result.nodes} relations={result.relations} />}
              {result.mode === "uml" && <UMLCanvas nodes={result.nodes} relations={result.relations} />}
            </div>
          ) : (
            <div style={{ margin: "auto", textAlign: "center", color: "#4a5568", maxWidth: 360 }}>
              <div style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 12 }}>
                {jsonText.trim() === ""
                  ? "Esperando entrada…"
                  : result.errors.length
                  ? "Corregí los errores para generar el diagrama."
                  : "Sin nodos que representar."}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
