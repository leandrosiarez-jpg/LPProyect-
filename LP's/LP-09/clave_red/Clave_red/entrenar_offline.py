# entrenar_offline.py
# Entrena C.L.A.V.E. usando el método 2 (memoria + reentrenar_con_memoria)
# Ejecutar con: python entrenar_offline.py

from memoria import Memoria
from reglas import SistemaDecision

# ─────────────────────────────────────────────
#  DATASET DE ENTRENAMIENTO
#  Agregá o modificá estos ejemplos según tu red
# ─────────────────────────────────────────────

INTRUSOS = [
    {"ip": "10.0.0.50", "mac": None,          "fabricante": "Desconocido", "nombre": None,
     "puertos": [{"puerto": 23, "servicio": "telnet"}], "ttl": 50},

    {"ip": "10.0.0.51", "mac": None,          "fabricante": "Desconocido", "nombre": None,
     "puertos": [{"puerto": 445, "servicio": "smb"}, {"puerto": 3389, "servicio": "rdp"}], "ttl": 128},

    {"ip": "10.0.0.52", "mac": "ff:ff:ff:ff:ff:ff", "fabricante": "Desconocido", "nombre": None,
     "puertos": [{"puerto": 21}, {"puerto": 23}, {"puerto": 5900}], "ttl": 64},

    {"ip": "10.0.0.53", "mac": None,          "fabricante": "Desconocido", "nombre": None,
     "puertos": [{"puerto": 1433, "servicio": "mssql"}], "ttl": 128},

    {"ip": "10.0.0.54", "mac": "aa:bb:cc:00:00:01", "fabricante": "Desconocido", "nombre": None,
     "puertos": [{"puerto": p} for p in [21,22,23,25,80,443,445,3306,3389,5900]], "ttl": 55},
]

SEGUROS = [
    {"ip": "192.168.1.1",  "mac": "a1:b2:c3:d4:e5:f6", "fabricante": "TP-Link",  "nombre": "router",
     "puertos": [{"puerto": 80}, {"puerto": 443}], "ttl": 64},

    {"ip": "192.168.1.10", "mac": "aa:bb:cc:11:22:33", "fabricante": "Apple",    "nombre": "macbook-pro",
     "puertos": [{"puerto": 443}], "ttl": 128},

    {"ip": "192.168.1.11", "mac": "dd:ee:ff:44:55:66", "fabricante": "Samsung",  "nombre": "galaxy-s24",
     "puertos": [], "ttl": 128},

    {"ip": "192.168.1.20", "mac": "11:22:33:44:55:66", "fabricante": "Synology", "nombre": "nas-home",
     "puertos": [{"puerto": 80}, {"puerto": 443}, {"puerto": 5000}], "ttl": 128},

    {"ip": "192.168.1.30", "mac": "ab:cd:ef:12:34:56", "fabricante": "Roku",     "nombre": "roku-tv",
     "puertos": [{"puerto": 8080}], "ttl": 128},
]

# ─────────────────────────────────────────────
#  ENTRENAMIENTO
# ─────────────────────────────────────────────

def main():
    print("=" * 60)
    print("🧠 C.L.A.V.E. — Entrenamiento offline (Método 2)")
    print("=" * 60)

    memoria = Memoria()

    print(f"\n📥 Cargando {len(INTRUSOS)} intrusos y {len(SEGUROS)} dispositivos seguros...")

    for d in INTRUSOS:
        memoria.registrar_marcado_directo(d, "intruso")
        print(f"   ⚠️  Intruso registrado:  {d['ip']}")

    for d in SEGUROS:
        memoria.registrar_marcado_directo(d, "seguro")
        print(f"   ✅ Seguro  registrado:  {d['ip']}")

    ejemplos = memoria.obtener_ejemplos_entrenamiento()
    print(f"\n📊 Total de ejemplos en memoria: {len(ejemplos)}")

    print("\n🔁 Iniciando re-entrenamiento de la red profunda...")
    decision = SistemaDecision()
    decision.reentrenar_con_memoria(memoria)

    print("\n✅ Entrenamiento completado. Pesos guardados en datos/red_profunda_pesos.json")

    # Verificación rápida: probar con un intruso y un dispositivo seguro
    print("\n🧪 Verificación rápida:")
    pruebas = [
        (INTRUSOS[0], "intruso esperado"),
        (SEGUROS[0],  "seguro esperado"),
    ]
    for disp, etiqueta in pruebas:
        resultado = decision.evaluar(disp)
        print(f"   {resultado['etiqueta']}  {disp['ip']}  ({etiqueta})  score={resultado['score_final']:.2f}")

    memoria.cerrar_sesion()


if __name__ == "__main__":
    main()