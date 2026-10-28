extends Node
## SoundController (cliente): efectos sintetizados en código (AudioStreamWAV) con
## paneo/atenuación según la cámara.
## Todo el sonido es procedural:
## ruido + envolvente para disparos/explosiones y tonos para UI/bips.
##
## API: play(name, position = null, volume_db := 0.0, pitch := 1.0)
##      play_ui(name, volume_db := 0.0, pitch := 1.0)
##      set_loop(id, name, playing, position = null)   (lanzallamas, estática)
##      music(name)   (loop simple sintetizado: "Battle", "Prep", "Menu"; "" = silencio)

const RATE := 22050
const MAX_VOICES := 28

## volumen base (lineal, como AudioData) y variación de tono
const SOUNDS := {
	"Rifle": [0.45, 0.08], "RifleShot": [0.7, 0.08], "Shotgun": [0.6, 0.08], "LMG": [0.4, 0.1],
	"Sniper": [0.75, 0.05], "Flame": [0.35, 0.15], "Explosion": [0.85, 0.08], "Hit": [0.5, 0.0],
	"Kill": [0.6, 0.0], "Headshot": [0.7, 0.0], "Squish": [0.5, 0.12], "Radio": [0.35, 0.0],
	"Squelch": [0.45, 0.05], "Reload": [0.45, 0.05], "Click": [0.5, 0.0], "BlockBreak": [0.55, 0.1],
	"BlockPlace": [0.6, 0.05], "Horn": [0.45, 0.0], "Victory": [0.5, 0.0], "Helicopter": [0.35, 0.0],
	"BoltBack": [0.6, 0.05], "BoltForward": [0.6, 0.05], "Heartbeat": [0.6, 0.0],
	"Artillery": [0.4, 0.1], "Ambience": [0.16, 0.0], "Bounce": [0.4, 0.15],
}

var _streams := {}
var _voices: Array = []
var _loops := {}
var _music_player: AudioStreamPlayer
var _music_name := ""
var _music_streams := {}
var _seed := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SOUNDS:
		_streams[n] = _synth(n)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -80.0
	add_child(_music_player)
	G.session_ended.connect(func():
		for id in _loops.keys():
			set_loop(id, "", false))


# --- API ------------------------------------------------------------------

## position: Vector2 px en el mundo (o null para sonido de interfaz sin paneo).
func play(sound_name: String, position = null, volume_db := 0.0, pitch := 1.0) -> void:
	var stream: AudioStreamWAV = _streams.get(sound_name)
	if stream == null:
		return
	var sfx := float(G.settings.get("sfx", 0.8))
	if sfx <= 0.0:
		return
	var def: Array = SOUNDS[sound_name]
	var vol: float = float(def[0]) * sfx
	if position is Vector2:
		vol *= _distance_factor(position)
	var v := _voice()
	if v == null:
		return
	v.stream = stream
	v.volume_db = linear_to_db(maxf(vol, 0.0001)) + volume_db
	v.pitch_scale = maxf(0.05, pitch * (1.0 + (randf() - 0.5) * float(def[1])))
	if position is Vector2:
		v.global_position = position
		v.panning_strength = 1.0
	else:
		v.global_position = _listener()
		v.panning_strength = 0.0
	v.play()


func play_ui(sound_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	play(sound_name, null, volume_db, pitch)


## Sonido en loop identificado por id (p. ej. el lanzallamas de cada personaje).
func set_loop(id: String, sound_name: String, playing: bool, position = null) -> void:
	var v: AudioStreamPlayer2D = _loops.get(id)
	if playing:
		var stream: AudioStreamWAV = _streams.get(sound_name)
		if stream == null:
			return
		if v == null:
			v = _make_voice()
			var looped := stream.duplicate() as AudioStreamWAV
			looped.loop_mode = AudioStreamWAV.LOOP_FORWARD
			looped.loop_begin = 0
			looped.loop_end = looped.data.size() / 2
			v.stream = looped
			v.play()
			_loops[id] = v
		var vol: float = float(SOUNDS[sound_name][0]) * float(G.settings.get("sfx", 0.8))
		if position is Vector2:
			v.global_position = position
			vol *= _distance_factor(position)
		v.volume_db = linear_to_db(maxf(vol, 0.0001))
	elif v != null:
		_loops.erase(id)
		v.stop()
		v.queue_free()


func music(music_name: String) -> void:
	if music_name == _music_name:
		return
	_music_name = music_name
	if music_name == "":
		_music_player.stop()
		return
	if not _music_streams.has(music_name):
		_music_streams[music_name] = _synth_music(music_name)
	_music_player.stream = _music_streams[music_name]
	_music_player.volume_db = -30.0
	_music_player.play()


func _process(dt: float) -> void:
	if _music_player.playing:
		var m := float(G.settings.get("music", 0.6))
		var target := linear_to_db(maxf(m * 0.25, 0.0001))
		_music_player.volume_db = move_toward(_music_player.volume_db, target, dt * 20.0)


# --- voces ----------------------------------------------------------------

func _make_voice() -> AudioStreamPlayer2D:
	var v := AudioStreamPlayer2D.new()
	v.attenuation = 0.0          # la atenuación se calcula a mano
	v.max_distance = 1000000.0
	add_child(v)
	return v


func _voice() -> AudioStreamPlayer2D:
	for v in _voices:
		if not v.playing:
			return v
	if _voices.size() < MAX_VOICES:
		var nv := _make_voice()
		_voices.append(nv)
		return nv
	return null


func _listener() -> Vector2:
	if G.camera and is_instance_valid(G.camera):
		return G.camera.get_screen_center_position()
	var vp := get_viewport()
	if vp:
		return vp.get_canvas_transform().affine_inverse() * (vp.get_visible_rect().size * 0.5)
	return Vector2.ZERO


## Volumen *= clamp(1 - (dx - 25) / 110, 0.12, 1), dx en studs.
func _distance_factor(pos: Vector2) -> float:
	var dx := absf(pos.x - _listener().x) / GC.STUD
	return clampf(1.0 - (dx - 25.0) / 110.0, 0.12, 1.0)


# --- síntesis -------------------------------------------------------------

func _rand() -> float:
	_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_seed) / float(0x7fffffff) * 2.0 - 1.0


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


## Ruido filtrado (pasabajos de un polo) con envolvente exponencial.
## tone_f: frecuencia de un golpe tonal (0 = ninguno), tone_drop: caída de tono.
func _noise_burst(dur: float, decay: float, lp: float, tone_f := 0.0, tone_amp := 0.0, tone_drop := 0.0, attack := 0.002) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t / attack) * exp(-t * decay)
		y += (_rand() - y) * lp
		var s := y
		if tone_f > 0.0:
			var f := tone_f * exp(-t * tone_drop)
			phase += TAU * f / RATE
			s += sin(phase) * tone_amp
		out[i] = s * env
	return out


func _tone(dur: float, f0: float, f1: float, decay: float, wave := "sine", attack := 0.004) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		phase += TAU * f / RATE
		var s := sin(phase)
		match wave:
			"square":
				s = 1.0 if s >= 0.0 else -1.0
				s *= 0.5
			"tri":
				s = 2.0 / PI * asin(sin(phase))
			"saw":
				s = fposmod(phase / TAU, 1.0) * 2.0 - 1.0
				s *= 0.6
		var env := minf(1.0, t / attack) * exp(-t * decay) * minf(1.0, (dur - t) * 60.0)
		out[i] = s * env
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array, offset_s := 0.0, gain := 1.0) -> PackedFloat32Array:
	var off := int(offset_s * RATE)
	var n := maxi(a.size(), off + b.size())
	var out := a.duplicate()
	out.resize(n)
	for i in b.size():
		out[off + i] += b[i] * gain
	return out


## Suma en el lugar (recorta lo que exceda el destino).
func _add_into(dst: PackedFloat32Array, src: PackedFloat32Array, offset_s: float, gain := 1.0) -> void:
	var off := int(offset_s * RATE)
	var n := mini(src.size(), dst.size() - off)
	for i in n:
		dst[off + i] += src[i] * gain


func _normalize(a: PackedFloat32Array, peak := 0.9) -> PackedFloat32Array:
	var m := 0.0001
	for s in a:
		m = maxf(m, absf(s))
	var k := peak / m
	for i in a.size():
		a[i] *= k
	return a


func _synth(n: String) -> AudioStreamWAV:
	_seed = n.hash() & 0x7fffff
	var s := PackedFloat32Array()
	match n:
		"Rifle", "RifleShot":
			s = _noise_burst(0.45, 11.0, 0.55, 140.0, 0.6, 6.0)
			s = _mix(s, _noise_burst(0.05, 60.0, 0.95), 0.0, 0.8)
		"Shotgun":
			s = _noise_burst(0.55, 8.0, 0.4, 90.0, 0.8, 4.0)
			s = _mix(s, _noise_burst(0.08, 40.0, 0.9), 0.0, 0.8)
		"LMG":
			s = _noise_burst(0.16, 26.0, 0.6, 180.0, 0.5, 10.0)
		"Sniper":
			s = _noise_burst(0.8, 6.5, 0.5, 110.0, 0.7, 3.0)
			s = _mix(s, _noise_burst(0.06, 50.0, 0.98), 0.0, 1.0)
		"Flame":
			s = _noise_burst(0.5, 0.5, 0.18, 0.0, 0.0, 0.0, 0.03)
			var n2 := s.size()
			for i in n2:  # fundido en los bordes para que el loop no haga click
				var t := float(i) / n2
				s[i] *= minf(1.0, minf(t, 1.0 - t) * 12.0)
		"Explosion", "Artillery":
			s = _noise_burst(1.4, 3.2, 0.12, 55.0, 0.9, 1.5, 0.004)
			s = _mix(s, _noise_burst(0.2, 18.0, 0.7), 0.0, 0.7)
		"Hit":
			s = _tone(0.07, 1500.0, 1300.0, 40.0, "square")
		"Kill":
			s = _tone(0.09, 880.0, 880.0, 20.0, "square")
			s = _mix(s, _tone(0.16, 1320.0, 1320.0, 14.0, "square"), 0.08)
		"Headshot":
			s = _tone(0.08, 1046.0, 1046.0, 16.0, "square")
			s = _mix(s, _tone(0.08, 1318.0, 1318.0, 16.0, "square"), 0.07)
			s = _mix(s, _tone(0.22, 1568.0, 1568.0, 9.0, "square"), 0.14)
		"Squish":
			s = _tone(0.22, 320.0, 90.0, 14.0, "sine")
			s = _mix(s, _noise_burst(0.15, 25.0, 0.25), 0.0, 0.6)
		"Radio":
			s = _noise_burst(0.6, 0.8, 0.8, 0.0, 0.0, 0.0, 0.02)
			for i in s.size():
				s[i] *= 0.4
		"Squelch":
			s = _noise_burst(0.18, 12.0, 0.9, 0.0, 0.0, 0.0, 0.003)
			s = _mix(s, _tone(0.12, 1800.0, 1200.0, 18.0, "square"), 0.0, 0.3)
		"Reload":
			s = _noise_burst(0.05, 70.0, 0.9, 2200.0, 0.3, 0.0)
			s = _mix(s, _noise_burst(0.06, 60.0, 0.85, 1500.0, 0.4, 0.0), 0.18)
			s = _mix(s, _noise_burst(0.08, 45.0, 0.7, 900.0, 0.4, 0.0), 0.36)
		"Click":
			s = _tone(0.035, 1800.0, 1400.0, 80.0, "tri", 0.001)
		"BlockBreak":
			s = _noise_burst(0.45, 9.0, 0.35, 220.0, 0.4, 5.0)
			s = _mix(s, _noise_burst(0.1, 30.0, 0.8), 0.06, 0.6)
			s = _mix(s, _noise_burst(0.1, 30.0, 0.8), 0.14, 0.4)
		"BlockPlace":
			s = _tone(0.12, 260.0, 160.0, 28.0, "sine", 0.001)
			s = _mix(s, _noise_burst(0.04, 80.0, 0.6), 0.0, 0.5)
		"Bounce":
			s = _tone(0.1, 420.0, 200.0, 30.0, "sine", 0.001)
		"BoltBack":
			s = _noise_burst(0.06, 60.0, 0.9, 1800.0, 0.35, 8.0)
			s = _mix(s, _noise_burst(0.05, 70.0, 0.7, 1100.0, 0.3, 0.0), 0.05)
		"BoltForward":
			s = _noise_burst(0.05, 70.0, 0.7, 1200.0, 0.3, 0.0)
			s = _mix(s, _noise_burst(0.06, 60.0, 0.95, 2400.0, 0.35, 6.0), 0.05)
		"Horn":
			s = _tone(0.9, 220.0, 220.0, 0.8, "saw", 0.05)
			s = _mix(s, _tone(0.9, 277.0, 277.0, 0.8, "saw", 0.05), 0.0, 0.7)
			s = _mix(s, _tone(0.9, 330.0, 330.0, 0.8, "saw", 0.05), 0.0, 0.6)
		"Victory":
			var notes := [523.0, 659.0, 784.0, 1046.0]
			s = PackedFloat32Array()
			for k in notes.size():
				s = _mix(s, _tone(0.5 if k == 3 else 0.18, notes[k], notes[k], 4.0, "square"), k * 0.15, 0.7)
		"Helicopter":
			s = PackedFloat32Array()
			for k in 8:
				s = _mix(s, _noise_burst(0.1, 25.0, 0.2, 70.0, 0.6, 0.0), k * 0.09)
		"Heartbeat":
			s = _tone(0.15, 70.0, 45.0, 16.0, "sine")
			s = _mix(s, _tone(0.15, 65.0, 40.0, 16.0, "sine"), 0.22, 0.8)
		"Ambience":
			s = _noise_burst(2.0, 0.0, 0.03, 0.0, 0.0, 0.0, 0.3)
		_:
			s = _tone(0.05, 1000.0, 1000.0, 30.0)
	return _to_wav(_normalize(s))


## Loop musical mínimo: bajo + bombo + caja, 4 compases.
func _synth_music(n: String) -> AudioStreamWAV:
	_seed = 77
	var bpm := 132.0 if n == "Battle" else (96.0 if n == "Prep" else 84.0)
	var beat := 60.0 / bpm
	var bars := 4
	var total := beat * 4.0 * bars
	var s := PackedFloat32Array()
	s.resize(int(total * RATE))
	var kick := _tone(0.25, 120.0, 45.0, 14.0, "sine", 0.002)
	var snare := _noise_burst(0.15, 22.0, 0.6)
	var roots := [110.0, 110.0, 98.0, 82.4] if n == "Battle" else [130.8, 110.0, 87.3, 98.0]
	for bar in bars:
		for b in 4:
			var t0 := (bar * 4 + b) * beat
			_add_into(s, kick, t0, 0.9)
			if b % 2 == 1:
				_add_into(s, snare, t0, 0.35)
			for h in 2:
				_add_into(s, _tone(beat * 0.45, roots[bar], roots[bar], 5.0, "tri", 0.01), t0 + h * beat * 0.5, 0.45)
			if n != "Battle" and b == 0:
				_add_into(s, _tone(beat * 1.8, roots[bar] * 3.0, roots[bar] * 3.0, 1.5, "sine", 0.05), t0, 0.15)
	var w := _to_wav(_normalize(s, 0.7))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = s.size()
	return w
