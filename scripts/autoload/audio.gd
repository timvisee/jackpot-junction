extends Node
## Sound and music, GAME.md 8.4. Autoloaded as `Audio`. Listens to gameplay events and plays
## short effects from a pooled set of players on the SFX bus; loops the music on the Music bus
## and speeds it up during Last Call. Every file is logged in THIRD_PARTY.md.

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const POOL_SIZE := 16
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/bossa_antigua.mp3"
const LAST_CALL_PITCH := 1.08
const BANK_TICK_INTERVAL := 0.07

## Effect name to the files it picks from at random.
const LIBRARY: Dictionary[StringName, Array] = {
	&"chip": ["chip-lay-1.ogg", "chip-lay-2.ogg", "chip-lay-3.ogg"],
	&"gold_chip": ["chips-stack-1.ogg", "chips-stack-2.ogg"],
	&"chips_scatter": ["chips-collide-1.ogg", "chips-collide-2.ogg"],
	&"die": ["dice-throw-1.ogg", "dice-throw-2.ogg", "dice-throw-3.ogg"],
	&"mult": ["pluck_001.ogg", "pluck_002.ogg"],
	&"graze": ["glass_001.ogg", "glass_002.ogg", "glass_003.ogg"],
	&"fire": ["drop_001.ogg", "drop_002.ogg"],
	&"bounce":
	["impactMetal_light_000.ogg", "impactMetal_light_001.ogg", "impactMetal_light_002.ogg"],
	&"bump": ["impactGeneric_light_000.ogg", "impactGeneric_light_001.ogg"],
	&"death": ["impactGlass_heavy_000.ogg", "impactGlass_heavy_001.ogg"],
	&"crate": ["impactPlate_light_000.ogg", "impactPlate_light_001.ogg"],
	&"turbo": ["maximize_001.ogg", "maximize_002.ogg"],
	&"bank_tick": ["tick_001.ogg", "tick_002.ogg"],
	&"bank_done": ["confirmation_002.ogg"],
	&"fanfare": ["bong_001.ogg", "confirmation_001.ogg"],
	&"death_bank": ["back_001.ogg"],
	&"jackpot_full": ["bong_001.ogg"],
	&"item_pick": ["open_001.ogg"],
	&"item_use": ["switch_001.ogg"],
	&"joker_offer": ["card-fan-1.ogg"],
	&"joker_take": ["card-place-1.ogg", "card-place-2.ogg"],
	&"joker_drop": ["card-shove-1.ogg"],
	&"countdown": ["click_002.ogg"],
	&"go": ["confirmation_001.ogg"],
	&"last_call": ["error_001.ogg"],
	&"results": ["bong_001.ogg", "chips-handle-1.ogg"],
	&"ui_click": ["click_001.ogg"],
	&"ui_move": ["tick_001.ogg"],
	&"ui_back": ["back_001.ogg"],
	&"shield_pop": ["impactBell_heavy_000.ogg"],
	&"turret_place": ["impactSoft_heavy_000.ogg"],
}

var music_enabled := true

var _streams: Dictionary[String, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _bank_tick_left := 0.0
var _bank_pitch := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_pool.append(player)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	add_child(_music)
	_connect_events()
	if not Game.is_headless():
		play_music()


func _process(delta: float) -> void:
	_bank_tick_left = maxf(_bank_tick_left - delta, 0.0)


## Plays a one-shot effect by library name, with a little random pitch.
func play_sfx(name: StringName, volume_db: float = 0.0, pitch_variation: float = 0.06) -> void:
	if not LIBRARY.has(name):
		push_warning("unknown sound effect %s" % name)
		return
	var files: Array = LIBRARY[name]
	var stream := _stream(files[_rng.randi_range(0, files.size() - 1)])
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	player.play()


func play_music() -> void:
	if not music_enabled or _music.playing:
		return
	var stream := load(MUSIC_PATH) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	_music.pitch_scale = 1.0
	_music.play()


func stop_music() -> void:
	_music.stop()


func set_music_urgent(urgent: bool) -> void:
	_music.pitch_scale = LAST_CALL_PITCH if urgent else 1.0


func _stream(file: String) -> AudioStream:
	if not _streams.has(file):
		var path := SFX_DIR + file
		_streams[file] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _streams[file]


func _free_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _pool:
		if not player.playing:
			return player
	return _pool[_rng.randi_range(0, _pool.size() - 1)]


func _connect_events() -> void:
	Events.coin_collected.connect(
		func(_slot: int, coins: int) -> void:
			play_sfx(&"gold_chip" if coins >= 5 else &"chip", -6.0)
	)
	Events.mult_gained.connect(_on_mult_gained)
	Events.grazed.connect(func(_slot: int) -> void: play_sfx(&"graze", -4.0))
	Events.kart_killed.connect(
		func(_victim: int, _killer: int, _cause: StringName) -> void: play_sfx(&"death")
	)
	Events.death_banked.connect(
		func(_slot: int, _amount: int) -> void: play_sfx(&"death_bank", -4.0)
	)
	Events.bank_tick.connect(_on_bank_tick)
	Events.bank_started.connect(func(_slot: int) -> void: _bank_pitch = 1.0)
	Events.bank_completed.connect(_on_bank_completed)
	Events.jackpot_full.connect(func(_zone: int) -> void: play_sfx(&"jackpot_full", -3.0))
	Events.item_picked.connect(
		func(_slot: int, _item: StringName) -> void: play_sfx(&"item_pick", -3.0)
	)
	Events.item_used.connect(
		func(_slot: int, _item: StringName) -> void: play_sfx(&"item_use", -3.0)
	)
	Events.joker_offered.connect(func(_slot: int) -> void: play_sfx(&"joker_offer", -3.0))
	Events.joker_taken.connect(
		func(_slot: int, _joker: StringName) -> void: play_sfx(&"joker_take", -3.0)
	)
	Events.bullet_fired.connect(func(_slot: int) -> void: play_sfx(&"fire", -10.0, 0.1))
	Events.bullet_bounced.connect(func() -> void: play_sfx(&"bounce", -12.0, 0.1))
	Events.kart_bumped.connect(func(_slot: int) -> void: play_sfx(&"bump", -8.0))
	Events.turbo_taken.connect(func(_slot: int) -> void: play_sfx(&"turbo", -6.0))
	Events.crate_destroyed.connect(func() -> void: play_sfx(&"crate", -6.0))
	Events.shield_popped.connect(func(_slot: int) -> void: play_sfx(&"shield_pop", -6.0))
	Events.match_state_changed.connect(_on_state_changed)


func _on_mult_gained(_slot: int, _amount: float, reason: StringName) -> void:
	if reason == &"graze":
		return
	play_sfx(&"die" if reason == &"die" else &"mult", -4.0)


func _on_bank_tick(_slot: int, _points: int) -> void:
	if _bank_tick_left > 0.0:
		return
	_bank_tick_left = BANK_TICK_INTERVAL
	_bank_pitch = minf(_bank_pitch + 0.03, 1.8)
	var player := _free_player()
	player.stream = _stream("tick_001.ogg")
	player.volume_db = -8.0
	player.pitch_scale = _bank_pitch
	player.play()


func _on_bank_completed(_slot: int, _coins: int, _mult: float, total: int) -> void:
	play_sfx(&"bank_done", 0.0, 0.0)
	if total >= 500:
		play_sfx(&"fanfare", 0.0, 0.0)
		play_sfx(&"chips_scatter", -2.0)


func _on_state_changed(state: int) -> void:
	match state:
		Match.State.COUNTDOWN:
			play_sfx(&"countdown", -4.0, 0.0)
		Match.State.PLAYING:
			play_sfx(&"go", -2.0, 0.0)
			set_music_urgent(false)
		Match.State.LAST_CALL:
			play_sfx(&"last_call", -2.0, 0.0)
			set_music_urgent(true)
		Match.State.RESULTS:
			play_sfx(&"results", -2.0, 0.0)
			set_music_urgent(false)
