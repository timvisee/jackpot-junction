extends Node
## Sound and music, GAME.md 8.4. Autoloaded as `Audio`. Listens to gameplay events and plays
## short effects from a pooled set of players on the SFX bus. The music is one track in three
## intensities that stay in step: calm by default, tense once the match heats up, see
## [MatchIntensity], and the full mix from Last Call to the end. Switches crossfade over one
## second with the two players summing to a constant level, so nothing dips. The files are cut to
## the track's 88 s loop with the decay tail folded under the start, so they loop without a gap.
## Every file is logged in THIRD_PARTY.md.

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
## Intensity at which the music steps up, and the lower mark it has to fall back through
## before it calms down again, so a value hovering around the line does not flap.
const TENSE_ON := 0.5
const TENSE_OFF := 0.3
## Nothing has refreshed the intensity for this long: no match is running, so wind down.
const INTENSITY_TIMEOUT := 0.5
## The music bus opens up as the match heats up: a low-pass filter sweeps from a dulled
## cutoff to fully open, and a little gain comes in with it.
const FILTER_CLOSED_HZ := 3800.0
const FILTER_OPEN_HZ := 20500.0
const HOT_GAIN_DB := 1.5
## How fast the filter follows the meter, per second, so it sweeps rather than snaps.
const OPEN_FOLLOW := 0.8
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
	&"explosion": ["impactPunch_heavy_000.ogg"],
	&"pad_claim": ["select_001.ogg"],
	&"oil": ["impactSoft_heavy_001.ogg"],
	&"wounded": ["impactPunch_heavy_000.ogg"],
	&"patched": ["confirmation_002.ogg"],
	&"explosion_tail": ["impactSoft_heavy_001.ogg"],
}

var music_enabled := true
## The intensity playing or fading in right now.
var current_layer := LAYER_CALM
## The match's excitement, 0 to 1, pushed in every tick by [MatchIntensity].
var intensity := 0.0

var _streams: Dictionary[String, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _active_player := 0
var _music_tween: Tween
var _intensity_age := 0.0
## The filter's own smoothed take on the intensity, 0 dulled and 1 wide open.
var _open := 0.0
var _filter: AudioEffectLowPassFilter
var _amplify: AudioEffectAmplify
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
	_build_music_effects()
	_connect_events()
	if not Game.is_headless():
		play_music()


## Puts a sweepable low-pass filter and a gain stage on the music bus. They sit after the bus
## volume, so the settings in 8.5 keep full control of how loud the music is.
func _build_music_effects() -> void:
	var bus := AudioServer.get_bus_index(BUS_MUSIC)
	if bus < 0:
		return
	_filter = AudioEffectLowPassFilter.new()
	_filter.cutoff_hz = FILTER_CLOSED_HZ
	AudioServer.add_bus_effect(bus, _filter)
	_amplify = AudioEffectAmplify.new()
	_amplify.volume_db = 0.0
	AudioServer.add_bus_effect(bus, _amplify)


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


## Sweeps the filter open and the gain up as the meter rises, and back down as it falls.
func _step_music_effects(delta: float) -> void:
	if _filter == null:
		return
	_open = move_toward(_open, intensity, OPEN_FOLLOW * delta)
	# Cutoff by ear rather than by number: an octave is a doubling, so sweep it that way.
	_filter.cutoff_hz = FILTER_CLOSED_HZ * pow(FILTER_OPEN_HZ / FILTER_CLOSED_HZ, _open)
	_amplify.volume_db = HOT_GAIN_DB * _open


func is_music_muted() -> bool:
	var music := AudioServer.get_bus_index("Music")
	return music >= 0 and AudioServer.is_bus_mute(music)


## One line for the debug overlay: the layer, both players' levels and positions, and the mute.
func music_debug() -> String:
	var parts: PackedStringArray = ["music %s %.2f" % [current_layer, intensity]]
	for i: int in _music_players.size():
		var player := _music_players[i]
		var file := "-"
		for layer: StringName in LAYER_FILES:
			if player.stream != null and player.stream.resource_path.ends_with(LAYER_FILES[layer]):
				file = layer
		var mark := "*" if i == _active_player else " "
		if player.playing:
			parts.append(
				(
					"%s%s %3.0f%% %5.1f s"
					% [mark, file, player.volume_linear * 100.0, player.get_playback_position()]
				)
			)
		else:
			parts.append("%s%s off" % [mark, file])
	parts.append("open %3.0f%%" % (_open * 100.0))
	if is_music_muted():
		parts.append("MUTED")
	elif not music_enabled:
		parts.append("disabled")
	return "  ".join(parts)


func _process(delta: float) -> void:
	_bank_tick_left = maxf(_bank_tick_left - delta, 0.0)
	_intensity_age += delta
	if _intensity_age > INTENSITY_TIMEOUT and intensity > 0.0:
		# The match is over or gone: let the music settle.
		set_intensity(maxf(intensity - delta, 0.0))
	_step_music_effects(delta)


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
	if not from.playing:
		# Nothing to fade out, in the menus or with the music off: hand the level straight over,
		# so the two players always sum to one whatever happened before.
		from.volume_linear = 0.0
	to.volume_linear = 0.0 if from.playing else 1.0
	if music_enabled and (from.playing or not Game.is_headless()):
		to.play(position)
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_LINEAR)
	_music_tween.tween_property(to, "volume_linear", 1.0, CROSSFADE_SECONDS)
	_music_tween.tween_property(from, "volume_linear", 0.0, CROSSFADE_SECONDS)
	_music_tween.chain().tween_callback(from.stop)


## The match's excitement, pushed in every tick. The music steps up past [constant TENSE_ON]
## and only calms down again below [constant TENSE_OFF]. Last Call outranks both.
func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.0)
	_intensity_age = 0.0
	if _last_call:
		return
	if intensity >= TENSE_ON:
		set_layer(LAYER_TENSE)
	elif intensity <= TENSE_OFF:
		set_layer(LAYER_CALM)


## Everyone who plays on this machine is dead: back to calm, whatever just happened.
func mark_all_players_down() -> void:
	intensity = 0.0
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
	Events.bomb_exploded.connect(func(_slot: int) -> void: _play_explosion())
	Events.pad_claimed.connect(func(_slot: int) -> void: play_sfx(&"pad_claim", -8.0, 0.05))
	Events.oil_hit.connect(func(_slot: int) -> void: play_sfx(&"oil", -4.0, 0.12))
	Events.flush_completed.connect(_on_flush_completed)
	Events.kart_wounded.connect(
		func(_victim: int, _by: int, _cause: StringName) -> void: play_sfx(&"wounded", -4.0, 0.1)
	)
	Events.life_restored.connect(func(_slot: int) -> void: play_sfx(&"patched", -6.0, 0.0))
	Events.match_state_changed.connect(_on_state_changed)


func _on_kart_killed(_victim: int, _killer: int, _cause: StringName) -> void:
	play_sfx(&"death")


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


func _on_flush_completed(_slot: int) -> void:
	play_sfx(&"fanfare", 0.0, 0.0)
	play_sfx(&"chips_scatter", -2.0)


## A bomb blast: a slowed-down punch for the boom and a soft thud for the rumble underneath.
func _play_explosion() -> void:
	for pair: Array in [[&"explosion", 0.55, 2.0], [&"explosion_tail", 0.7, -2.0]]:
		var files: Array = LIBRARY[pair[0]]
		var player := _free_player()
		player.stream = _stream(files[0])
		if player.stream == null:
			continue
		player.volume_db = pair[2]
		player.pitch_scale = pair[1]
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
			intensity = 0.0
			set_layer(LAYER_CALM)
