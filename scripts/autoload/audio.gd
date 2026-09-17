extends Node
## Sound and music, GAME.md 8.4. Autoloaded as `Audio`. Listens to gameplay events and plays
## short effects from a pooled set of players on the SFX bus. The music is one track in three
## intensities that stay in step: calm by default, tense once the match heats up, see
## [MatchIntensity], and the full mix from Last Call to the end. Switches crossfade over one
## second with the two players summing to a constant level, so nothing dips. The files are cut to
## the track's 88 s loop with the decay tail folded under the start, so they loop without a gap.
## Every file is logged in THIRD_PARTY.md.

const POOL_SIZE := 16
const AUDIO_DIR := "res://assets/audio/"
const SFX_DIR := AUDIO_DIR + "sfx/"
const MUSIC_DIR := "res://assets/audio/music/deceased_rodent/"
const LAYER_CALM := &"calm"
const LAYER_TENSE := &"tense"
const LAYER_PEAK := &"peak"
const LAYER_FILES: Dictionary[StringName, String] = {
	LAYER_CALM: "intensity_1.ogg", LAYER_TENSE: "intensity_2.ogg", LAYER_PEAK: "main.ogg"
}
const CROSSFADE_SECONDS := 1.0
## The excitement levels of GAME.md 8.4 at which the music steps up. Below the first the calm
## mix plays, from it the tense one, from the second the full one. The levels themselves hold
## for long enough that no extra hysteresis is needed here.
const TENSE_LEVEL := 4
const PEAK_LEVEL := 6
## Nothing has refreshed the excitement for this long: no match is running, so wind down.
const EXCITEMENT_TIMEOUT := 0.5
## The music bus opens up as the match heats up: a low-pass filter sweeps from a dulled
## cutoff to fully open, and the volume comes up with it. The early levels are meant to sit
## under the room rather than lead it, so they are both quieter and duller: a lap on a quiet
## table should sound like a bar with the music on, not like the music.
const FILTER_CLOSED_HZ := 1700.0
const FILTER_OPEN_HZ := 20500.0
## Decibels at level 1 and at the top, against the bus's own setting.
const COLD_GAIN_DB := -7.5
const HOT_GAIN_DB := 1.5
## How fast the filter follows the meter, per second, so it sweeps rather than snaps.
const OPEN_FOLLOW := 0.8
const BANK_TICK_INTERVAL := 0.07
## The least time between two cash-out chimes for one player.
const BANK_CHIME_GAP := 1.6
## The track's tempo. It is a steady four to the bar, so the beat can be read straight off
## the playback position rather than analysed.
const MUSIC_BPM := 120.0
const BEATS_PER_BAR := 4

## The swell that leads into a nitro burn runs backwards into its own hit, so it is played
## from this far before the end rather than from the start. Longer lands later and bigger.
const NITRO_SWELL_LEAD := 0.18
## A kart into a wall, GAME.md 8.4: the level and the playback speed run between these with how
## hard it was hit, so clipping a wall is a knock and only a real shunt is a bang. The heavy
## layer is only added above that much force.
const CRASH_LIGHT_DB := -24.0
const CRASH_HARD_DB := -8.0
const CRASH_HEAVY_DB := -12.0
const CRASH_HEAVY_FORCE := 0.55
const CRASH_LIGHT_PITCH := 1.3
const CRASH_HARD_PITCH := 0.9

## Effect name to the files it picks from at random. A name with a slash is under
## [constant AUDIO_DIR], anything else under [constant SFX_DIR].
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
	&"bump": ["kart/crash_1.ogg", "kart/crash_2.ogg"],
	&"crash": ["kart/crash_1.ogg", "kart/crash_2.ogg", "kart/crash_3.ogg"],
	&"crash_hard": ["kart/crash_heavy.ogg"],
	&"death": ["impactGlass_heavy_000.ogg", "impactGlass_heavy_001.ogg"],
	&"fall": ["back_001.ogg"],
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
	&"countdown": ["kart/start_tone_low.ogg"],
	&"go": ["kart/start_tone_high.ogg"],
	&"last_call": ["error_001.ogg"],
	&"results": ["bong_001.ogg", "chips-handle-1.ogg"],
	&"ui_click": ["click_001.ogg"],
	&"ui_move": ["tick_001.ogg"],
	&"ui_back": ["back_001.ogg"],
	&"shield_pop": ["impactBell_heavy_000.ogg"],
	&"turret_place": ["impactSoft_heavy_000.ogg"],
	&"explosion": ["impactPunch_heavy_000.ogg"],
	&"pad_claim": ["select_001.ogg"],
	&"oil": ["kart/spin_out.ogg"],
	&"bounty": ["question_001.ogg"],
	&"target": ["select_002.ogg"],
	&"wounded": ["impactPunch_heavy_000.ogg"],
	&"patched": ["confirmation_002.ogg"],
	&"explosion_tail": ["impactSoft_heavy_001.ogg"],
	&"turbo_pass": ["kart/turbo_pass.ogg"],
	&"nitro_swell": ["kart/nitro_swell.ogg"],
}

var music_enabled := true
## The intensity playing or fading in right now.
var current_layer := LAYER_CALM
## The match's excitement level, 1 to 6, pushed in every tick by [MatchIntensity].
var excitement := 1
## How far through the levels that is, 0 at level 1 and 1 at the top. The filter sweep and the
## gain follow it, so the mix keeps opening between the steps where the track itself changes.
var excitement_share := 0.0

var _streams: Dictionary[String, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _active_player := 0
var _music_tween: Tween
var _excitement_age := 0.0
## The filter's own smoothed take on the excitement, 0 dulled and 1 wide open.
var _open := 0.0
var _filter: AudioEffectLowPassFilter
var _amplify: AudioEffectAmplify
## The file each effect played last, so an effect with several never plays the same one twice
## running. Hearing one sound over and over is what makes a repeated effect wearing.
var _last_pick: Dictionary[StringName, int] = {}
var _bank_tick_left := 0.0
## When each slot last finished a cash-out, so a run of them is not a run of chimes.
var _banked_at: Dictionary[int, float] = {}
var _bank_pitch := 1.0
## The physics frame the last chip clink played on, so coins that land together are one sound.
var _chip_frame := -1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = Buses.SFX
		add_child(player)
		_pool.append(player)
	for i: int in 2:
		var player := AudioStreamPlayer.new()
		player.bus = Buses.MUSIC
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
	var bus := AudioServer.get_bus_index(Buses.MUSIC)
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
	_open = move_toward(_open, excitement_share, OPEN_FOLLOW * delta)
	# Cutoff by ear rather than by number: an octave is a doubling, so sweep it that way.
	_filter.cutoff_hz = FILTER_CLOSED_HZ * pow(FILTER_OPEN_HZ / FILTER_CLOSED_HZ, _open)
	_amplify.volume_db = lerpf(COLD_GAIN_DB, HOT_GAIN_DB, _open)


func is_music_muted() -> bool:
	var music := AudioServer.get_bus_index(Buses.MUSIC)
	return music >= 0 and AudioServer.is_bus_mute(music)


## Where the music is within the current beat: 0 right on it, rising to 1 just before the next.
func music_beat() -> float:
	return fposmod(_beats(), 1.0)


## Which beat of the bar the music is on, 0 for the downbeat.
func music_beat_index() -> int:
	return posmod(floori(_beats()), BEATS_PER_BAR)


## Beats since the start of the track. With the music stopped, in the menus or headless, a
## free-running clock keeps time so anything dancing to it carries on.
func _beats() -> float:
	var player := _music_players[_active_player]
	var position := Time.get_ticks_msec() * 0.001
	if player.playing:
		position = player.get_playback_position() + AudioServer.get_time_since_last_mix()
	return position * MUSIC_BPM / 60.0


## One line for the debug overlay: the layer, both players' levels and positions, and the mute.
func music_debug() -> String:
	var parts: PackedStringArray = ["music %s L%d" % [current_layer, excitement]]
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
	_excitement_age += delta
	if _excitement_age > EXCITEMENT_TIMEOUT and excitement > 1:
		# The match is over or gone: let the music settle.
		set_excitement(1, 0.0)
	_step_music_effects(delta)


## Plays a one-shot effect by library name, with a little random pitch. [param pitch] shifts
## the whole effect: below 1 it plays slower and deeper, above 1 quicker and higher.
func play_sfx(
	name: StringName, volume_db: float = 0.0, pitch_variation: float = 0.06, pitch: float = 1.0
) -> void:
	if not LIBRARY.has(name):
		push_warning("unknown sound effect %s" % name)
		return
	var stream := _stream(_pick(name, LIBRARY[name]))
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch * (1.0 + _rng.randf_range(-pitch_variation, pitch_variation))
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


## The match's excitement level and how far through the levels it is, pushed in every tick.
## The music steps up at [constant TENSE_LEVEL] and again at [constant PEAK_LEVEL]; the filter
## and the gain sweep with the share in between. Last Call outranks all of it.
func set_excitement(level: int, share: float) -> void:
	excitement = clampi(level, 1, PEAK_LEVEL)
	excitement_share = clampf(share, 0.0, 1.0)
	_excitement_age = 0.0
	if excitement >= PEAK_LEVEL:
		set_layer(LAYER_PEAK)
	elif excitement >= TENSE_LEVEL:
		set_layer(LAYER_TENSE)
	else:
		set_layer(LAYER_CALM)


## Everyone who plays on this machine is dead: back to calm, whatever just happened.
func mark_all_players_down() -> void:
	excitement = 1
	excitement_share = 0.0
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
		var path := (AUDIO_DIR + file) if file.contains("/") else (SFX_DIR + file)
		_streams[file] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _streams[file]


## One of an effect's files, never the one it played last.
func _pick(name: StringName, files: Array) -> String:
	var last: int = _last_pick.get(name, -1)
	var index := _rng.randi_range(0, files.size() - 1)
	if last >= 0 and files.size() > 1:
		index = _rng.randi_range(0, files.size() - 2)
		if index >= last:
			index += 1
	_last_pick[name] = index
	return files[index]


func _free_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _pool:
		if not player.playing:
			return player
	return _pool[_rng.randi_range(0, _pool.size() - 1)]


## Coins landing in the same instant are one sound. The four Royal Flush pads pay on the same
## beat, GAME.md 3.9, and four clinks stacked on one frame is a rattle rather than four coins.
func _on_coin_collected(_slot: int, coins: int) -> void:
	var frame := Engine.get_physics_frames()
	if frame == _chip_frame:
		return
	_chip_frame = frame
	play_sfx(&"gold_chip" if coins >= 5 else &"chip", -6.0)


func _connect_events() -> void:
	Events.coin_collected.connect(_on_coin_collected)
	Events.mult_gained.connect(_on_mult_gained)
	Events.grazed.connect(func(_slot: int) -> void: play_sfx(&"graze", -4.0))
	Events.kart_killed.connect(_on_kart_killed)
	# Dropping away, pitched well down so it reads as going somewhere rather than arriving.
	# What it lands on is the death sound, which follows on its own when the fall runs out.
	Events.kart_fell.connect(func(_slot: int) -> void: play_sfx(&"fall", -2.0, 0.05, 0.55))
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
	Events.kart_bumped.connect(func(_slot: int) -> void: play_sfx(&"bump", -10.8))
	Events.turbo_taken.connect(_on_turbo_taken)
	# The same chime nitro and a turbo pad get, a little brighter so a drift boost is its own
	# receipt rather than sounding like the bottle went off. No swell: that is nitro's alone.
	Events.drift_boosted.connect(func(_slot: int) -> void: play_sfx(&"turbo", -12.0, 0.1, 1.15))
	Events.nitro_started.connect(_on_nitro_started)
	Events.kart_crashed.connect(_on_kart_crashed)
	Events.countdown_tick.connect(func(_count: int) -> void: play_sfx(&"countdown", -11.0, 0.0))
	Events.countdown_done.connect(func() -> void: play_sfx(&"go", -5.0, 0.0))
	Events.crate_destroyed.connect(func() -> void: play_sfx(&"crate", -6.0))
	Events.target_struck.connect(
		func(_slot: int, _coins: int) -> void: play_sfx(&"target", -4.0, 0.12)
	)
	Events.shield_popped.connect(func(_slot: int) -> void: play_sfx(&"shield_pop", -6.0))
	Events.bomb_exploded.connect(func(_slot: int) -> void: _play_explosion())
	Events.pad_claimed.connect(func(_slot: int) -> void: play_sfx(&"pad_claim", -8.0, 0.05))
	Events.oil_hit.connect(func(_slot: int) -> void: play_sfx(&"oil", -2.5, 0.12))
	Events.bounty_called.connect(func(_slot: int) -> void: play_sfx(&"bounty", -2.0, 0.0))
	Events.bounty_claimed.connect(_on_bounty_claimed)
	Events.flush_completed.connect(_on_flush_completed)
	Events.kart_wounded.connect(
		func(_victim: int, _by: int, _cause: StringName) -> void: play_sfx(&"wounded", -4.0, 0.1)
	)
	Events.life_restored.connect(func(_slot: int) -> void: play_sfx(&"patched", -6.0, 0.0))
	Events.match_state_changed.connect(_on_state_changed)


func _on_kart_killed(_victim: int, _killer: int, _cause: StringName) -> void:
	play_sfx(&"death")


## A turbo pad: the chime that says a power-up landed, and a kart rushing past underneath it.
func _on_turbo_taken(_slot: int) -> void:
	play_sfx(&"turbo", -6.0)
	play_sfx(&"turbo_pass", -4.9, 0.05, 0.7)


## Nitro: a quiet chime for the cue, and the swell that runs backwards into its own kick.
func _on_nitro_started(_slot: int) -> void:
	play_sfx(&"turbo", -12.0, 0.1)
	var stream := _stream(LIBRARY[&"nitro_swell"][0])
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = -6.6
	player.pitch_scale = 1.0
	player.play(maxf(stream.get_length() - NITRO_SWELL_LEAD, 0.0))


## A kart into a wall. [param force] is 0 for the lightest contact worth hearing and 1 for a
## flat-out shunt. Walls are clipped constantly in an arena this size, so the level and the
## weight follow it rather than the same bang landing every time.
func _on_kart_crashed(_slot: int, force: float) -> void:
	var shaped := clampf(force, 0.0, 1.0)
	play_sfx(
		&"crash",
		lerpf(CRASH_LIGHT_DB, CRASH_HARD_DB, shaped),
		0.18,
		lerpf(CRASH_LIGHT_PITCH, CRASH_HARD_PITCH, shaped)
	)
	if shaped >= CRASH_HEAVY_FORCE:
		var over := (shaped - CRASH_HEAVY_FORCE) / (1.0 - CRASH_HEAVY_FORCE)
		play_sfx(&"crash_hard", lerpf(CRASH_LIGHT_DB, CRASH_HEAVY_DB, over), 0.1)


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


func _on_bounty_claimed(_killer: int, _victim: int, _amount: int) -> void:
	play_sfx(&"bank_done", 0.0, 0.0)
	play_sfx(&"fanfare", -2.0, 0.0)


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


## A run of tiny cash-outs, which is what a player parked on the Junction with the flush pads
## trickling makes, is one event and gets one sound: the chime is skipped while the last one
## is still ringing.
func _on_bank_completed(slot: int, _coins: int, _mult: float, total: int) -> void:
	var now := Time.get_ticks_msec() * 0.001
	var quiet: float = _banked_at.get(slot, -BANK_CHIME_GAP)
	if now - quiet >= BANK_CHIME_GAP:
		play_sfx(&"bank_done", 0.0, 0.0)
	_banked_at[slot] = now
	if total >= 500:
		play_sfx(&"fanfare", 0.0, 0.0)
		play_sfx(&"chips_scatter", -2.0)


func _on_state_changed(state: int) -> void:
	match state:
		Match.State.COUNTDOWN:
			# The start tones come from the clock, one per lamp, and the flag from the countdown
			# finishing. Neither is a sound the match makes on changing state, which is what lets
			# a room with no countdown, such as the Garage, have none of them at all.
			set_layer(LAYER_CALM)
		Match.State.LAST_CALL:
			# The mix is not switched here: the excitement climb of GAME.md 8.4 brings the full
			# track in as it walks the room up to the top level.
			play_sfx(&"last_call", -2.0, 0.0)
		Match.State.OVERTIME:
			# The same alarm as Last Call, further down: it is the same warning, only final.
			play_sfx(&"last_call", -1.0, 0.0, 0.78)
		Match.State.RESULTS:
			play_sfx(&"results", -2.0, 0.0)
			excitement = 1
			excitement_share = 0.0
			set_layer(LAYER_CALM)
