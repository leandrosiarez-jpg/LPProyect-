# escaner.py - Todas las funciones de escaneo de red

import socket
import subprocess
import threading
import ipaddress
import time
import platform
import re
from datetime import datetime

class EscanerRed:
    def __init__(self):
        self.sistema = platform.system()
        self.ultimos_resultados = []
        self.historial_escaneos = []
        
        # Base de datos completa de fabricantes
        self.fabricantes = {
            # Apple
            "00:00:00": "Apple (antiguo)", "00:03:93": "Apple", "00:05:02": "Apple",
            "00:0A:27": "Apple", "00:0D:93": "Apple", "00:0E:9F": "Apple",
            "00:10:FA": "Apple", "00:11:24": "Apple", "00:12:00": "Apple",
            "00:14:51": "Apple", "00:16:CB": "Apple", "00:17:F2": "Apple",
            "00:19:E3": "Apple", "00:1C:B3": "Apple", "00:1E:52": "Apple",
            "00:1E:C2": "Apple", "00:1F:5B": "Apple", "00:21:E9": "Apple",
            "00:23:6C": "Apple", "00:25:00": "Apple", "00:26:08": "Apple",
            "00:27:24": "Apple", "3C:15:C2": "Apple", "F0:18:98": "Apple",
            "8C:FA:BA": "Apple", "D4:F4:6F": "Apple", "9C:F3:87": "Apple",
            "B8:4D:12": "Apple", "C4:2C:03": "Apple",
            
            # Samsung
            "00:01:36": "Samsung", "00:13:77": "Samsung", "00:15:99": "Samsung",
            "00:19:40": "Samsung", "00:1C:F0": "Samsung", "00:22:6B": "Samsung",
            "00:25:9B": "Samsung", "38:AA:3C": "Samsung", "90:18:7C": "Samsung",
            
            # Raspberry Pi
            "B8:27:EB": "Raspberry Pi", "DC:A6:32": "Raspberry Pi",
            "E4:5F:01": "Raspberry Pi", "28:CD:C1": "Raspberry Pi",
            
            # Google
            "DC:A6:32": "Google", "00:1A:11": "Google", "AC:9E:17": "Google",
            "94:EB:2C": "Google", "F0:A3:5A": "Google",
            
            # Dell
            "00:14:22": "Dell", "00:1D:09": "Dell", "00:21:70": "Dell",
            "00:23:7D": "Dell", "F0:4D:A2": "Dell", "00:13:72": "Dell",
            
            # HP
            "00:1A:2B": "HP", "00:1E:0B": "HP", "00:21:5A": "HP",
            "00:23:BB": "HP", "9C:B6:D0": "HP", "00:1B:78": "HP",
            
            # Lenovo
            "00:1C:25": "Lenovo", "00:23:7E": "Lenovo", "F0:76:1C": "Lenovo",
            
            # Virtualización
            "08:00:27": "VirtualBox", "00:0C:29": "VMware", "00:50:56": "VMware",
            "00:05:69": "VMware", "00:15:5D": "Hyper-V",
            
            # Cisco
            "00:1A:6C": "Cisco", "00:1D:45": "Cisco", "00:24:96": "Cisco",
            "00:0D:BD": "Cisco", "00:1A:8C": "Cisco", "00:1B:54": "Cisco",
            
            # Netgear
            "00:0F:66": "Netgear", "00:1B:2F": "Netgear", "00:22:3F": "Netgear",
            
            # TP-Link
            "00:1D:AA": "TP-Link", "00:25:9C": "TP-Link", "D8:5D:4C": "TP-Link",
            
            # Huawei
            "00:1E:10": "Huawei", "28:6C:07": "Huawei", "34:80:B3": "Huawei",
            
            # Xiaomi
            "34:CE:00": "Xiaomi", "48:46:FB": "Xiaomi", "60:64:05": "Xiaomi",
            
            # Nintendo
            "00:1E:35": "Nintendo", "00:22:79": "Nintendo", "00:0E:5C": "Nintendo",
            
            # Sony
            "00:0F:53": "Sony", "00:1D:D2": "Sony", "08:00:46": "Sony",
            
            # Microsoft
            "00:03:FF": "Microsoft", "00:0D:3A": "Microsoft", "00:1F:3A": "Microsoft",
            
            # Intel
            "00:04:23": "Intel", "00:13:59": "Intel", "00:15:00": "Intel",
            
            # Acer
            "00:1D:72": "Acer", "00:23:8B": "Acer", "B8:AE:6E": "Acer",
            
            # Asus
            "00:22:15": "Asus", "00:25:9E": "Asus", "10:BF:48": "Asus",
            
            # Xiaomi
            "34:CE:00": "Xiaomi", "48:46:FB": "Xiaomi", "60:64:05": "Xiaomi",
            
            # OnePlus
            "E8:BB:5D": "OnePlus", "A8:66:7D": "OnePlus",
            
            # LG
            "00:1A:7D": "LG", "00:24:FE": "LG", "A4:77:33": "LG",
            
            # Philips
            "00:12:47": "Philips", "00:18:0A": "Philips", "00:23:DF": "Philips",
            
            # Bosch
            "00:21:08": "Bosch", "00:24:7A": "Bosch",
        }
        
        # Base de datos de servicios por puerto
        self.puertos_servicios = {
            # Puertos comunes
            20: "FTP-Datos", 21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP",
            53: "DNS", 67: "DHCP-Server", 68: "DHCP-Client", 69: "TFTP",
            80: "HTTP", 110: "POP3", 111: "RPC", 119: "NNTP", 123: "NTP",
            135: "RPC", 137: "NetBIOS-NS", 138: "NetBIOS-DGM", 139: "NetBIOS-SSN",
            143: "IMAP", 161: "SNMP", 162: "SNMP-Trap", 179: "BGP", 194: "IRC",
            389: "LDAP", 443: "HTTPS", 445: "SMB", 465: "SMTPS", 514: "Syslog",
            515: "LPD", 543: "Kerberos", 544: "Kerberos", 548: "AFP",
            554: "RTSP", 587: "SMTP", 631: "IPP", 636: "LDAPS", 873: "rsync",
            989: "FTPS-Data", 990: "FTPS", 993: "IMAPS", 995: "POP3S",
            1025: "NFS", 1194: "OpenVPN", 1433: "MSSQL", 1434: "MSSQL-Monitor",
            1720: "H323", 1723: "PPTP", 1900: "UPnP", 2049: "NFS",
            2082: "cPanel", 2083: "cPanel-SSL", 2086: "WHM", 2087: "WHM-SSL",
            2095: "Webmail", 2096: "Webmail-SSL", 2181: "ZooKeeper",
            2222: "DirectAdmin", 2375: "Docker", 2376: "Docker-SSL",
            2480: "OrientDB", 3000: "Node.js", 3128: "Squid", 3306: "MySQL",
            3389: "RDP", 3690: "SVN", 4369: "Erlang", 5000: "UPnP",
            5001: "UPnP", 5060: "SIP", 5061: "SIP-TLS", 5222: "XMPP",
            5223: "XMPP", 5432: "PostgreSQL", 5500: "VNC", 5601: "Kibana",
            5800: "VNC", 5900: "VNC", 5901: "VNC", 5938: "TeamViewer",
            5984: "CouchDB", 6000: "X11", 6001: "X11", 6379: "Redis",
            6667: "IRC", 6881: "BitTorrent", 6889: "BitTorrent", 6969: "BitTorrent",
            7000: "Cassandra", 7077: "Apache", 7474: "Neo4j", 7475: "Neo4j",
            7547: "TR-069", 8000: "HTTP-Alt", 8008: "HTTP-Alt", 8009: "AJP",
            8010: "HTTP-Alt", 8042: "HTTP-Alt", 8069: "Zabbix", 8080: "HTTP-Proxy",
            8081: "HTTP-Proxy", 8086: "InfluxDB", 8087: "HTTP-Alt", 8088: "HTTP-Alt",
            8089: "Splunk", 8096: "Emby", 8140: "Puppet", 8181: "Hadoop",
            8333: "Bitcoin", 8443: "HTTPS-Alt", 8880: "HTTP-Alt", 8883: "MQTT",
            8888: "Jupyter", 8983: "Solr", 9000: "PHP-FPM", 9001: "SonarQube",
            9042: "Cassandra", 9092: "Kafka", 9100: "Print", 9200: "Elasticsearch",
            9290: "Elasticsearch", 9300: "Elasticsearch", 9418: "Git", 9999: "Webmin",
            10000: "Webmin", 11211: "Memcached", 15672: "RabbitMQ", 16080: "Mac",
            16384: "RTP", 20000: "DNP", 27017: "MongoDB", 30000: "Jenkins",
            };
    
    def obtener_ip_local(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "127.0.0.1"
    
    def obtener_gateway(self):
        ip_local = self.obtener_ip_local()
        partes = ip_local.split('.')
        if len(partes) == 4:
            posibles = [f"{partes[0]}.{partes[1]}.{partes[2]}.1",
                       f"{partes[0]}.{partes[1]}.{partes[2]}.254",
                       f"{partes[0]}.{partes[1]}.{partes[2]}.0",
                       f"{partes[0]}.{partes[1]}.1.1"]
            for p in posibles:
                if self.ping(p):
                    return p
        return None
    
    def obtener_dns_primario(self):
        try:
            resultado = subprocess.run(["nslookup", "google.com"], capture_output=True, text=True)
            for linea in resultado.stdout.split('\n'):
                if "Server:" in linea or "Servidor:" in linea:
                    partes = linea.split()
                    if len(partes) > 1:
                        return partes[1]
        except:
            pass
        return None
    
    def ping(self, ip, timeout=1):
        try:
            param = "-n" if self.sistema == "Windows" else "-c"
            subprocess.run(["ping", param, "1", "-w", str(int(timeout * 1000)), ip],
                          capture_output=True, timeout=timeout + 1)
            return True
        except:
            return False
    
    def ping_capturar_ttl(self, ip):
        try:
            param = "-n" if self.sistema == "Windows" else "-c"
            resultado = subprocess.run(["ping", param, "1", ip], capture_output=True, text=True)
            if resultado.returncode == 0:
                for linea in resultado.stdout.split('\n'):
                    if "TTL=" in linea.upper():
                        ttl = int(linea.upper().split('TTL=')[1].split()[0])
                        return True, ttl
            return True, None
        except:
            return False, None
    
    def obtener_mac(self, ip):
        try:
            if self.sistema == "Windows":
                resultado = subprocess.run(["arp", "-a", ip], capture_output=True, text=True)
                for linea in resultado.stdout.split('\n'):
                    if ip in linea:
                        partes = linea.split()
                        for parte in partes:
                            if ":" in parte and len(parte) == 17:
                                return parte.upper()
            else:
                resultado = subprocess.run(["arp", "-n", ip], capture_output=True, text=True)
                for linea in resultado.stdout.split('\n'):
                    if ip in linea:
                        partes = linea.split()
                        if len(partes) >= 3 and ":" in partes[2]:
                            return partes[2].upper()
        except:
            pass
        return None
    
    def fabricante_por_mac(self, mac):
        if not mac:
            return "Desconocido"
        mac_upper = mac.upper()
        for i in range(8, 0, -2):
            prefijo = mac_upper[:i]
            if prefijo in self.fabricantes:
                return self.fabricantes[prefijo]
        return "Desconocido"
    
    def obtener_nombre_dns(self, ip):
        try:
            return socket.gethostbyaddr(ip)[0]
        except:
            return None
    
    def detectar_so(self, ttl):
        if not ttl:
            return "Desconocido"
        if ttl <= 64:
            return "Linux/Unix/Mac"
        elif ttl <= 128:
            return "Windows"
        elif ttl <= 255:
            return "Router/Switch/Cisco"
        return "Desconocido"
    
    def escanear_puertos(self, ip, puertos=None):
        if puertos is None:
            puertos = [21, 22, 23, 25, 53, 80, 110, 139, 143, 443, 445, 
                      993, 995, 1433, 1723, 3306, 3389, 5432, 5900, 8080, 8443]
        
        abiertos = []
        for puerto in puertos:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(0.3)
                if sock.connect_ex((ip, puerto)) == 0:
                    servicio = self.puertos_servicios.get(puerto, "Desconocido")
                    abiertos.append({"puerto": puerto, "servicio": servicio})
                sock.close()
            except:
                pass
        return abiertos
    
    def escanear_todos_los_puertos(self, ip):
        """Escanea los 65535 puertos (puede tomar varios minutos)"""
        abiertos = []
        print(f"🔍 Escaneando TODOS los puertos de {ip}... (hasta 65535)")
        for puerto in range(1, 65536):
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(0.1)
                if sock.connect_ex((ip, puerto)) == 0:
                    servicio = self.puertos_servicios.get(puerto, "Desconocido")
                    abiertos.append({"puerto": puerto, "servicio": servicio})
                    print(f"   Puerto {puerto} abierto - {servicio}")
                sock.close()
            except:
                pass
            if puerto % 1000 == 0:
                print(f"   Progreso: {puerto}/65535")
        return abiertos
    
    def escanear_red_completo(self, red_especifica=None):
        """Escanear toda la red con todas las opciones"""
        if red_especifica:
            red = red_especifica
        else:
            ip_local = self.obtener_ip_local()
            partes = ip_local.split('.')
            red = f"{partes[0]}.{partes[1]}.{partes[2]}.0/24" if len(partes) == 4 else "192.168.1.0/24"
        
        print(f"\n🔍 Escaneando red: {red}")
        print("⏳ Esto tomará ~1-3 minutos...")
        
        try:
            red_ip = ipaddress.ip_network(red, strict=False)
        except:
            return []
        
        resultados = []
        hilos = []
        
        def escanear_ip(ip):
            activo, ttl = self.ping_capturar_ttl(ip)
            if activo:
                mac = self.obtener_mac(ip)
                nombre = self.obtener_nombre_dns(ip)
                fabricante = self.fabricante_por_mac(mac)
                so = self.detectar_so(ttl)
                puertos = self.escanear_puertos(ip)
                
                resultados.append({
                    "ip": ip,
                    "activo": True,
                    "nombre": nombre or "Desconocido",
                    "mac": mac or "No disponible",
                    "fabricante": fabricante,
                    "sistema_operativo": so,
                    "ttl": ttl,
                    "puertos": puertos
                })
                print(f"✅ {ip} - {nombre or 'Desconocido'} - {fabricante} - {so}")
        
        for ip in red_ip.hosts():
            hilo = threading.Thread(target=escanear_ip, args=(str(ip),))
            hilo.start()
            hilos.append(hilo)
        
        for hilo in hilos:
            hilo.join()
        
        self.ultimos_resultados = resultados
        self.guardar_historial(resultados)
        return resultados
    
    def escanear_rapido(self):
        """Solo ping para encontrar dispositivos rápidamente"""
        ip_local = self.obtener_ip_local()
        partes = ip_local.split('.')
        base = f"{partes[0]}.{partes[1]}.{partes[2]}" if len(partes) == 4 else "192.168.1"
        
        print(f"\n🔍 Escaneo rápido {base}.0/24...")
        resultados = []
        
        for i in range(1, 255):
            ip = f"{base}.{i}"
            if self.ping(ip, timeout=0.5):
                nombre = self.obtener_nombre_dns(ip)
                resultados.append({"ip": ip, "nombre": nombre or "Desconocido"})
                print(f"✅ {ip} - {nombre or 'Desconocido'}")
        
        return resultados
    
    def escanear_rango(self, inicio, fin):
        """Escanear un rango específico de IPs"""
        print(f"\n🔍 Escaneando rango {inicio} a {fin}")
        resultados = []
        
        inicio_parts = inicio.split('.')
        fin_parts = fin.split('.')
        
        if len(inicio_parts) == 4 and len(fin_parts) == 4:
            base = ".".join(inicio_parts[:3])
            inicio_ultimo = int(inicio_parts[3])
            fin_ultimo = int(fin_parts[3])
            
            for i in range(inicio_ultimo, fin_ultimo + 1):
                ip = f"{base}.{i}"
                if self.ping(ip):
                    nombre = self.obtener_nombre_dns(ip)
                    resultados.append({"ip": ip, "nombre": nombre or "Desconocido"})
                    print(f"✅ {ip} - {nombre or 'Desconocido'}")
        
        return resultados
    
    def guardar_historial(self, resultados):
        """Guarda el escaneo en el historial"""
        self.historial_escaneos.append({
            "timestamp": datetime.now().isoformat(),
            "total": len(resultados),
            "dispositivos": resultados
        })
        if len(self.historial_escaneos) > 10:
            self.historial_escaneos.pop(0)
    
    def obtener_historial(self):
        return self.historial_escaneos
    
    def comparar_escaneos(self, idx1=-1, idx2=-2):
        """Compara dos escaneos y muestra diferencias"""
        if len(self.historial_escaneos) < 2:
            return "No hay suficientes escaneos para comparar"
        
        escaneo1 = self.historial_escaneos[idx1]
        escaneo2 = self.historial_escaneos[idx2]
        
        ips1 = set([d['ip'] for d in escaneo1['dispositivos']])
        ips2 = set([d['ip'] for d in escaneo2['dispositivos']])
        
        nuevos = ips2 - ips1
        desaparecidos = ips1 - ips2
        
        resultado = f"\n📊 Comparación:\n"
        resultado += f"   Escaneo 1 ({escaneo1['timestamp']}): {len(ips1)} dispositivos\n"
        resultado += f"   Escaneo 2 ({escaneo2['timestamp']}): {len(ips2)} dispositivos\n"
        resultado += f"   🔵 Nuevos: {len(nuevos)} - {list(nuevos)[:10]}\n"
        resultado += f"   🔴 Desaparecidos: {len(desaparecidos)} - {list(desaparecidos)[:10]}"
        
        return resultado
    
    def filtrar_por_tipo(self, tipo):
        """Filtra dispositivos por tipo (Apple, Samsung, etc.)"""
        return [d for d in self.ultimos_resultados if tipo.lower() in d.get('fabricante', '').lower()]
    
    def filtrar_por_so(self, so):
        """Filtra por sistema operativo"""
        return [d for d in self.ultimos_resultados if so.lower() in d.get('sistema_operativo', '').lower()]
    
    def obtener_top_puertos(self):
        """Analiza los puertos más comunes en la red escaneada"""
        puertos_contar = {}
        for dispositivo in self.ultimos_resultados:
            for puerto in dispositivo.get('puertos', []):
                p = puerto['puerto']
                puertos_contar[p] = puertos_contar.get(p, 0) + 1
        
        top = sorted(puertos_contar.items(), key=lambda x: x[1], reverse=True)[:10]
        return [(puerto, self.puertos_servicios.get(puerto, "Desconocido"), count) for puerto, count in top]
    
    def monitorear_red(self, intervalo=30, duracion=None):
        """Monitorea la red continuamente"""
        print(f"\n🔍 Monitoreando red cada {intervalo} segundos...")
        start_time = time.time()
        historial_cambios = []
        
        ips_antes = set([d['ip'] for d in self.escanear_rapido()])
        
        while True:
            time.sleep(intervalo)
            if duracion and (time.time() - start_time) > duracion:
                break
            
            ips_ahora = set([d['ip'] for d in self.escanear_rapido()])
            
            nuevas = ips_ahora - ips_antes
            perdidas = ips_antes - ips_ahora
            
            if nuevas:
                print(f"\n🟢 Nuevos dispositivos: {list(nuevas)}")
                historial_cambios.append(("nuevo", nuevas, datetime.now()))
            
            if perdidas:
                print(f"\n🔴 Dispositivos perdidos: {list(perdidas)}")
                historial_cambios.append(("perdido", perdidas, datetime.now()))
            
            ips_antes = ips_ahora
        
        return historial_cambios
    
    def watch_ip(self, ip, intervalo=10, timeout=300):
        """Observa si una IP específica aparece o desaparece"""
        print(f"🔍 Observando {ip} cada {intervalo} segundos...")
        estado_actual = self.ping(ip)
        print(f"   Estado inicial: {'Activo' if estado_actual else 'Inactivo'}")
        
        start_time = time.time()
        while (time.time() - start_time) < timeout:
            time.sleep(intervalo)
            nuevo_estado = self.ping(ip)
            
            if nuevo_estado != estado_actual:
                print(f"\n{'🟢' if nuevo_estado else '🔴'} {ip} {'conectado' if nuevo_estado else 'desconectado'} a las {datetime.now().strftime('%H:%M:%S')}")
                estado_actual = nuevo_estado
    
    def tipo_red(self):
        """Determina si la IP es pública o privada"""
        ip = self.obtener_ip_local()
        ip_int = int(ipaddress.IPv4Address(ip))
        
        rangos_privados = [
            (int(ipaddress.IPv4Address("10.0.0.0")), int(ipaddress.IPv4Address("10.255.255.255"))),
            (int(ipaddress.IPv4Address("172.16.0.0")), int(ipaddress.IPv4Address("172.31.255.255"))),
            (int(ipaddress.IPv4Address("192.168.0.0")), int(ipaddress.IPv4Address("192.168.255.255")))
        ]
        
        for inicio, fin in rangos_privados:
            if inicio <= ip_int <= fin:
                return f"IP Privada (No rooteable)"
        
        return "IP Pública (Roteable en Internet)"