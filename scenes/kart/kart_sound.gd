class_name KartSound
extends Node3D
## The noise one kart makes, GAME.md 8.4: the engine and the tires. Both are continuous voices
## driven by the motor every physics tick, so they belong to the kart rather than to the [Audio]
## autoload, which plays the one-shots that anybody in the room can hear.
##
## The engine is a single loop stretched across the whole range by a [KartRev] needle, not by
## road speed, so it revs against a slipping clutch as the kart pulls away and screams past the
## limiter on nitro. The tires are three squeals, one for each way of losing grip: a
## bright one for a drift, a duller one for sliding sideways with nobody asking, and that same
## one pitched well down for wheels locked under the brakes or the handbrake. All of it sits
## under the one-shots by [member KartSoundStats.kart_db]: the kart is running the whole time,
## so it is the bed the room is heard over rather than an event in it.
##
## Every kart carries one. A kart nobody here is driving gets a lean version of it: one engine
## and one squeal covering everything its tires do, no chirp, a few dB down and detuned a little
## off the recorded pitch so three of them behind you are three engines and not one loud one.

const AUDIO_DIR := "res://assets/audio/kart/"
const ENGINE_FILE := "engine_loop.ogg"
const SQUEAL_FILE := "tire_squeal.ogg"
const SCRUB_FILE := "tire_scrub.ogg"
## Every kart voice goes to its own bus under SFX, so one slider covers the lot, GAME.md 8.5.
## Below this much of a voice there is nothing left to hear, so the player is stopped.
const SILENT := 0.002
## How far off its own pitch each slot's engine sits, in steps of
## [member KartSoundStats.bot_detune], spread either side so nobody sits far from it.
const DETUNE_STEPS: Array[float] = [0.0, -1.0, 1.0, -2.0, 2.0, -3.0]

var stats: KartSoundStats
var rev: KartRev
## One engine and one squeal rather than the full set: everything but the kart being driven here.
var lean := false

var _kart: Kart
var _engine: AudioStreamPlayer3D
var _drift: AudioStreamPlayer3D
var _slide: AudioStreamPlayer3D
var _lock: AudioStreamPlayer3D
var _chirp: AudioStreamPlayer3D
var _drift_level := 0.0
var _slide_level := 0.0
var _lock_level := 0.0
## Fades the engine out when the kart dies or drops down a pit, and back in when it returns.
var _alive_fade := 1.0
var _spin_up := 0.0
var _chirp_wait := 0.0
var _silent := false
## This kart's own engine pitch, a little off the recorded one when it is not the one being
## driven here, and the level every one of its voices is shifted by.
var _detune := 1.0
var _trim := 0.0
## Controls read back off a puppet's movement, the speed they were read from last tick, and
## what the driver is doing this tick, worked out once and then read by every voice.
var _read := KartInput.new()
var _last_speed := 0.0
var _driver: KartInput


func setup(kart: Kart, sound_stats: KartSoundStats, is_lean: bool = false) -> void:
	_kart = kart
	_driver = kart.input
	stats = sound_stats
	lean = is_lean
	rev = KartRev.new(stats)
	if lean:
		_trim = stats.bot_db
		_detune = 1.0 + stats.bot_detune * DETUNE_STEPS[kart.slot % DETUNE_STEPS.size()]


func _ready() -> void:
	_silent = Game.is_headless()
	_engine = _build("Engine", ENGINE_FILE, true)
	_drift = _build("Drift", SCRUB_FILE if lean else SQUEAL_FILE, true)
	if not lean:
		_slide = _build("Slide", SCRUB_FILE, true)
		_lock = _build("Lock", SCRUB_FILE, true)
		_chirp = _build("Chirp", SQUEAL_FILE, false)
	if not _silent:
		_engine.volume_db = _quiet_db()
		_engine.play()


## Advances every voice. Called from the kart's physics tick, including while it is frozen on
## the grid, where the motor is standing still and the throttle revs the engine against it.
func step(delta: float) -> void:
	if _kart == null:
		return
	var driving := _kart.alive and not _kart.falling
	_alive_fade = move_toward(_alive_fade, 1.0 if driving else 0.0, stats.engine_fade * delta)
	_driver = _read_controls(delta)
	if driving:
		rev.step(_kart.motor, _driver, delta)
	_step_engine()
	_step_tires(delta, driving)
	_step_chirp(delta, driving)


## What the driver is doing. A puppet's controls never arrive over the wire, only where it
## ended up, so they are read back off its movement instead: speeding up or already going fast
## is the throttle, slowing down hard is the brake. It is an approximation, but without it a
## kart somebody else is driving would idle its way around the room.
func _read_controls(delta: float) -> KartInput:
	if not _kart.puppet:
		return _kart.input
	var motor := _kart.motor
	var speed := motor.speed()
	var change := (speed - _last_speed) / maxf(delta, 0.0001)
	_last_speed = speed
	var fraction := speed / maxf(motor.stats.top_speed, 0.001)
	var climbing := change / maxf(motor.stats.acceleration(), 0.001)
	_read.throttle = clampf(maxf(climbing, fraction), 0.0, 1.0)
	_read.brake = clampf(-change / maxf(motor.stats.brake_decel, 0.001), 0.0, 1.0)
	return _read


## One line for the debug overlay: where the needle is, what that does to the loop, and which
## tires are making a noise.
func debug_text() -> String:
	return (
		"rev %4.2f  pitch %4.2f  load %3.0f%%  drift %3.0f%% slide %3.0f%% lock %3.0f%%"
		% [
			rev.rev,
			rev.pitch(),
			rev.load * 100.0,
			_drift_level * 100.0,
			_slide_level * 100.0,
			_lock_level * 100.0,
		]
	)


func _step_engine() -> void:
	if _silent:
		return
	_engine.pitch_scale = rev.pitch() * _detune
	if _alive_fade <= SILENT:
		if _engine.playing:
			_engine.stop()
		return
	_engine.volume_db = (stats.kart_db + _trim + rev.volume_db() + linear_to_db(_alive_fade))
	if not _engine.playing:
		_engine.play()


func _step_tires(delta: float, driving: bool) -> void:
	var motor := _kart.motor
	var speed := motor.speed()
	var rolling := _ramp(speed, stats.roll_speed_min, stats.roll_speed_full) if driving else 0.0
	var slip := absf(motor.slip_angle())
	var drift := 0.0
	var slide := 0.0
	if motor.drifting:
		drift = clampf(slip / maxf(stats.drift_slip_full, 0.001), stats.drift_floor, 1.0)
	else:
		slide = _ramp(slip, stats.slide_slip_min, stats.slide_slip_full)
	if motor.spinning():
		# Spun out on oil: the tires are scrubbing sideways whatever the slip angle says.
		slide = 1.0
	var lock := 0.0
	if _driver.handbrake:
		lock = 1.0
	elif motor.forward_speed > 1.0:
		lock = _driver.brake * _ramp(speed, stats.lock_speed_min, stats.lock_speed_full)
	var fraction := minf(speed / maxf(motor.stats.top_speed, 0.001), stats.squeal_pitch_cap)
	if lean:
		# One squeal for whatever the tires are doing: at the distance a kart like this is
		# usually heard from, which of the three it is does not survive the trip anyway.
		_drift_level = _follow(_drift_level, maxf(maxf(drift, slide), lock) * rolling, delta)
		_voice(
			_drift,
			_drift_level,
			stats.bot_squeal_db,
			stats.slide_pitch,
			stats.slide_pitch_speed,
			fraction
		)
		return
	_drift_level = _follow(_drift_level, drift * rolling, delta)
	_slide_level = _follow(_slide_level, slide * rolling, delta)
	_lock_level = _follow(_lock_level, lock * rolling, delta)
	_voice(
		_drift, _drift_level, stats.drift_db, stats.drift_pitch, stats.drift_pitch_speed, fraction
	)
	_voice(
		_slide, _slide_level, stats.slide_db, stats.slide_pitch, stats.slide_pitch_speed, fraction
	)
	_voice(_lock, _lock_level, stats.lock_db, stats.lock_pitch, stats.lock_pitch_speed, fraction)


## A chirp of wheelspin the moment the throttle goes down at a standstill.
func _step_chirp(delta: float, driving: bool) -> void:
	if lean:
		return
	_chirp_wait = maxf(_chirp_wait - delta, 0.0)
	var speed := _kart.motor.speed()
	var room := 1.0 - _ramp(speed, stats.chirp_speed_min, stats.chirp_speed_full)
	var amount := (_driver.throttle * room) if driving else 0.0
	var crossed := _spin_up < stats.chirp_threshold and amount >= stats.chirp_threshold
	_spin_up = amount
	if not crossed or _chirp_wait > 0.0 or _silent:
		return
	_chirp_wait = stats.chirp_cooldown
	_chirp.volume_db = stats.kart_db + stats.chirp_db
	_chirp.pitch_scale = stats.chirp_pitch
	_chirp.play()


## Points one squeal at a level and a playback speed, starting and stopping it as it comes and
## goes so a silent voice costs nothing.
func _voice(
	player: AudioStreamPlayer3D,
	level: float,
	voice_db: float,
	base_pitch: float,
	pitch_speed: float,
	fraction: float
) -> void:
	if _silent:
		return
	if level <= SILENT:
		if player.playing:
			player.stop()
		return
	player.volume_db = stats.kart_db + _trim + voice_db + linear_to_db(level)
	player.pitch_scale = base_pitch + pitch_speed * fraction
	if not player.playing:
		player.play()


func _follow(value: float, target: float, delta: float) -> float:
	var rate := stats.squeal_attack if target > value else stats.squeal_release
	return value + (target - value) * (1.0 - exp(-rate * delta))


## 0 below [param from], 1 above [param to], straight between them.
static func _ramp(value: float, from: float, to: float) -> float:
	return clampf((value - from) / maxf(to - from, 0.001), 0.0, 1.0)


func _quiet_db() -> float:
	return stats.kart_db + _trim + stats.engine_db + stats.off_throttle_db


func _build(name: String, file: String, looping: bool) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = name
	player.stream = _stream(file, looping)
	player.bus = Buses.KART
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.unit_size = stats.unit_size
	# Godot adds volume_db to the distance attenuation and only then clamps to max_db, so a
	# ceiling at or under the written levels pins every voice to it and the whole resource
	# stops doing anything. It sits above them instead.
	player.max_db = stats.max_db
	player.panning_strength = stats.panning_strength
	# The engine is already pitched by the rev needle; a second helping from the engine's own
	# speed would fight it.
	player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	player.volume_db = -60.0
	add_child(player)
	return player


## The file, set to loop or not. Loading hands back one shared resource per file, and the loop
## flag lives on it, so a one-shot that shares a file with a loop gets its own copy.
static func _stream(file: String, looping: bool) -> AudioStream:
	var path := AUDIO_DIR + file
	if not ResourceLoader.exists(path):
		# The dedicated server build carries no sound at all, GAME.md 10.5, and says nothing of it.
		if not OS.has_feature("dedicated_server"):
			push_warning("missing kart sound %s" % path)
		return null
	var stream := load(path) as AudioStream
	if stream is AudioStreamOggVorbis:
		if not looping:
			stream = stream.duplicate() as AudioStream
		(stream as AudioStreamOggVorbis).loop = looping
	return stream
