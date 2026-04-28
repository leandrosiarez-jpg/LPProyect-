# exportador.py - Exportar resultados en múltiples formatos

import json
import csv
import os
from datetime import datetime

class Exportador:
    def __init__(self):
        self.carpeta = "datos/resultados"
        os.makedirs(self.carpeta, exist_ok=True)
    
    def exportar_json(self, datos, nombre=None):
        if not nombre:
            nombre = f"escaneo_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        archivo = f"{self.carpeta}/{nombre}.json"
        with open(archivo, 'w', encoding='utf-8') as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "total": len(datos),
                "dispositivos": datos
            }, f, indent=2, ensure_ascii=False)
        
        print(f"💾 Exportado a JSON: {archivo}")
        return archivo
    
    def exportar_csv(self, datos, nombre=None):
        if not nombre:
            nombre = f"escaneo_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        archivo = f"{self.carpeta}/{nombre}.csv"
        with open(archivo, 'w', newline='', encoding='utf-8') as f:
            if datos:
                campos = datos[0].keys()
                writer = csv.DictWriter(f, fieldnames=campos)
                writer.writeheader()
                writer.writerows(datos)
        
        print(f"💾 Exportado a CSV: {archivo}")
        return archivo
    
    def exportar_txt(self, datos, nombre=None):
        if not nombre:
            nombre = f"escaneo_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        archivo = f"{self.carpeta}/{nombre}.txt"
        with open(archivo, 'w', encoding='utf-8') as f:
            f.write("=" * 70 + "\n")
            f.write(f"C.L.A.V.E. - Reporte de Escaneo\n")
            f.write(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Total dispositivos: {len(datos)}\n")
            f.write("=" * 70 + "\n\n")
            
            for i, d in enumerate(datos, 1):
                f.write(f"{i}. IP: {d.get('ip', 'N/A')}\n")
                f.write(f"   Nombre: {d.get('nombre', 'Desconocido')}\n")
                f.write(f"   MAC: {d.get('mac', 'N/A')}\n")
                f.write(f"   Fabricante: {d.get('fabricante', 'Desconocido')}\n")
                f.write(f"   SO: {d.get('sistema_operativo', 'Desconocido')}\n")
                if d.get('puertos'):
                    puertos_str = ", ".join([f"{p['puerto']}({p['servicio']})" for p in d['puertos']])
                    f.write(f"   Puertos: {puertos_str}\n")
                f.write("\n")
        
        print(f"💾 Exportado a TXT: {archivo}")
        return archivo
    
    def exportar_html(self, datos, nombre=None):
        """Exporta a HTML con formato bonito"""
        if not nombre:
            nombre = f"escaneo_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        archivo = f"{self.carpeta}/{nombre}.html"
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>C.L.A.V.E. - Reporte de Escaneo</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; background: #1e1e2e; color: #cdd6f4; }}
                h1 {{ color: #89b4fa; }}
                table {{ border-collapse: collapse; width: 100%; margin-top: 20px; }}
                th, td {{ border: 1px solid #313244; padding: 10px; text-align: left; }}
                th {{ background: #313244; }}
                tr:hover {{ background: #313244; }}
                .ip {{ color: #89b4fa; font-family: monospace; }}
                .activo {{ color: #a6e3a1; }}
                .puertos {{ color: #f9e2af; }}
            </style>
        </head>
        <body>
            <h1>🔍 C.L.A.V.E. - Reporte de Escaneo de Red</h1>
            <p><strong>Fecha:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p><strong>Total dispositivos:</strong> {len(datos)}</p>
            
            <table>
                <tr>
                    <th>#</th>
                    <th>IP</th>
                    <th>Nombre</th>
                    <th>MAC</th>
                    <th>Fabricante</th>
                    <th>SO</th>
                    <th>Puertos</th>
                </tr>
        """
        
        for i, d in enumerate(datos, 1):
            puertos_str = ", ".join([f"{p['puerto']}" for p in d.get('puertos', [])]) if d.get('puertos') else "-"
            html += f"""
                <tr>
                    <td>{i}</td>
                    <td class="ip">{d.get('ip', 'N/A')}</td>
                    <td>{d.get('nombre', 'Desconocido')}</td>
                    <td>{d.get('mac', 'N/A')}</td>
                    <td>{d.get('fabricante', 'Desconocido')}</td>
                    <td>{d.get('sistema_operativo', 'Desconocido')}</td>
                    <td class="puertos">{puertos_str}</td>
                </tr>
            """
        
        html += """
            </table>
        </body>
        </html>
        """
        
        with open(archivo, 'w', encoding='utf-8') as f:
            f.write(html)
        
        print(f"💾 Exportado a HTML: {archivo}")
        return archivo
    
    def listar_escaneos(self):
        """Lista todos los escaneos guardados"""
        archivos = os.listdir(self.carpeta) if os.path.exists(self.carpeta) else []
        return archivos