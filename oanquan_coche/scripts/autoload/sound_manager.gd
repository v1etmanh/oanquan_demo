extends Node

# SoundManager — Autoload
# Phase 1: procedural audio via AudioStreamPlayer + pitch variation
# Phase 2+: load real .wav assets

const PITCH_VARIATIONS := [0.95, 1.0, 1.05, 1.10]
var _sfx_players: Array[AudioStreamPlayer] = []
var _pool_size := 8
var _pool_index := 0

var sound_volume: float = 1.0
var music_volume: float = 0.8

func _ready() -> void:
	for i in range(_pool_size):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

func play_stone_drop(stone_type: GameEnums.StoneType, cell_stone_count: int) -> void:
	# Pitch: more stones in cell = lower pitch (bồm vs cắc)
	var base_pitch := clampf(1.2 - cell_stone_count * 0.02, 0.8, 1.2)
	match stone_type:
		GameEnums.StoneType.GOLD:
			_play_tone(880.0, 0.15, base_pitch * 1.2)
		GameEnums.StoneType.DARK:
			_play_tone(120.0, 0.25, base_pitch * 0.6)
		_:
			var rand_pitch: float = PITCH_VARIATIONS[randi() % PITCH_VARIATIONS.size()]
			_play_tone(440.0, 0.08, base_pitch * rand_pitch)

func play_capture(stone_count: int) -> void:
	if stone_count >= 8:
		_play_tone(660.0, 0.3, 1.3)
	elif stone_count >= 4:
		_play_tone(550.0, 0.2, 1.1)
	else:
		_play_tone(495.0, 0.15, 1.0)

func play_trap_trigger() -> void:
	_play_tone(200.0, 0.4, 0.5)

func play_timer_tick() -> void:
	_play_tone(880.0, 0.05, 1.5)

func play_win() -> void:
	_play_tone(660.0, 0.5, 1.2)
	await get_tree().create_timer(0.15).timeout
	_play_tone(880.0, 0.5, 1.3)

func play_lose() -> void:
	_play_tone(330.0, 0.6, 0.8)

# Internal: generates a simple beep using AudioStreamGenerator
func _play_tone(freq: float, duration: float, pitch: float) -> void:
	var player := _sfx_players[_pool_index % _pool_size]
	_pool_index += 1

	var gen := AudioStreamGenerator.new()
	gen.mix_rate  = 44100.0
	gen.buffer_length = duration
	player.stream       = gen
	player.pitch_scale  = pitch * sound_volume
	player.volume_db    = linear_to_db(sound_volume)
	player.play()

	# Fill generator buffer with a simple sine wave
	await get_tree().process_frame
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var samples := int(44100.0 * duration)
	var frames_available := playback.get_frames_available()
	var to_fill := mini(samples, frames_available)
	for i in range(to_fill):
		var t := float(i) / 44100.0
		var envelope := 1.0 - (float(i) / float(to_fill))   # simple decay
		var sample := sin(TAU * freq * t) * envelope * 0.3
		playback.push_frame(Vector2(sample, sample))
