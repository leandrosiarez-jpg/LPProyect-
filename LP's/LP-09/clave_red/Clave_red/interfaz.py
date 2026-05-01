# interfaz.py - Interfaz de comandos completa

import os
import time

class Interfaz:
    def __init__(self, clave):
        self.clave = clave
        self.running = True
    
    def iniciar(self):
        while self.running:
            try:
                cmd = input("\n🔧 C.L.A.V.E.> ").strip()
                if not cmd:
                    continue
                self.ejecutar_comando(cmd)
            except KeyboardInterrupt:
                print("\n")
                self.comando_salir()
            except Exception as e:
                print(f"❌ Error: {e}")
    
    def ejecutar_comando(self, cmd):
        cmd_parts = cmd.lower().split()
        comando = cmd_parts[0]
        args = cmd_parts[1:] if len(cmd_parts) > 1 else []
        
        if comando == "salir":
            self.comando_salir()
        
        elif comando == "ayuda" or comando == "help":
            self.comando_ayuda()
        
        elif comando == "voz_on":
            self.clave.voz.activar()
        elif comando == "voz_off":
            self.clave.voz.desactivar()
        
        elif comando == "scan":
            self.comando_scan()
        elif comando == "scan_rapido":
            self.comando_scan_rapido()
        elif comando == "scan_profundo":
            self.comando_scan_profundo()
        
        elif comando == "scan_rango" and len(args) >= 2:
            self.comando_scan_rango(args[0], args[1])
        
        elif comando == "info" and len(args) >= 1:
            self.comando_info(args[0])
        elif comando == "puertos" and len(args) >= 1:
            self.comando_puertos(args[0])
        elif comando == "todos_puertos" and len(args) >= 1:
            self.comando_todos_puertos(args[0])
        elif comando == "mac" and len(args) >= 1:
            self.comando_mac(args[0])
        elif comando == "ping" and len(args) >= 1:
            self.comando_ping(args[0])
        
        elif comando in ["mi_ip", "miip"]:
            self.comando_mi_ip()
        elif comando == "gateway":
            self.comando_gateway()
        elif comando == "iptype":
            self.comando_iptype()
        elif comando == "so" and len(args) >= 1:
            self.comando_so(args[0])
        
        elif comando == "dispositivos_tipo" and len(args) >= 1:
            self.comando_filtrar_tipo(args[0])
        elif comando == "dispositivos_so" and len(args) >= 1:
            self.comando_filtrar_so(args[0])
        elif comando == "top_10_puertos":
            self.comando_top_puertos()
        
        elif comando == "export_json":
            self.comando_export_json()
        elif comando == "export_csv":
            self.comando_export_csv()
        elif comando == "export_txt":
            self.comando_export_txt()
        elif comando == "export_html":
            self.comando_export_html()
        
        elif comando == "ver_historial":
            self.comando_historial()
        elif comando == "comparar":
            self.comando_comparar()
        
        elif comando == "monitorear":
            intervalo = int(args[0]) if args else 30
            self.comando_monitorear(intervalo)
        elif comando == "watch" and len(args) >= 1:
            self.comando_watch(args[0])
        
        elif comando == "scan_wifi":
            self.comando_scan_wifi()
        
        elif comando == "analizar":
            self.comando_analizar()
        elif comando == "informe":
            self.comando_informe()
        
        elif comando == "neuro" or comando == "neuronal":
            self.comando_neuronal()
        elif comando == "marcar_intruso" and len(args) >= 1:
            self.clave.escaner.marcar_intruso(args[0])
        elif comando == "marcar_seguro" and len(args) >= 1:
            self.clave.escaner.marcar_seguro(args[0])
        elif comando == "neuro_estado":
            self.clave.escaner.estado_neuronas()
        
        else:
            print(f"❌ Comando '{comando}' no reconocido. Escribí 'ayuda' para ver todos los comandos")
    
    def comando_ayuda(self):
        print("\n" + "=" * 70)
        print("📋 C.L.A.V.E. - TODOS LOS COMANDOS DISPONIBLES")
        print("=" * 70)
        for cmd, desc in self.clave.comandos.items():
            print(f"   {cmd:20} - {desc}")
        print("-" * 70)
        print("\n📌 Comandos adicionales:")
        print("   voz_on               - Activar voz")
        print("   voz_off              - Desactivar voz")
        print("   export_html          - Exportar a HTML")
        print("   dispositivos_tipo    - Filtrar por fabricante")
        print("   comparar             - Comparar escaneos anteriores")
        print("   analizar             - Análisis de seguridad de la red")
    
    def comando_salir(self):
        self.clave.voz.decir("Cerrando C L A V E")
        print("👋 C.L.A.V.E. cerrada")
        self.running = False
    
    def comando_scan(self):
        self.clave.voz.decir("Iniciando escaneo completo de red")
        resultados = self.clave.escaner.escanear_red_completo()
        if resultados:
            print(f"\n📡 Encontrados {len(resultados)} dispositivos")
            self.clave.voz.decir(f"Encontrados {len(resultados)} dispositivos")
        self.clave.exportador.exportar_json(resultados)
    
    def comando_scan_rapido(self):
        self.clave.voz.decir("Iniciando escaneo rápido")
        resultados = self.clave.escaner.escanear_rapido()
        print(f"\n📡 Encontrados {len(resultados)} dispositivos")
    
    def comando_scan_profundo(self):
        self.clave.voz.decir("Iniciando escaneo profundo con puertos")
        resultados = self.clave.escaner.escanear_red_completo()
        self.comando_top_puertos()
    
    def comando_scan_rango(self, inicio, fin):
        self.clave.voz.decir(f"Escaneando rango {inicio} a {fin}")
        resultados = self.clave.escaner.escanear_rango(inicio, fin)
        print(f"\n📡 Encontrados {len(resultados)} dispositivos")
    
    def comando_info(self, ip):
        self.clave.voz.decir(f"Obteniendo información de {ip}")
        print(f"\n🔍 Información detallada de {ip}")
        print("=" * 50)
        
        activo, ttl = self.clave.escaner.ping_capturar_ttl(ip)
        if not activo:
            print("❌ No responde al ping")
            return
        
        print("✅ Estado: Activo")
        nombre = self.clave.escaner.obtener_nombre_dns(ip)
        if nombre:
            print(f"📛 Nombre DNS: {nombre}")
        
        mac = self.clave.escaner.obtener_mac(ip)
        if mac:
            print(f"🔌 MAC: {mac}")
            print(f"🏭 Fabricante: {self.clave.escaner.fabricante_por_mac(mac)}")
        
        if ttl:
            so = self.clave.escaner.detectar_so(ttl)
            print(f"💿 SO probable: {so} (TTL={ttl})")
        
        puertos = self.clave.escaner.escanear_puertos(ip)
        if puertos:
            print(f"\n🚪 Puertos abiertos:")
            for p in puertos:
                print(f"   → {p['puerto']} - {p['servicio']}")
    
    def comando_puertos(self, ip):
        self.clave.voz.decir(f"Escaneando puertos de {ip}")
        puertos = self.clave.escaner.escanear_puertos(ip)
        if puertos:
            print(f"\n🚪 Puertos abiertos en {ip}:")
            for p in puertos:
                print(f"   {p['puerto']} - {p['servicio']}")
        else:
            print(f"No se encontraron puertos abiertos en {ip}")
    
    def comando_todos_puertos(self, ip):
        self.clave.voz.decir(f"Escaneando todos los puertos de {ip}. Esto puede tomar varios minutos.")
        puertos = self.clave.escaner.escanear_todos_los_puertos(ip)
        print(f"\n📡 Total puertos abiertos: {len(puertos)}")
    
    def comando_mac(self, ip):
        mac = self.clave.escaner.obtener_mac(ip)
        if mac:
            fab = self.clave.escaner.fabricante_por_mac(mac)
            print(f"🔌 MAC: {mac}")
            print(f"🏭 Fabricante: {fab}")
            self.clave.voz.decir(f"MAC de {ip} es {mac}, fabricante {fab}")
        else:
            print(f"No se pudo obtener MAC de {ip}")
    
    def comando_ping(self, ip):
        if self.clave.escaner.ping(ip):
            print(f"✅ {ip} responde al ping")
            self.clave.voz.decir(f"{ip} responde")
        else:
            print(f"❌ {ip} no responde al ping")
    
    def comando_mi_ip(self):
        ip = self.clave.escaner.obtener_ip_local()
        print(f"📍 IP Local: {ip}")
        self.clave.voz.decir(f"Mi IP local es {ip}")
    
    def comando_gateway(self):
        gw = self.clave.escaner.obtener_gateway()
        if gw:
            print(f"🌐 Gateway: {gw}")
            self.clave.voz.decir(f"El gateway es {gw}")
        else:
            print("No se pudo detectar el gateway")
    
    def comando_iptype(self):
        tipo = self.clave.escaner.tipo_red()
        print(f"📡 {tipo}")
    
    def comando_so(self, ip):
        activo, ttl = self.clave.escaner.ping_capturar_ttl(ip)
        if activo and ttl:
            so = self.clave.escaner.detectar_so(ttl)
            print(f"💿 SO probable en {ip}: {so} (TTL={ttl})")
        else:
            print(f"No se pudo determinar SO de {ip}")
    
    def comando_filtrar_tipo(self, tipo):
        resultados = self.clave.escaner.filtrar_por_tipo(tipo)
        print(f"\n📡 Dispositivos {tipo}: {len(resultados)}")
        for d in resultados:
            print(f"   {d['ip']} - {d.get('nombre', 'Desconocido')}")
    
    def comando_filtrar_so(self, so):
        resultados = self.clave.escaner.filtrar_por_so(so)
        print(f"\n📡 Dispositivos {so}: {len(resultados)}")
        for d in resultados:
            print(f"   {d['ip']} - {d.get('nombre', 'Desconocido')}")
    
    def comando_top_puertos(self):
        top = self.clave.escaner.obtener_top_puertos()
        if top:
            print("\n📊 Puertos más comunes en la red:")
            for puerto, servicio, count in top:
                print(f"   Puerto {puerto} ({servicio}) - aparece en {count} dispositivos")
    
    def comando_export_json(self):
        if self.clave.escaner.ultimos_resultados:
            self.clave.exportador.exportar_json(self.clave.escaner.ultimos_resultados)
        else:
            print("No hay resultados para exportar. Ejecutá 'scan' primero.")
    
    def comando_export_csv(self):
        if self.clave.escaner.ultimos_resultados:
            self.clave.exportador.exportar_csv(self.clave.escaner.ultimos_resultados)
        else:
            print("No hay resultados para exportar")
    
    def comando_export_txt(self):
        if self.clave.escaner.ultimos_resultados:
            self.clave.exportador.exportar_txt(self.clave.escaner.ultimos_resultados)
        else:
            print("No hay resultados para exportar")
    
    def comando_export_html(self):
        if self.clave.escaner.ultimos_resultados:
            self.clave.exportador.exportar_html(self.clave.escaner.ultimos_resultados)
        else:
            print("No hay resultados para exportar")
    
    def comando_historial(self):
        historial = self.clave.escaner.obtener_historial()
        if not historial:
            print("No hay escaneos en el historial")
            return
        for i, h in enumerate(historial):
            print(f"{i}: {h['timestamp']} - {h['total']} dispositivos")
    
    def comando_comparar(self):
        resultado = self.clave.escaner.comparar_escaneos()
        print(resultado)
    
    def comando_monitorear(self, intervalo):
        print(f"🔍 Monitoreando cada {intervalo} segundos. Presioná Ctrl+C para detener.")
        try:
            self.clave.escaner.monitorear_red(intervalo)
        except KeyboardInterrupt:
            print("\n✅ Monitoreo detenido")
    
    def comando_watch(self, ip):
        print(f"🔍 Observando {ip}. Presioná Ctrl+C para detener.")
        try:
            self.clave.escaner.watch_ip(ip)
        except KeyboardInterrupt:
            print("\n✅ Observación detenida")
    
    def comando_scan_wifi(self):
        self.clave.voz.decir("Escaneando redes WiFi cercanas")
        print("\n🔍 Función WiFi - Requiere hardware compatible")
        print("   En Windows: netsh wlan show networks")
        try:
            import subprocess
            resultado = subprocess.run(["netsh", "wlan", "show", "networks"], capture_output=True, text=True)
            print(resultado.stdout)
        except:
            print("   No se pudo escanear WiFi. ¿Tienes tarjeta WiFi?")
    
    def comando_analizar(self):
        if not self.clave.escaner.ultimos_resultados:
            print("Ejecutá 'scan' primero para analizar la red")
            return
        
        print("\n📊 ANÁLISIS DE SEGURIDAD DE LA RED")
        print("=" * 50)
        
        # Conteos
        total = len(self.clave.escaner.ultimos_resultados)
        con_mac = sum(1 for d in self.clave.escaner.ultimos_resultados if d.get('mac') != 'No disponible')
        con_puertos = sum(1 for d in self.clave.escaner.ultimos_resultados if d.get('puertos'))
        
        print(f"📡 Total dispositivos: {total}")
        print(f"🔌 Dispositivos con MAC detectable: {con_mac}")
        print(f"🚪 Dispositivos con puertos abiertos: {con_puertos}")
        
        # Puertos peligrosos
        puertos_peligrosos = {21: "FTP (inseguro)", 23: "Telnet (inseguro)", 445: "SMB (vulnerable)"}
        hosts_riesgosos = []
        
        for d in self.clave.escaner.ultimos_resultados:
            for p in d.get('puertos', []):
                if p['puerto'] in puertos_peligrosos:
                    hosts_riesgosos.append((d['ip'], p['puerto'], puertos_peligrosos[p['puerto']]))
        
        if hosts_riesgosos:
            print("\n⚠️ DISPOSITIVOS CON PUERTOS RIESGOSOS:")
            for ip, puerto, servicio in hosts_riesgosos[:10]:
                print(f"   → {ip}: puerto {puerto} ({servicio})")
        
        # Recomendaciones
        print("\n💡 RECOMENDACIONES:")
        if con_puertos > 0:
            print("   • Cerrar puertos no utilizados en el firewall")
        if hosts_riesgosos:
            print("   • Evitar usar FTP/Telnet (usar SSH/SFTP)")
            print("   • Deshabilitar SMB si no es necesario")
        print("   • Mantener firmware actualizado de routers y dispositivos IoT")
    
    def comando_informe(self):
        self.comando_analizar()
        self.comando_export_html()
        self.clave.voz.decir("Informe generado")

    def comando_neuronal(self):
        self.clave.voz.decir("Iniciando análisis neuronal")
        self.clave.escaner.analizar_con_neuronas()