extends Node
## =====================================================================
##  SYNTH - emulazione (semplificata) dell'audio TIA dell'Atari 2600
## ---------------------------------------------------------------------
##  Autoload "Synth". Genera il suono in tempo reale, senza file audio.
##  - note(audf)  = BAS: AUDF1 = valore : AUDV1 = 2   (musica)
##  - sfx(nome)   = BAS: callmacro sound V C F        (effetti)
##  Frequenza TIA "pure tone" (AUDC=4): f = 31400 / (2 * (AUDF+1))
## =====================================================================

const RATE := 22050.0
const TIA_CLOCK := 31400.0
## La musica del BAS suona un'ottava sotto per essere meno stridula
const MUSIC_OCTAVE_DIV := 2.0

var muted := false
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback

var _m_freq := 0.0
var _m_phase := 0.0
var _m_env := 0.0
var _m_vol := 0.16

var _voices: Array = []


class Voice:
	var f0 := 440.0
	var f1 := 440.0
	var dur := 0.1
	var t := 0.0
	var vol := 0.2
	var wave := 0  # 0 = quadra, 1 = rumore, 2 = triangolo
	var phase := 0.0
	var noise := 0.0


const PRESETS := {
	"sugar": [[880.0, 1760.0, 0.12, 0.20, 0], [1320.0, 2640.0, 0.10, 0.10, 2]],
	"golden": [[523.0, 2093.0, 0.45, 0.20, 2], [784.0, 1568.0, 0.35, 0.12, 0]],
	"key": [[660.0, 990.0, 0.18, 0.18, 0], [990.0, 1320.0, 0.25, 0.12, 2]],
	"shoot": [[620.0, 180.0, 0.10, 0.16, 0]],
	"jump": [[260.0, 620.0, 0.09, 0.10, 0]],
	"double": [[400.0, 1100.0, 0.13, 0.14, 2]],
	"land": [[0.0, 0.0, 0.05, 0.05, 1]],
	"break": [[0.0, 0.0, 0.14, 0.22, 1], [300.0, 120.0, 0.10, 0.08, 0]],
	"mouth": [[0.0, 0.0, 0.35, 0.30, 1], [240.0, 50.0, 0.32, 0.20, 0]],
	"hurt": [[420.0, 70.0, 0.45, 0.25, 0], [0.0, 0.0, 0.2, 0.15, 1]],
	"fall": [[720.0, 40.0, 0.7, 0.22, 0]],
	"lightoff": [[600.0, 90.0, 0.55, 0.20, 2]],
	"lighton": [[300.0, 1250.0, 0.28, 0.20, 2]],
	"bag": [[523.0, 1046.0, 0.40, 0.18, 0], [659.0, 1318.0, 0.50, 0.12, 2]],
	"level": [[392.0, 1568.0, 0.70, 0.20, 2], [523.0, 2093.0, 0.80, 0.12, 0]],
	"steam": [[0.0, 0.0, 0.30, 0.10, 1]],
	"splash": [[0.0, 0.0, 0.07, 0.07, 1]],
	"slow": [[300.0, 150.0, 0.25, 0.14, 2]],
	"knife": [[1800.0, 2400.0, 0.06, 0.08, 0]],
	"select": [[1000.0, 1000.0, 0.05, 0.14, 0]],
	"start": [[440.0, 1760.0, 0.35, 0.18, 0]],
	"gameover": [[330.0, 40.0, 1.3, 0.25, 0]],
	"victory": [[523.0, 2093.0, 1.2, 0.2, 2], [659.0, 2637.0, 1.2, 0.12, 0]],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.1
	_player.stream = gen
	_player.volume_db = -4.0
	# sul Web Godot 4.3 usa i "sample" di default, che non supportano il generatore
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


static func tia_freq(audf: int) -> float:
	return TIA_CLOCK / (2.0 * float(audf + 1))


## BAS: AUDF1 = tabella[_music_index] : AUDV1 = 2
func note(audf: int) -> void:
	_m_freq = tia_freq(audf) / MUSIC_OCTAVE_DIV
	_m_env = 1.0


func sfx(name: String) -> void:
	if not PRESETS.has(name):
		return
	for p in PRESETS[name]:
		var v := Voice.new()
		v.f0 = p[0]
		v.f1 = p[1]
		v.dur = p[2]
		v.vol = p[3]
		v.wave = p[4]
		_voices.append(v)
	while _voices.size() > 8:
		_voices.pop_front()


func toggle_mute() -> void:
	muted = not muted


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var n := _playback.get_frames_available()
	if n <= 0:
		return
	var buf := PackedVector2Array()
	buf.resize(n)
	var inv := 1.0 / RATE
	for i in n:
		var s := 0.0
		if _m_env > 0.002:
			_m_phase = fmod(_m_phase + _m_freq * inv, 1.0)
			s += (1.0 if _m_phase < 0.5 else -1.0) * _m_vol * 0.5 * _m_env
			s += (absf(_m_phase * 4.0 - 2.0) - 1.0) * _m_vol * 0.5 * _m_env
			_m_env *= 0.99972
		for v in _voices:
			if v.t >= v.dur:
				continue
			var k: float = v.t / v.dur
			var env := 1.0 - k
			var smp := 0.0
			if v.wave == 1:
				if int(v.t * 9000.0) != int((v.t - inv) * 9000.0):
					v.noise = randf() * 2.0 - 1.0
				smp = v.noise
			else:
				var f: float = lerpf(v.f0, v.f1, k)
				v.phase = fmod(v.phase + f * inv, 1.0)
				if v.wave == 0:
					smp = 1.0 if v.phase < 0.5 else -1.0
				else:
					smp = absf(v.phase * 4.0 - 2.0) - 1.0
			s += smp * v.vol * env
			v.t += inv
		if muted:
			s = 0.0
		s = clampf(s, -0.9, 0.9)
		buf[i] = Vector2(s, s)
	_playback.push_buffer(buf)
	var alive: Array = []
	for v in _voices:
		if v.t < v.dur:
			alive.append(v)
	_voices = alive
