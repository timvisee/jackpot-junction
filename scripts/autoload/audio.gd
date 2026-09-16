extends Node
## Sound and music, GAME.md 8.4. Autoloaded as `Audio`. Listens to gameplay events and plays
## short effects from a pooled set of players on the SFX bus. The music is one track in three
## intensities that stay in step: calm by default, tense for a while after a kill, and the full
## mix from Last Call to the end. Switches crossfade over one second with the two players
## summing to a constant level, so nothing dips. Every file is logged in THIRD_PARTY.md.

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const POOL_SIZE := 16
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/deceased_rodent/"
const LAYER_CALM := &"calm"
const LAYER_TENSE := &"tense"
const LAYER_PEAK := &"peak"
const LAYER_FILES: Dictionary[StringName, String] = {
	LAYER_CALM: "intensity_1.ogg", LAYER_TENSE: "intensity_2.ogg", LAYER_PEAK: "main.ogg"
}
const CROSSFADE_SECONDS := 1.0
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
## The intensity playing or fading in right now.
var current_layer := LAYER_CALM
## Seconds a kill keeps the music tense; another kill restarts the clock.
var tense_seconds := 12.0

var _streams: Dictionary[String, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _active_player := 0
var _music_tween: Tween
var _tense_left := 0.0
var _last_call := false
var _bank_tick_left := 0.0
var _bank_pitch := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_pool.append(player)
	for i: int in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_MUSIC
		player.volume_linear = 0.0
		add_child(player)
		_music_players.append(player)
	_connect_events()
	if not Game.is_headless():
		play_music()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.MUTE_MUSIC):
		toggle_music_mute()
		get_viewport().set_input_as_handled()


## Mutes or unmutes the music bus at once and remembers the choice.
func toggle_music_mute() -> void:
	Game.settings.music_muted = not Game.settings.music_muted
	Game.settings.apply_audio()
	Game.settings.save_to_disk()
	play_sfx(&"ui_click", -10.0, 0.0)


func is_music_muted() -> bool:
	var music := AudioServer.get_bus_index("Music")
	return music >= 0 and AudioServer.is_bus_mute(music)


func _process(delta: float) -> void:
	_bank_tick_left = maxf(_bank_tick_left - delta, 0.0)
	if _tense_left > 0.0:
		_tense_left -= delta
		if _tense_left <= 0.0 and not _last_call and current_layer == LAYER_TENSE:
			set_layer(LAYER_CALM)


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


## Starts the calm layer from the top, unless music is already playing.
func play_music() -> void:
	if not music_enabled or _music_players[_active_player].playing:
		return
	var player := _music_players[_active_player]
	player.stream = _music_stream(current_layer)
	player.volume_db = 0.0
	if player.stream != null:
		player.play()


func stop_music() -> void:
	for player: AudioStreamPlayer in _music_players:
		player.stop()


## Crossfades to another intensity of the same track, continuing from the same position. The
## fade is linear in amplitude: the layers are the same music, so their sum stays level.
func set_layer(layer: StringName) -> void:
	if layer == current_layer or not LAYER_FILES.has(layer):
		return
	current_layer = layer
	var from := _music_players[_active_player]
	var to := _music_players[1 - _active_player]
	_active_player = 1 - _active_player
	to.stream = _music_stream(layer)
	if to.stream == null:
		return
	var position := 0.0
	if from.playing:
		# Where the old player will be when the new one first mixes, so both stay in phase.
		position = (
			from.get_playback_position()
			+ AudioServer.get_time_since_last_mix()
			+ AudioServer.get_time_to_next_mix()
		)
		position = fmod(position, maxf(to.stream.get_length(), 0.001))
	to.volume_linear = 0.0 if from.playing else 1.0
	if music_enabled and (from.playing or not Game.is_headless()):
		to.play(position)
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_LINEAR)
	_music_tween.tween_property(to, "volume_linear", 1.0, CROSSFADE_SECONDS)
	_music_tween.tween_property(from, "volume_linear", 0.0, CROSSFADE_SECONDS)
	_music_tween.chain().tween_callback(from.stop)


## A kill makes the music tense for a while, unless Last Call already has the full mix playing.
func mark_excitement() -> void:
	_tense_left = tense_seconds
	if not _last_call:
		set_layer(LAYER_TENSE)


## Everyone who plays on this machine is dead: back to calm, even mid-excitement.
func mark_all_players_down() -> void:
	_tense_left = 0.0
	if not _last_call:
		set_layer(LAYER_CALM)


func _music_stream(layer: StringName) -> AudioStream:
	var path := MUSIC_DIR + LAYER_FILES[layer]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


## True when every human kart in the running match is dead.
func _all_humans_dead() -> bool:
	var match_node := get_tree().get_first_node_in_group(&"match") as Match
	if match_node == null:
		return false
	var humans := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			humans += 1
			if slot.kart != null and slot.kart.alive:
				return false
	return humans > 0


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
	Events.kart_killed.connect(_on_kart_killed)
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
	Events.nitro_started.connect(func(_slot: int) -> void: play_sfx(&"turbo", -8.0, 0.1))
	Events.crate_destroyed.connect(func() -> void: play_sfx(&"crate", -6.0))
	Events.shield_popped.connect(func(_slot: int) -> void: play_sfx(&"shield_pop", -6.0))
	Events.match_state_changed.connect(_on_state_changed)


func _on_kart_killed(_victim: int, killer: int, _cause: StringName) -> void:
	play_sfx(&"death")
	if _all_humans_dead():
		mark_all_players_down()
	elif killer >= 0:
		mark_excitement()


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
			_last_call = false
			set_layer(LAYER_CALM)
		Match.State.PLAYING:
			play_sfx(&"go", -2.0, 0.0)
		Match.State.LAST_CALL:
			play_sfx(&"last_call", -2.0, 0.0)
			_last_call = true
			set_layer(LAYER_PEAK)
		Match.State.RESULTS:
			play_sfx(&"results", -2.0, 0.0)
			_last_call = false
			_tense_left = 0.0
			set_layer(LAYER_CALM)
