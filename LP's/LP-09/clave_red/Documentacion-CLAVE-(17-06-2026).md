-Investigación y explicación de los tipos de neuronas que pueden integrarse en una "IA".
	*Perceptrón.
		-Clasificación binaria.
	*Neurona Sigmoide.
		-Probabilidad Continua.
	*Neurona ReLU.
		-Activación no Lineal.
	

-En este GitHub, CLAVE es un programa "IA" que tiene como posibilidad:

	*Escanear IPs.
		-escanear_red_completo() - Escaneo completo de red
		-escanear_rapido() - Solo ping para velocidad
		-escanear_rango() - Rango específico de IPs
		-escanear_todos_los_puertos() - Escaneo de 65535 puertos
	
	*Tener memoria.
		-guardar_escaneo() - Guarda todos los dispositivos detectados
		-dispositivos_nuevos() - Detecta dispositivos no vistos antes
		-buscar_dispositivo() - Historial de una IP específica
		-resumen_sesion_anterior() - Resumen de la última sesión
		-registrar_marcado() - Guarda cuando el usuario marca un dispositivo
		-estadisticas() - Métricas de uso de C.L.A.V.E.
		
	*Neuronas.
		-Perceptrón (Clasificación binaria (intruso/no intruso))
			.Usa regla delta para aprendizaje
			.Decide si un dispositivo es sospechoso
		-Sigmoide (Probabilidad de riesgo (0.0 a 1.0))
			.Regresión logística
			.Calcula qué tan riesgoso es un dispositivo
		-ReLU (Capa oculta que combina señales)
			.Red de 2 capas (4 neuronas ocultas)
			.Genera un "score" continuo
