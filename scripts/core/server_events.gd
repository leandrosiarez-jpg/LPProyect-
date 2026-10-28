extends Node
## Eventos internos del servidor (evitan dependencias circulares entre sistemas).

signal phase_changed(phase: String, round_number: int)
signal deployed(peer_id: int)
signal character_ready(character: Node, key: String)
## info: {victim_key, attacker_key, attacker_team, amount, weapon, headshot}
signal damaged(victim: Node, amount: float, info: Dictionary)
## info: {victim_key, victim_team, killer_key, killer_team, weapon, headshot, position}
signal killed(info: Dictionary)
## target: el nodo/celda dañado (Dictionary {kind:"block", cell:Vector2i} o el depósito)
signal structure_damaged(target, amount: float, attacker_team: String, attacker_key: String)
signal structure_destroyed(target, attacker_team: String, attacker_key: String)
