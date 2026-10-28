class_name MissionData
extends RefCounted
## Misiones por ronda y líneas del intercom de cada comandante
## (textos de cada comandante).
## Uso: MissionData.get_line("USA", "Welcome"), MissionData.get_mission("Radio").

## icon: sprite de Sprites (IcoTarget, IcoHill, IcoRadio, IcoFlag, IcoTnt)
const MISSIONS := {
	"Assassination": {
		"name": "ASESINATO",
		"short": "Eliminá al oficial enemigo y protegé al tuyo",
		"icon": "IcoTarget",
	},
	"KingOfHill": {
		"name": "REY DE LA COLINA",
		"short": "Controlá la colina del centro",
		"icon": "IcoHill",
	},
	"Radio": {
		"name": "INTERCEPCIÓN",
		"short": "Interceptá 3 señales de radio",
		"icon": "IcoRadio",
	},
	"CTF": {
		"name": "ROBO DE BANDERA",
		"short": "Robá la bandera enemiga y traela a tu base (2)",
		"icon": "IcoFlag",
	},
	"Demolition": {
		"name": "DEMOLICIÓN",
		"short": "Destruí el depósito enemigo",
		"icon": "IcoTnt",
	},
}

const LINES := {
	"USA": {
		"Welcome": [
			"Bienvenidos a la jungla, gomitas. Nadie sabe bien qué hacemos acá, pero el Pentágono dice que es importante.",
			"Atención, tropa. Les prometieron una guerra corta. Les mintieron. ¡A sus puestos!",
		],
		"Prep": [
			"Tienen un minuto. Levanten defensas y pasen por la intendencia.",
			"Un minuto para fortificar. Bloques arriba, munición en el bolsillo.",
		],
		"Briefing_Assassination": [
			"Inteligencia marcó a un oficial enemigo. Elimínenlo. Y cuiden al nuestro: también tiene precio su cabeza.",
		],
		"Briefing_KingOfHill": [
			"El alto mando quiere esa colina. Nadie sabe por qué. Tómenla y no la suelten.",
		],
		"Briefing_Radio": [
			"Captamos transmisiones enemigas. Lleguen a las antenas antes que ellos y escuchen todo.",
		],
		"Briefing_CTF": [
			"Roben su bandera y tráiganla a casa. Va a quedar linda en el despacho del general.",
		],
		"Briefing_Demolition": [
			"Su depósito de azúcar está en la base enemiga. Vuélenlo. Y cuiden el nuestro.",
		],
		"Start": ["¡Muévanse, muévanse, muévanse!", "¡A la carga, gomitas!", "¡Por la libertad! ...o lo que sea."],
		"OneMinute": ["¡Un minuto! ¡Ahora o nunca!", "Queda un minuto. Quiero resultados, no excusas."],
		"RoundWon": [
			"Buen trabajo. Mañana el diario dirá que fue una victoria aplastante.",
			"Ganamos la ronda. Que no se les suba el azúcar a la cabeza.",
		],
		"RoundLost": [
			"Perdimos. Oficialmente esto fue una 'retirada estratégica'.",
			"Eso fue un desastre. Reagrúpense.",
		],
		"RoundDraw": ["Nadie ganó. Como siempre en la guerra."],
		"MatchWon": ["Victoria. Que alguien me explique ahora para qué vinimos."],
		"MatchLost": ["Derrota. Que nadie le cuente a la prensa."],
		"FlagTaken": ["¡Tenemos su bandera! ¡Cubran al portador!"],
		"FlagStolen": ["¡Se llevan nuestra bandera! ¡Deténganlos!"],
		"FlagScored": ["¡Bandera capturada! Otra más y es nuestra."],
		"FlagConceded": ["Capturaron nuestra bandera... inaceptable."],
		"HillOurs": ["La colina es nuestra. ¡Aguanten!"],
		"HillTheirs": ["¡El enemigo tomó la colina! ¡Recupérenla!"],
		"RadioNew": ["Nueva señal detectada. ¡A la antena!"],
		"RadioOurs": ["Señal interceptada. Buen trabajo."],
		"RadioTheirs": ["Interceptaron una de sus señales. ¡Que no se repita!"],
		"VIPYou": ["Soldado, sos el objetivo. Que no te maten."],
		"VIPTeam": ["Tenemos un oficial marcado. Protéjanlo con su vida."],
		"DepotHit": ["¡Están atacando nuestro depósito!"],
		"DepotEnemyLow": ["¡Su depósito está por caer! ¡Terminen el trabajo!"],
	},
	"Vietnam": {
		"Welcome": [
			"Camaradas, los invasores de caramelo llegaron. Defendamos nuestra tierra... y nuestro azúcar.",
			"Ellos tienen helicópteros. Nosotros tenemos la jungla. Y la jungla no se rinde.",
		],
		"Prep": [
			"Un minuto para preparar la defensa. Cada bloque cuenta.",
			"Fortifiquen. Armen trampas. Abastézcanse.",
		],
		"Briefing_Assassination": [
			"El enemigo marcó a uno de los nuestros. Protéjanlo... y encuentren a su oficial.",
		],
		"Briefing_KingOfHill": [
			"Esa colina fue nuestra mil años. Que lo siga siendo.",
		],
		"Briefing_Radio": [
			"Los yanquis quieren espiar nuestras radios. Interceptemos primero sus señales.",
		],
		"Briefing_CTF": [
			"Su bandera, a nuestro cuartel. La nuestra, que no la toquen.",
		],
		"Briefing_Demolition": [
			"Destruyan el depósito invasor. Sin azúcar no hay guerra.",
		],
		"Start": ["¡Adelante, camaradas!", "¡Por nuestra tierra!", "¡Ahora! ¡Ataquen!"],
		"OneMinute": ["¡Un minuto, camaradas! ¡Todo o nada!"],
		"RoundWon": ["Ganamos esta batalla. La guerra... todavía no.", "Bien hecho. La jungla está con nosotros."],
		"RoundLost": ["Caímos. Reagrúpense, la jungla nos protege.", "Perdimos esta. No la próxima."],
		"RoundDraw": ["Empate. Nadie avanza, todos pierden."],
		"MatchWon": ["La tierra es nuestra. Que vuelvan a casa... los que quedan."],
		"MatchLost": ["Perdimos la batalla, no la memoria."],
		"FlagTaken": ["¡Tenemos su bandera! ¡Llévenla al cuartel!"],
		"FlagStolen": ["¡Robaron nuestra bandera! ¡Recupérenla!"],
		"FlagScored": ["¡Bandera capturada! ¡Una más!"],
		"FlagConceded": ["Se llevaron nuestra bandera. Vergüenza."],
		"HillOurs": ["Controlamos la colina. ¡Resistan!"],
		"HillTheirs": ["¡Los invasores están en la colina!"],
		"RadioNew": ["Señal nueva en el aire. ¡Corran a la antena!"],
		"RadioOurs": ["Señal capturada, camaradas."],
		"RadioTheirs": ["Escucharon nuestras transmisiones..."],
		"VIPYou": ["Camarada, sos el objetivo. Escondete y sobreviví."],
		"VIPTeam": ["Uno de los nuestros está marcado. Protéjanlo."],
		"DepotHit": ["¡El depósito está bajo ataque!"],
		"DepotEnemyLow": ["¡El depósito yanqui está por volar!"],
	},
}


## Devuelve una variante al azar, o "" si no existe la clave.
static func get_line(team: String, key: String) -> String:
	var by_team: Dictionary = LINES.get(team, {})
	var lines: Array = by_team.get(key, [])
	if lines.is_empty():
		return ""
	return lines[randi() % lines.size()]


static func get_mission(id: String) -> Dictionary:
	return MISSIONS.get(id, {})


static func mission_name(id: String) -> String:
	return MISSIONS.get(id, {}).get("name", "")
