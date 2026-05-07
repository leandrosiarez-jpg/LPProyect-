# memoria.py - Sistema de memoria persistente para C.L.A.V.E.
# Usa SQLite (incluido en Python, sin instalar nada)
#
# CONCEPTO: una base de datos local con 3 tablas:
#   sesiones      → cada vez que iniciás C.L.A.V.E.
#   escaneos      → cada dispositivo encontrado en cada sesión
#   aprendizaje   → qué marcaste como intruso/seguro manualmente

import sqlite3
import json
import os
from datetime import datetime


class Memoria:
    """
    Sistema de memoria persistente de C.L.A.V.E.
    
    ¿QUÉ ES SQLite?
    Es una base de datos que vive en un solo archivo .db en tu disco.
    No necesita servidor. Es perfecta para apps locales como esta.
    Python la incluye de fábrica con el módulo 'sqlite3'.
    
    ¿QUÉ ES UN CURSOR?
    Cuando abrís una conexión a SQLite, el "cursor" es el objeto
    que ejecuta las consultas SQL. Funciona como un puntero que
    recorre los resultados fila por fila.
    """
    
    ARCHIVO_DB = "datos/clave_memoria.db"
    
    def __init__(self):
        os.makedirs("datos", exist_ok=True)
        self.conexion = sqlite3.connect(
            self.ARCHIVO_DB,
            detect_types=sqlite3.PARSE_DECLTYPES  # para fechas automáticas
        )
        self.conexion.row_factory = sqlite3.Row  # resultados como dicts
        self._crear_tablas()
        self.sesion_id = self._iniciar_sesion()
        print(f"🧠 Memoria iniciada (sesión #{self.sesion_id})")
    
    # ─────────────────────────────────────────────
    #  INICIALIZACIÓN DE TABLAS
    # ─────────────────────────────────────────────
    
    def _crear_tablas(self):
        """
        Crea las tablas si no existen.
        
        ¿QUÉ ES 'IF NOT EXISTS'?
        Le decimos a SQLite que solo cree la tabla si aún no está.
        Así podés ejecutar este método siempre sin errores.
        """
        c = self.conexion.cursor()
        
        # Tabla 1: cada vez que iniciás C.L.A.V.E.
        c.execute("""
            CREATE TABLE IF NOT EXISTS sesiones (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                inicio    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                fin       TIMESTAMP,
                comandos  INTEGER DEFAULT 0,
                notas     TEXT
            )
        """)
        
        # Tabla 2: dispositivos encontrados en cada escaneo
        c.execute("""
            CREATE TABLE IF NOT EXISTS escaneos (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                sesion_id     INTEGER REFERENCES sesiones(id),
                timestamp     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ip            TEXT NOT NULL,
                mac           TEXT,
                fabricante    TEXT,
                nombre_dns    TEXT,
                sistema_op    TEXT,
                puertos_json  TEXT,   -- lista de puertos como JSON
                riesgo        REAL,   -- 0.0 a 1.0 (de neurona.py)
                etiqueta      TEXT,   -- BAJO/MEDIO/ALTO/CRÍTICO
                es_intruso    INTEGER DEFAULT 0,  -- 0=no, 1=sí
                marcado_por_usuario INTEGER DEFAULT 0  -- el usuario lo marcó
            )
        """)
        
        # Tabla 3: aprendizaje manual del usuario
        c.execute("""
            CREATE TABLE IF NOT EXISTS aprendizaje (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ip         TEXT NOT NULL,
                accion     TEXT NOT NULL,  -- 'intruso' o 'seguro'
                mac        TEXT,
                fabricante TEXT,
                notas      TEXT
            )
        """)
        
        # Tabla 4: comandos usados (para que el NLP aprenda cuáles preferís)
        c.execute("""
            CREATE TABLE IF NOT EXISTS historial_comandos (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                sesion_id INTEGER REFERENCES sesiones(id),
                comando   TEXT NOT NULL,
                args      TEXT,
                resultado TEXT  -- 'ok', 'error', 'vacio'
            )
        """)
        
        self.conexion.commit()
    
    # ─────────────────────────────────────────────
    #  SESIONES
    # ─────────────────────────────────────────────
    
    def _iniciar_sesion(self) -> int:
        c = self.conexion.cursor()
        c.execute("INSERT INTO sesiones DEFAULT VALUES")
        self.conexion.commit()
        return c.lastrowid
    
    def cerrar_sesion(self, notas: str = None):
        c = self.conexion.cursor()
        c.execute("""
            UPDATE sesiones
            SET fin = CURRENT_TIMESTAMP, notas = ?
            WHERE id = ?
        """, (notas, self.sesion_id))
        self.conexion.commit()
        self.conexion.close()
        print("💾 Sesión guardada en memoria")
    
    def registrar_comando(self, comando: str, args: str = "", resultado: str = "ok"):
        """Guarda cada comando ejecutado. El NLP usará esto para aprender."""
        c = self.conexion.cursor()
        c.execute("""
            INSERT INTO historial_comandos (sesion_id, comando, args, resultado)
            VALUES (?, ?, ?, ?)
        """, (self.sesion_id, comando, args, resultado))
        # Incrementar contador de comandos en la sesión
        c.execute("UPDATE sesiones SET comandos = comandos + 1 WHERE id = ?",
                  (self.sesion_id,))
        self.conexion.commit()
    
    # ─────────────────────────────────────────────
    #  GUARDAR Y CONSULTAR ESCANEOS
    # ─────────────────────────────────────────────
    
    def guardar_escaneo(self, dispositivos: list, resultados_neuronales: list = None):
        """
        Guarda todos los dispositivos del último escaneo.
        
        ¿POR QUÉ GUARDAMOS LOS PUERTOS COMO JSON?
        Los puertos son una lista de dicts (estructurada).
        SQLite no tiene tipo "lista", así que la convertimos
        a texto JSON y la guardamos en un campo TEXT.
        Al leerla, la convertimos de vuelta con json.loads().
        """
        # Mapa de resultados neuronales por IP
        mapa_neuro = {}
        if resultados_neuronales:
            for r in resultados_neuronales:
                mapa_neuro[r.get("ip")] = r
        
        c = self.conexion.cursor()
        guardados = 0
        
        for d in dispositivos:
            ip = d.get("ip", "")
            neuro = mapa_neuro.get(ip, {})
            
            c.execute("""
                INSERT INTO escaneos 
                (sesion_id, ip, mac, fabricante, nombre_dns, sistema_op,
                 puertos_json, riesgo, etiqueta)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                self.sesion_id,
                ip,
                d.get("mac"),
                d.get("fabricante"),
                d.get("nombre"),
                d.get("sistema_operativo"),
                json.dumps(d.get("puertos", []), ensure_ascii=False),
                neuro.get("riesgo", 0.0),
                neuro.get("etiqueta", "BAJO")
            ))
            guardados += 1
        
        self.conexion.commit()
        print(f"💾 {guardados} dispositivos guardados en memoria")
    
    def dispositivos_nuevos(self, dispositivos_actuales: list) -> list:
        """
        Compara el escaneo actual con el historial.
        Devuelve solo los dispositivos que NO aparecieron antes.
        
        ¿CÓMO FUNCIONA?
        Busca en la tabla escaneos todas las IPs conocidas.
        Las que están en el escaneo actual pero NO en el historial
        son "nuevas" — potencialmente intrusos o dispositivos nuevos.
        """
        c = self.conexion.cursor()
        c.execute("SELECT DISTINCT ip FROM escaneos WHERE sesion_id != ?",
                  (self.sesion_id,))
        ips_conocidas = {row["ip"] for row in c.fetchall()}
        
        nuevos = [d for d in dispositivos_actuales 
                  if d.get("ip") not in ips_conocidas]
        return nuevos
    
    def buscar_dispositivo(self, ip: str) -> dict | None:
        """
        Recupera todo el historial de un IP específico.
        Útil para ver si un dispositivo ya fue marcado como intruso antes.
        """
        c = self.conexion.cursor()
        c.execute("""
            SELECT e.*, s.inicio as sesion_inicio
            FROM escaneos e
            JOIN sesiones s ON e.sesion_id = s.id
            WHERE e.ip = ?
            ORDER BY e.timestamp DESC
            LIMIT 10
        """, (ip,))
        rows = c.fetchall()
        if not rows:
            return None
        
        # Convertir a lista de dicts (Row ya es dict-like)
        historial = []
        for row in rows:
            entrada = dict(row)
            # Deserializar puertos JSON
            if entrada.get("puertos_json"):
                try:
                    entrada["puertos"] = json.loads(entrada["puertos_json"])
                except:
                    entrada["puertos"] = []
            historial.append(entrada)
        
        return {
            "ip": ip,
            "veces_visto": len(historial),
            "primera_vez": historial[-1]["sesion_inicio"],
            "ultima_vez": historial[0]["timestamp"],
            "fue_intruso": any(h.get("marcado_por_usuario") for h in historial),
            "historial": historial
        }
    
    def resumen_sesion_anterior(self) -> str | None:
        """
        Genera un texto con lo que pasó en la última sesión.
        C.L.A.V.E. lo dice al iniciar: 'La última vez encontraste X dispositivos...'
        """
        c = self.conexion.cursor()
        # Buscar la sesión anterior (no la actual)
        c.execute("""
            SELECT s.id, s.inicio, s.fin, s.comandos,
                   COUNT(e.id) as total_dispositivos,
                   SUM(CASE WHEN e.etiqueta IN ('ALTO', 'CRÍTICO') THEN 1 ELSE 0 END) as alto_riesgo
            FROM sesiones s
            LEFT JOIN escaneos e ON s.id = e.sesion_id
            WHERE s.id != ?
            GROUP BY s.id
            ORDER BY s.id DESC
            LIMIT 1
        """, (self.sesion_id,))
        row = c.fetchone()
        
        if not row or not row["total_dispositivos"]:
            return None
        
        fecha = row["inicio"][:10] if row["inicio"] else "antes"
        total = row["total_dispositivos"]
        riesgo = row["alto_riesgo"] or 0
        comandos = row["comandos"] or 0
        
        resumen = f"📋 Última sesión ({fecha}): {total} dispositivos encontrados"
        if riesgo > 0:
            resumen += f", {riesgo} con riesgo ALTO/CRÍTICO ⚠️"
        if comandos > 0:
            resumen += f", {comandos} comandos ejecutados"
        return resumen
    
    # ─────────────────────────────────────────────
    #  APRENDIZAJE MANUAL
    # ─────────────────────────────────────────────
    
    def registrar_marcado(self, ip: str, accion: str, dispositivo: dict = None):
        """
        Guarda cuando el usuario marca manualmente un dispositivo.
        Esto alimenta el entrenamiento de neurona.py con datos reales.
        """
        c = self.conexion.cursor()
        c.execute("""
            INSERT INTO aprendizaje (ip, accion, mac, fabricante)
            VALUES (?, ?, ?, ?)
        """, (
            ip, accion,
            dispositivo.get("mac") if dispositivo else None,
            dispositivo.get("fabricante") if dispositivo else None
        ))
        # También actualizar el flag en escaneos
        c.execute("""
            UPDATE escaneos SET marcado_por_usuario = 1,
            es_intruso = ?
            WHERE ip = ? AND sesion_id = ?
        """, (1 if accion == "intruso" else 0, ip, self.sesion_id))
        self.conexion.commit()
    
    def obtener_ejemplos_entrenamiento(self) -> list:
        """
        Extrae los dispositivos marcados manualmente para re-entrenar neurona.py.
        Devuelve lista de (ip, accion, dispositivo_dict).
        """
        c = self.conexion.cursor()
        c.execute("""
            SELECT a.ip, a.accion, e.mac, e.fabricante, 
                   e.nombre_dns, e.sistema_op, e.puertos_json
            FROM aprendizaje a
            LEFT JOIN escaneos e ON a.ip = e.ip
            ORDER BY a.timestamp DESC
        """)
        rows = c.fetchall()
        
        ejemplos = []
        for row in rows:
            d = dict(row)
            puertos = []
            if d.get("puertos_json"):
                try:
                    puertos = json.loads(d["puertos_json"])
                except:
                    pass
            
            dispositivo = {
                "ip": d["ip"],
                "mac": d.get("mac", "No disponible"),
                "fabricante": d.get("fabricante", "Desconocido"),
                "nombre": d.get("nombre_dns", "Desconocido"),
                "sistema_operativo": d.get("sistema_op", "Desconocido"),
                "puertos": puertos
            }
            ejemplos.append((dispositivo, d["accion"]))
        
        return ejemplos
    
    # ─────────────────────────────────────────────
    #  ESTADÍSTICAS (para el NLP y la interfaz)
    # ─────────────────────────────────────────────
    
    def estadisticas(self) -> dict:
        """Devuelve métricas generales del uso de C.L.A.V.E."""
        c = self.conexion.cursor()
        
        c.execute("SELECT COUNT(*) as total FROM sesiones")
        total_sesiones = c.fetchone()["total"]
        
        c.execute("SELECT COUNT(DISTINCT ip) as total FROM escaneos")
        ips_unicas = c.fetchone()["total"]
        
        c.execute("""
            SELECT comando, COUNT(*) as usos 
            FROM historial_comandos 
            GROUP BY comando 
            ORDER BY usos DESC 
            LIMIT 5
        """)
        top_comandos = [(r["comando"], r["usos"]) for r in c.fetchall()]
        
        c.execute("""
            SELECT COUNT(*) as total FROM aprendizaje 
            WHERE accion = 'intruso'
        """)
        intrusos_marcados = c.fetchone()["total"]
        
        return {
            "total_sesiones": total_sesiones,
            "ips_unicas_vistas": ips_unicas,
            "intrusos_marcados": intrusos_marcados,
            "top_comandos": top_comandos
        }
    
    def mostrar_estadisticas(self):
        stats = self.estadisticas()
        print("\n📊 ESTADÍSTICAS DE C.L.A.V.E.")
        print("=" * 40)
        print(f"  Sesiones totales:      {stats['total_sesiones']}")
        print(f"  IPs únicas vistas:     {stats['ips_unicas_vistas']}")
        print(f"  Intrusos marcados:     {stats['intrusos_marcados']}")
        if stats["top_comandos"]:
            print(f"  Comandos más usados:")
            for cmd, n in stats["top_comandos"]:
                print(f"    {cmd:20} × {n}")
        print("=" * 40)