extends "res://scenes/dev/playground.gd"
## The store trailer's shots of play, docs/STEAM.md "The trailer": one shot a run, `++ --trailer=`
## and its name, on the playground's match and with any of its arguments, recorded by Godot's movie
## writer and cut together by tools/trailer. The shot is staged once the match is running; its
## action starts [member _lead] seconds later, and the run goes on [member _length] seconds past
## that and [member _tail] more, room for a transition into the next shot. Everything a shot does
## is timed from its action in seconds, which tools/trailer lays on the music's beats, half a
## second apart: negative before it, for what has to be under way when it starts.
##
## Captions are stamped over it at their times and turns, `++ --captions=0|Drift._Shoot.|-0.03`
## and more after semicolons, each until the next or the shot's end; a shot of the run of features,
## `++ --rack=` and its place in the run, racks them up, see scenes/dev/trailer_caption.gd. The
## match's own camera shows it, as a player sees it, but for the opening, which starts close on the
## Junction with the trailer's own camera and opens out into the match's, see
## scenes/dev/trailer_camera.gd.
##
## Shots: vault (a fat pot cashed out close up, opening out into the match, a rival knocked out),
## crossing (a spilled pot scooped up, then a race for the Junction a rival loses), jokers (the
## respawn pick), carousel (every kart drifting round the Junction in a ring, `++ --ring=` meters
## out), slot (three sevens, paid at `++ --pay-at=` seconds), bounty (the leader in its crown,
## `++ --bounty=1`, just ahead), volley (every kart in a ring opening fire with a shot power-up of
## its own), blasts (the karts round the hero blown up on the beat and the next, spilling chips),
## slip (the payout slip, `++ --results=1`, its podium's karts facing forward), podium (a Grand
## Prix's finale, `++ --finale=1`, without the standings over it), the run's shield, teams, slot,
## chase, ram, shock (a live cabinet), bomb, railgun and trade, each staged close round the Junction
## so the match's own camera frames it, and any other name for the table as the match plays it.
## `++ --stage=` stages a shot as another, so two shots can share one. With `++ --opaque=1` the
## HUD's panels stay whole over a kart rather than going see-through, see [HudCovers]: for a hand of
## jokers to be read.
##
## The match's clock reads `++ --clock=` seconds as the shot starts, so the trailer's shots read as
## one match going on rather than each a new one at five minutes. The music's beat clock, which the
## crowd, the lights and a finale's speakers keep time with, runs on the trailer's own music, its
## beats on the trailer's half seconds, `++ --at=` telling where in the trailer the shot starts.
## From `++ --drift=` on, the title's chips and cards drift over it, see
## scenes/dev/trailer_caption.gd.

const CAPTION := preload("res://scenes/dev/trailer_caption.gd")
const CAMERA := preload("res://scenes/dev/trailer_camera.gd")
const FPS := 60
## Watchers' reactions: how long before the shot they start, how often one floats up, and how many.
const REACT_FROM := 1.6
const REACT_EVERY := 0.24
const REACT_MOST := 8
## How much bigger than the game draws them, to read in a beat; and where each floats up from in
## turn, as shares of the frame across, from one side to the other and back, between the run's lists
## down either side rather than wherever the game's own chance puts them.
const REACT_SIZE := 2.0
const REACT_ACROSS: Array[float] = [0.32, 0.7, 0.48, 0.82, 0.38, 0.6, 0.27, 0.76]
## The trailer's music's beats a second: its 120 a minute, see tools/trailer.
const BEATS_A_SECOND := 2.0
## The shot power-ups every kart fires on the beat in the volley, each its own, in seat order.
const VOLLEY: Array[String] = [
	"spread_cannon", "flak_cannon", "grenade", "rocket", "ricochet_cannon", "sticky_bomb"
]
## Where the other karts wait while the opening's kart cashes out, from the Junction: round the
## table, clear of the lane it comes down.
const VAULT_ASIDE: Array[Vector3] = [
	Vector3(-8.0, 0.0, 5.0),
	Vector3(8.0, 0.0, 5.0),
	Vector3(-8.0, 0.0, -5.5),
	Vector3(8.0, 0.0, -5.5),
	Vector3(0.0, 0.0, 8.0),
	Vector3(-5.0, 0.0, 8.0),
	Vector3(5.0, 0.0, 8.0),
]
## How close the payout slip comes in and settles back from over its shot, how far it falls away
## into the dissolve to the podium at its end, starting how long before the cut and over how long,
## and how far it turns.
const SLIP_NEAR := 1.04
const SLIP_AWAY := 0.86
const SLIP_FALLS := Vector2(0.35, 0.6)
const SLIP_TURN := -0.012
## Every seat's banked chips by the trailer's second, so the sidebar never reads a row of zeroes:
## the leader's as the opening starts and how much it gains a second after, and each seat's share of
## it, the hero ahead.
const BANKED_FROM := 260.0
const BANKED_A_SECOND := 18.0
const BANKED_SHARES: Array[float] = [1.0, 0.83, 0.71, 0.58, 0.47, 0.38, 0.3, 0.24]
## The trailer's second the opening's take starts on, for [constant BANKED_FROM].
const OPENING_AT := 6.0
## How far out from the Junction the carousel's karts go round, in meters: inside the Vault's
## blocks with room to slide.
const RING := 4.8
## How every other kart is dressed, in seat order from the second, GAME.md 4.4: each its own fun
## hat, so no two karts on the payout slip or the Grand Prix's podium look alike, never a learner's
## L, a plain cap or none, nor the crown, which marks the bounty's carrier, and nothing of the
## supporter pack, 10.8; a paint, a flag and a trail of its own and the bodies mixed, a piece or two
## in a finish. [paint, hat, flag, trail, frame, marks, body, and the hat's and the paint's finish],
## by [constant KartStyle.CHOICES] and [constant Loyalty.FINISHES].
const DRESSES: Array[Array] = [
	["Flames", "Traffic cone", "Fuzzy dice", "Sparks", 0, 1, 1, 0, 0],
	["Checks", "Fez", "Ace of spades", "Poker chips", 1, 0, 2, 2, 0],
	["Spots", "Horns", "Windsock", "Afterburn", 0, 2, 3, 0, 0],
	["Card suits", "Shark fin", "Banner", "Pencil", 0, 3, 0, 0, 0],
	["Patchwork", "Party", "Pennant", "Confetti", 0, 0, 1, 1, 0],
	["Graph paper", "Welding goggles", "Tape measure", "Smoke", 0, 1, 2, 0, 1],
	["Stripes", "Paper hat", "Magnet", "Sparks", 1, 0, 3, 0, 0],
]

var _shot := ""
var _lead := 3.0
var _length := 2.0
var _tail := 0.5
var _frames := -1
var _cam: Camera3D
var _captions: Array[Array] = []
var _shown: CanvasLayer
var _done: Dictionary[String, bool] = {}
var _steer: Dictionary[int, Steer] = {}
var _rack := -1
var _pay_at := 0.5
var _stage := ""
var _ring := RING
var _clock := -1.0
var _drift := 0.0
var _at := 0.0
## Whether watchers' reactions float up the screen over the shot, `++ --emotes=1`.
var _emotes := false
## Whether the shot's clock runs from the start rather than from the match running: for the
## screens after a match, the payout slip and a Grand Prix's finale, `++ --now=1`.
var _now := false
var _opaque := false


## Steers a kart at a spot on the floor at full throttle and pulls it up there, for a shot that
## needs a kart to go somewhere on cue, as a bot's brain never does.
class Steer:
	extends KartInput
	## How far from the spot it starts to pull up, in meters.
	const STOPPING := 4.0
	var kart: Node3D
	var goal := Vector3.ZERO
	var speed := 1.0
	var turn := 2.2
	## Whether it fires, and burns nitro, as it goes; and a kart to chase rather than a spot.
	var shooting := false
	var boosting := false
	var chasing: Node3D

	func poll(_delta: float) -> void:
		if is_instance_valid(chasing):
			goal = chasing.global_position
		var way := goal - kart.global_position
		way.y = 0.0
		var nose := -kart.global_basis.z
		nose.y = 0.0
		var angle := nose.signed_angle_to(way, Vector3.UP) if way.length() > 0.05 else 0.0
		steer = clampf(-angle * turn, -1.0, 1.0)
		throttle = speed if way.length() > 0.8 else 0.0
		# Braked while faster than the room left lets it stop in, and let off once nearly still,
		# as a held brake backs a kart up.
		brake = 0.0
		var left := way.length()
		if left < STOPPING and chasing == null and not boosting:
			throttle = 0.0
			if (kart as Kart).motor.velocity.length() > maxf(left * 1.4, 0.8):
				brake = 1.0
		fire = shooting
		fire_pressed = shooting
		nitro = boosting


## Drives a kart round a ring about a spot, drifting, chasing a point a little ahead of it on the
## ring, so a field of karts goes round together like horses on a carousel. A kart slid out wide is
## aimed inside the ring by as much as it is out, and lets the slide go to grip again, so none
## drifts on into the furniture round it; and each keeps its share of the ring behind the kart
## ahead of it, easing off when it closes up and pushing on when it falls back, so they stay
## evenly spread rather than bunching.
class Orbit:
	extends KartInput
	## How far out past the ring a kart may slide before it lets the slide go.
	const WIDE := 0.5
	var kart: Node3D
	var middle := Vector3.ZERO
	var radius := 5.0
	var ahead := 0.7
	var speed := 1.0
	var turn := 2.6
	## The kart ahead round the ring, and the share of the ring to keep behind it, in radians.
	var ahead_of: Node3D
	var gap := TAU / 8.0

	func poll(_delta: float) -> void:
		var from := kart.global_position - middle
		from.y = 0.0
		var out := from.length() - radius
		var angle := atan2(from.z, from.x) + ahead
		var goal := middle + Vector3(cos(angle), 0.0, sin(angle)) * (radius - out * 1.2)
		var way := goal - kart.global_position
		way.y = 0.0
		var nose := -kart.global_basis.z
		nose.y = 0.0
		steer = clampf(-nose.signed_angle_to(way, Vector3.UP) * turn, -1.0, 1.0)
		var keep := 1.0
		if ahead_of != null:
			var there := ahead_of.global_position - middle
			var behind := fposmod(atan2(there.z, there.x) - atan2(from.z, from.x), TAU)
			keep = clampf(1.0 + (behind - gap) * 1.6, 0.35, 1.35)
		throttle = clampf(speed * keep * (1.0 if out < WIDE else 0.6), 0.0, 1.0)
		handbrake = absf(steer) > 0.35 and out < WIDE


func _ready() -> void:
	CAPTION.deafen(self)
	# What floats over the karts moves smoothly: a Control's place is otherwise held to whole
	# pixels, so one rising slowly stood still for a frame or two between pixels.
	get_viewport().gui_snap_controls_to_pixels = false
	_dress()
	super()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trailer="):
			_shot = arg.get_slice("=", 1)
		elif arg.begins_with("--lead="):
			_lead = float(arg.get_slice("=", 1))
		elif arg.begins_with("--length="):
			_length = float(arg.get_slice("=", 1))
		elif arg.begins_with("--tail="):
			_tail = float(arg.get_slice("=", 1))
		elif arg.begins_with("--captions="):
			for one: String in arg.get_slice("=", 1).split(";", false):
				var turn := float(one.get_slice("|", 2)) if one.get_slice_count("|") > 2 else -0.025
				_captions.append([float(one.get_slice("|", 0)), one.get_slice("|", 1), turn])
		elif arg.begins_with("--rack="):
			_rack = int(arg.get_slice("=", 1))
		elif arg.begins_with("--pay-at="):
			_pay_at = float(arg.get_slice("=", 1))
		elif arg == "--now=1":
			_now = true
		elif arg.begins_with("--stage="):
			_stage = arg.get_slice("=", 1)
		elif arg.begins_with("--ring="):
			_ring = float(arg.get_slice("=", 1))
		elif arg.begins_with("--clock="):
			_clock = float(arg.get_slice("=", 1))
		elif arg.begins_with("--drift="):
			_drift = float(arg.get_slice("=", 1))
		elif arg.begins_with("--at="):
			_at = float(arg.get_slice("=", 1))
		elif arg == "--emotes=1":
			_emotes = true
		elif arg == "--opaque=1":
			_opaque = true
	_cam = CAMERA.new()
	_cam.name = "TrailerCamera"
	add_child(_cam)
	# Ahead of everything that reads the beat clock, so all of it keeps this frame's beat.
	process_priority = -1000


func _process(delta: float) -> void:
	super(delta)
	if match_node != null and _once("no_notes", true):
		# Kit's notes left out of every shot: one driven over unfolds NOTE COLLECTED mid-screen.
		for dealer: Node in get_tree().get_nodes_in_group(NoteDealer.GROUP):
			dealer.queue_free()
	if match_node == null or not (_now or match_node.is_running()):
		return
	_frames += 1
	# Where the trailer's music is this frame, by the frames drawn rather than the clock on the wall,
	# which runs on ahead while a movie is written slower than it plays: told to the beat clock as
	# the seconds of the track playing that land on as many of the trailer's beats.
	var music_at := maxf(_at + float(_frames - roundi(_lead * FPS)) / FPS, 0.0)
	Engine.set_meta(&"music_at", music_at * BEATS_A_SECOND * 60.0 / Audio.bpm())
	var lead_frames := roundi(_lead * FPS)
	if _stage.is_empty():
		_stage = _shot
	if _frames == 0 and has_method("_stage_" + _stage):
		call("_stage_" + _stage)
	if _frames == 0 and not _now:
		_bank()
	if _frames == 0 and _clock >= 0.0:
		# Wound on as far as the shot's lead, so it reads its time as the shot starts.
		match_node.time_left = _clock + (0.0 if _now else _lead)
	if _frames == 0 and _drift > 0.0:
		CAPTION.drift(self, _at - _lead, match_node.hud.layer - 1)
	if _opaque:
		_keep_whole()
	if _frames == lead_frames:
		print("TRAILER_ACTION ", Engine.get_frames_drawn())
	var t := float(_frames - lead_frames) / FPS
	if has_method("_tick_" + _stage):
		call("_tick_" + _stage, t)
	if _emotes:
		_react(t)
	_caption_at(t)
	if _rack >= 0 and _once("rack", t >= 0.0):
		CAPTION.rack(self, _rack)
	if _frames - lead_frames >= roundi((_length + _tail) * FPS):
		get_tree().quit()


## Every seat's banked chips as the trailer's one match has them where the shot starts, see
## [constant BANKED_SHARES].
func _bank() -> void:
	var leader := BANKED_FROM + BANKED_A_SECOND * maxf(_at - OPENING_AT, 0.0)
	for slot: PlayerSlot in match_node.slots:
		var share: float = BANKED_SHARES[slot.index % BANKED_SHARES.size()]
		slot.banked = roundi(leader * share / 5.0) * 5


## The HUD's panels kept whole over a kart, see [HudCovers]: what it has made see-through already
## brought back, and it left with nothing more to do.
func _keep_whole() -> void:
	var covers := match_node.hud.get_node_or_null("Covers")
	if covers == null:
		return
	var shown: Dictionary = covers.get("_shown")
	for id: int in shown:
		var panel := instance_from_id(id) as Control
		if panel != null:
			HudCovers._show(panel, 1.0)
	covers.queue_free()
	_opaque = false


## The caption due at [param t] stamped down, the one before it faded away a moment before.
func _caption_at(t: float) -> void:
	for i: int in _captions.size():
		var at: float = _captions[i][0]
		var until: float = _captions[i + 1][0] if i + 1 < _captions.size() else _length
		# Started down a moment early inside a shot, so it lands on its beat.
		var down := at - CAPTION.STAMP if at > 0.0 else at
		if _once("caption%d" % i, t >= down):
			if _shown != null:
				_shown.queue_free()
			_shown = CAPTION.over(
				self, (_captions[i][1] as String).replace("_", " "), _captions[i][2]
			)
		if _once("caption_off%d" % i, t >= until - 0.22) and _shown != null:
			_shown.call("go")


## Whether [param due] has just come true for the first time under [param key]: for what a shot
## does once at its moment.
func _once(key: String, due: bool) -> bool:
	if not due or _done.has(key):
		return false
	_done[key] = true
	return true


## The hero's kart dressed and licensed as the README's is, so it wears a plate rather than a
## learner's L, and the drive hint every seat is shown on its first map taken as seen.
func _dress() -> void:
	var settings := Game.settings
	settings.tutorial_done = true
	settings.set_seat_name(0, "Tail Light Tim")
	settings.set_seat_color(0, 1)
	settings.set_seat_style(0, PackedInt32Array([5, 2, 3, 2, 0, 0, 0]))
	settings.license_holder = "Tail Light Tim"
	settings.license_number = "JJ-7714-0921"
	settings.license_date = LicenseCard.today()
	settings.license_plate = LicensePlate.clean("TIM 777")
	for seat: int in 4:
		ControlHint.shown_to[seat] = true


## Every bot's kart in its dress of [constant DRESSES] as the match starts, over the one its way of
## driving gave it as its kart was built, see [method Match._deal_bot], and its seat's, which the
## payout slip's photo and a Grand Prix's podium dress their karts in: before the playground stages
## either.
func _started() -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.index == 0:
			continue
		var was := slot.kart.style
		slot.style = _style_of(DRESSES[(slot.index - 1) % DRESSES.size()])
		slot.kart.style = slot.style
		KartVisuals.redress(slot.kart, was)


## The dress [param named] lists, see [constant DRESSES], as a kart's.
static func _style_of(named: Array) -> KartStyle:
	var style := KartStyle.new()
	style.paint = KartStyle.PAINTS.find(named[0])
	style.hat = KartStyle.HATS.find(named[1])
	style.flag = KartStyle.FLAGS.find(named[2])
	style.trail = KartStyle.TRAILS.find(named[3])
	style.frame = named[4]
	style.marks = named[5]
	style.body = named[6]
	style.finishes[1] = named[7]
	style.finishes[0] = named[8]
	return style


## Takes the wheel of [param kart] off whoever had it and points it at [param goal].
func _drive(kart: Kart, goal: Vector3, speed := 1.0) -> Steer:
	for brain: Node in kart.get_children():
		if brain is BotBrain:
			brain.queue_free()
	var steer := Steer.new()
	steer.kart = kart
	steer.goal = goal
	steer.speed = speed
	kart.input = steer
	_steer[kart.slot] = steer
	return steer


## Hands [param kart] back to a bot's brain, to play on as the match's bots do.
func _let_go(kart: Kart) -> void:
	kart.input = BotInput.new()
	var brain := BotBrain.new()
	brain.name = "Autopilot"
	var drives := match_node.bot_traits.pick(match_node.rng)
	brain.setup(kart, match_node, drives, match_node.bot_difficulty, match_node.rng)
	kart.add_child(brain)
	_steer.erase(kart.slot)


## Puts [param kart] at [param place] facing [param toward], still.
func _put(kart: Kart, place: Vector3, toward: Vector3) -> void:
	kart.global_position = Vector3(place.x, kart.global_position.y, place.z)
	kart.face(toward - place)
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO
	kart.reset_physics_interpolation()


## Holds every kart but [param kept] still where it is, or lets them all go again.
func _hold_others(kept: Kart, held := true) -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and slot.kart != kept:
			slot.kart.frozen = held


## Blows [param kart] up where it is, carrying [param chips] that spill, as a bomb does.
func _knock_out(kart: Kart, chips := 0, by := 0) -> void:
	if kart == null or not kart.alive:
		return
	if chips > 0:
		kart.pot.add_coins(chips)
	Explosion.spawn(match_node, kart.global_position, Bomb.RADIUS, Palette.player_color(by))
	kart.die(&"bomb", by)


## The alive kart nearest [param to] other than [param but].
func _nearest(to: Vector3, but: Kart) -> Kart:
	var best: Kart
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or kart == but or not kart.alive:
			continue
		var far := kart.global_position.distance_to(to)
		if best == null or far < best.global_position.distance_to(to):
			best = kart
	return best


func _junction() -> Vector3:
	return match_node.arena.junctions[0].global_position


## The opening, one take: a kart carrying a fat pot pulls up on the Junction as the music drops, its
## pot streaming into the tank, close and low; the camera rises into the match's own, the table
## plays on, and a rival carrying chips is knocked out near the kart on the beat.
func _stage_vault() -> void:
	var kart := match_node.kart_of(0)
	var pad := _junction()
	# Down the open lane from the top of the table onto the Junction's top half, toward the camera,
	# which looks up the table as the match's does, so rising into the match's turns it nowhere.
	# Aimed deeper than it is to stop: it pulls up a little short of its spot, well on the pad; in
	# from a little to the side, so it comes to rest turned rather than square on.
	var stop := pad + Vector3(0.6, 0.0, -0.6)
	_put(kart, pad + Vector3(-2.0, 0.0, -7.5), stop)
	kart.pot.add_coins(48)
	kart.pot.mult = 6.0
	kart.pot.changed.emit()
	# Cashed out quicker than a match does, so the count climbs within the shot.
	match_node.rules.bank_rate_base *= 2.5
	_drive(kart, stop, 0.0)
	# The rest put round the table, out of the lane, before they are held still in it.
	for i: int in range(1, match_node.slots.size()):
		var spot: Vector3 = VAULT_ASIDE[(i - 1) % VAULT_ASIDE.size()]
		_put(match_node.kart_of(i), pad + spot, pad)
	_hold_others(kart)
	var at := pad + Vector3(0.3, 0.3, -1.4)
	_cam.dolly(pad + Vector3(0.0, 3.2, 3.6), pad + Vector3(0.0, 2.8, 2.9), at, at, _lead + 1.5)


func _tick_vault(t: float) -> void:
	var kart := match_node.kart_of(0)
	# Set off so it rolls onto the pad as the shot starts, on the music's drop.
	if _once("go", t >= -0.95):
		_steer[kart.slot].speed = 1.0
	if _once("rise", t >= 1.5):
		_hold_others(kart, false)
		_cam.blend_to(match_node.camera_rig.camera, 2.0)
	if _once("drive_on", t >= 2.5):
		_let_go(kart)
	if _once("rival", t >= 5.5):
		var rival := _nearest(kart.global_position, kart)
		if rival != null:
			rival.pot.add_coins(30)
			set_meta("rival", rival)
	if _once("boom", t >= 6.0) and has_meta("rival"):
		_knock_out(get_meta("rival"), 0, 0)


## A rival's pot spilled ahead, scooped up; then the Junction calls and two karts race for it, the
## rival blown up short of it on the beat.
func _stage_crossing() -> void:
	var kart := match_node.kart_of(0)
	var pad := _junction()
	_put(kart, pad + Vector3(-13.0, 0.0, 6.0), pad + Vector3(-5.0, 0.0, 6.0))
	var victim := match_node.kart_of(1)
	_put(victim, pad + Vector3(-7.0, 0.0, 6.0), pad)
	var rival := match_node.kart_of(2)
	_put(rival, pad + Vector3(9.0, 0.0, -6.0), pad)
	kart.pot.add_coins(20)
	kart.pot.mult = 4.0
	rival.pot.add_coins(30)
	rival.pot.mult = 3.0
	_drive(kart, pad + Vector3(-5.0, 0.0, 6.0), 0.0)
	_drive(rival, pad, 0.0)
	_drive(victim, pad + Vector3(-7.0, 0.0, 9.0), 0.0)


func _tick_crossing(t: float) -> void:
	var kart := match_node.kart_of(0)
	if _once("spill", t >= -0.4):
		_knock_out(match_node.kart_of(1), 34, 3)
	if _once("go", t >= -0.3):
		_steer[kart.slot].speed = 0.8
	if _once("call", t >= 1.5):
		_steer[kart.slot].goal = _junction()
		_steer[kart.slot].speed = 1.0
		_steer[match_node.kart_of(2).slot].speed = 1.0
	if t >= 1.5:
		for pad: JunctionPad in match_node.arena.junctions:
			pad.hint = 1.0
	if _once("boom", t >= 3.0):
		_knock_out(match_node.kart_of(2), 0, 3)


## The respawn pick, `++ --offer=1`: the cursor walks to a joker and takes it on the beat.
func _tick_jokers(t: float) -> void:
	var slot := match_node.slots[0]
	if slot.offer == null:
		return
	if _once("right", t >= 0.5):
		slot.offer.selected = 2
	if _once("take", t >= 1.0):
		slot.offer.take(2)


## Two karts each at a slot machine of its own left and right of Lucky Crossing's Junction, as the
## match's camera sees them: the hero's on the right, clear of the run's list down the left, its
## reels set spinning so the last one stops on three sevens just before the beat and the room
## parties on it; the other's a moment before on three bells.
func _stage_slot() -> void:
	var pad := _junction()
	var pads := match_node.arena.find_children("*", "SlotPad", true, false)
	pads.sort_custom(
		func(a: Node3D, b: Node3D) -> bool:
			return a.global_position.distance_to(pad) < b.global_position.distance_to(pad)
	)
	var two := pads.slice(0, 2)
	two.sort_custom(
		func(a: Node3D, b: Node3D) -> bool: return a.global_position.x > b.global_position.x
	)
	for k: int in two.size():
		var machine: SlotPad = two[k]
		var kart := match_node.kart_of(k)
		var inward := ((pad - machine.global_position) * Vector3(1.0, 0.0, 1.0)).normalized()
		_put(kart, machine.global_position + inward * 1.4, machine.global_position)
		_drive(kart, machine.global_position + inward * 1.4, 0.0)
		set_meta("pad%d" % k, machine)
	_bystanders(2, [Vector3(-2.0, 0.0, -3.6), Vector3(2.0, 0.0, 3.6), Vector3(-2.2, 0.0, 3.6)])


func _tick_slot(t: float) -> void:
	var faces: Array[int] = [SlotPad.Face.SEVEN, SlotPad.Face.BELL]
	var early: Array[float] = [0.0, 0.2]
	for k: int in 2:
		if not has_meta("pad%d" % k):
			continue
		var machine: SlotPad = get_meta("pad%d" % k)
		var due := _pay_at - early[k] - SlotPad.STOPS[2] - SlotPad.SETTLE
		if _once("spin%d" % k, t >= due):
			Events.slot_spun.emit(
				k, machine.index, 20, PackedByteArray([faces[k], faces[k], faces[k]])
			)


## Every kart round the Junction in a ring, evenly spaced, drifting round together: set going a
## second before the shot so they are round at speed as it starts.
func _stage_carousel() -> void:
	var middle := _junction()
	var count := match_node.slots.size()
	for i: int in count:
		var kart := match_node.kart_of(i)
		var angle := TAU * i / count
		var at := middle + Vector3(cos(angle), 0.0, sin(angle)) * _ring
		var along := Vector3(-sin(angle), 0.0, cos(angle))
		_put(kart, at, at + along)
		for brain: Node in kart.get_children():
			if brain is BotBrain:
				brain.queue_free()
		var ring := Orbit.new()
		ring.kart = kart
		ring.middle = middle
		ring.radius = _ring
		ring.speed = 0.0
		ring.gap = TAU / count
		kart.input = ring
		set_meta("ring%d" % i, ring)
	for i: int in count:
		(get_meta("ring%d" % i) as Orbit).ahead_of = match_node.kart_of((i + 1) % count)
	# The hero carrying a pot past the Junction's full call, so its wheel turns as it does for a
	# player riding round with that much unbanked, see [method Match.junction_hint].
	match_node.kart_of(0).pot.add_coins(roundi(match_node.rules.junction_hint_full) + 100)


func _tick_carousel(t: float) -> void:
	if _once("go", t >= -1.8):
		for i: int in match_node.slots.size():
			(get_meta("ring%d" % i) as Orbit).speed = 0.72


## The kart with the bounty on it, `++ --bounty=1`, put just ahead of the hero, so the match's
## camera has its crown in the middle of the frame.
func _stage_bounty() -> void:
	var kart := match_node.kart_of(0)
	var leader := match_node.kart_of(1)
	var ahead := kart.global_position - kart.global_basis.z * 3.5 + kart.global_basis.x * 1.5
	_put(leader, ahead, ahead - kart.global_basis.z)


## The karts round the hero blown up, the nearest on the beat and the next two on the half-beat,
## each spilling a pot.
func _tick_blasts(t: float) -> void:
	var kart := match_node.kart_of(0)
	if _once("first", t >= 0.0):
		_knock_out(_nearest(kart.global_position, kart), 24, 0)
	if _once("second", t >= 0.25):
		_knock_out(_nearest(kart.global_position, kart), 18, 0)
		_knock_out(_nearest(kart.global_position, kart), 18, 0)


## The payout slip as a match ends, `++ --results=1`: the whistle's fireworks over the table, then
## the slip coming in over them, its podium's karts turning as they do, settling back a little and
## turning a little, then falling away from the viewer into the dissolve to the podium, which
## pushes in, [param t] seconds in.
func _tick_slip(t: float) -> void:
	var results: Control = match_node.hud.get("_results")
	if results == null or t < -1.0:
		return
	var along := clampf((t + 1.0) / (_length + _tail + 1.0), 0.0, 1.0)
	results.pivot_offset = results.size * 0.5
	var settled := lerpf(SLIP_NEAR, 1.0, smoothstep(0.0, 1.0, along))
	var falls := smoothstep(_length - SLIP_FALLS.x, _length - SLIP_FALLS.x + SLIP_FALLS.y, t)
	results.scale = Vector2.ONE * settled * lerpf(1.0, SLIP_AWAY, falls)
	results.rotation = lerpf(0.0, SLIP_TURN, smoothstep(0.0, 1.0, along))


## A Grand Prix's finale, `++ --finale=1`: its podium alone, the run's standings kept from coming up
## over it.
func _tick_podium(_t: float) -> void:
	var results: Control = match_node.hud.get("_results")
	if results != null:
		results.visible = false


## Every kart from the [param first] on put at the next of [param places], from the Junction,
## facing [param toward] from it, and held there: the karts a shot of the run has no part for kept
## in among it, so the match's camera, which frames every kart, frames the action close.
func _bystanders(first: int, places: Array[Vector3], toward := Vector3.ZERO) -> void:
	var pad := _junction()
	for k: int in range(first, match_node.slots.size()):
		var kart := match_node.kart_of(k)
		var at := pad + places[(k - first) % places.size()]
		_put(kart, at, pad + toward if (pad + toward).distance_to(at) > 0.1 else at + Vector3.BACK)
		kart.frozen = true


## The hero on Lucky Crossing's Junction, turned toward the camera, putting its shield power-up up
## on the beat as two rivals either side of it open fire, their shots still on their way as the
## beat ends: it is never hit, so never blinks for a life lost, as the match's camera sees it.
func _stage_shield() -> void:
	var pad := _junction()
	var hero := match_node.kart_of(0)
	var at := pad + Vector3(0.0, 0.0, 0.8)
	_put(hero, at, at + Vector3.BACK)
	_drive(hero, at, 0.0)
	for k: int in [1, 2]:
		var rival := match_node.kart_of(k)
		_put(rival, at + Vector3(-5.0 if k == 1 else 5.0, 0.0, 0.0), at)
		_drive(rival, at, 0.0)
	_bystanders(3, [Vector3(0.0, 0.0, -3.6)], Vector3(0.0, 0.0, 0.8))


func _tick_shield(t: float) -> void:
	var hero := match_node.kart_of(0)
	# Swelling up as the beat starts.
	if _once("shield", t >= -0.08):
		hero.hold_item(load("res://data/powerups/shield.tres"), 0.0)
		hero.item_reveal_left = 0.0
		hero.use_item()
	# Five meters off at seventeen a second, the first shots reach it past the beat's cut.
	if _once("fire", t >= 0.22):
		for k: int in [1, 2]:
			_steer[k].shooting = true


## The two teams facing off across Pin Alley's middle, Hearts on the left and Spades on the right,
## each side rolling up toward the other and opening fire on the beat, their shots still crossing
## the gap as it ends.
func _stage_teams() -> void:
	var pad := _junction()
	var spots: Array[Vector3] = [
		Vector3(-5.6, 0.0, -2.4), Vector3(-7.2, 0.0, 0.1), Vector3(-5.6, 0.0, 2.6)
	]
	var count: Array[int] = [0, 0]
	for slot: PlayerSlot in match_node.slots:
		if slot.kart == null:
			continue
		var side := 0 if slot.team <= 0 else 1
		var spot: Vector3 = spots[count[side] % spots.size()]
		count[side] += 1
		if side == 1:
			spot.x = -spot.x
		# Facing across, a little in toward the middle of the other side.
		var toward := pad + Vector3(-spot.x, 0.0, spot.z * 0.4)
		_put(slot.kart, pad + spot, toward)
		var ahead := pad + spot + (toward - pad - spot).normalized() * 1.6
		_drive(slot.kart, ahead, 0.0)


func _tick_teams(t: float) -> void:
	if _once("roll", t >= -0.6):
		for steer: Steer in _steer.values():
			steer.speed = 0.45
	if _once("fire", t >= 0.0):
		for steer: Steer in _steer.values():
			steer.shooting = true


## Three karts chasing each other across Toy Box's middle, each firing at the one ahead.
func _stage_chase() -> void:
	var lane := _junction() + Vector3(0.0, 0.0, -1.875)
	var order: Array[Kart] = [match_node.kart_of(1), match_node.kart_of(0), match_node.kart_of(2)]
	var steers: Array[Steer] = []
	for i: int in order.size():
		var kart := order[i]
		var at := lane + Vector3(-4.8 - 2.2 * i, 0.0, 0.0)
		_put(kart, at, at + Vector3.RIGHT)
		var steer := _drive(kart, lane + Vector3(30.0, 0.0, 0.0), 0.0)
		if i > 0:
			steer.chasing = order[i - 1]
		steers.append(steer)
	set_meta("chase", steers)
	_bystanders(3, [Vector3(0.0, 0.0, 1.6)], Vector3(0.0, 0.0, -1.875))


func _tick_chase(t: float) -> void:
	var steers: Array = get_meta("chase", [])
	if _once("go", t >= -0.8):
		for steer: Steer in steers:
			steer.speed = 1.0
	if _once("fire", t >= -0.3):
		for i: int in range(1, steers.size()):
			(steers[i] as Steer).shooting = true


## The hero, the bounty's crown on it, burning nitro down the Vault's middle through two karts side
## on to it: a kart on nitro rams whatever it reaches, see [method Kart.ram_kills].
func _stage_ram() -> void:
	var lane := _junction()
	var hero := match_node.kart_of(0)
	var from := lane + Vector3(-11.5, 0.0, 0.0)
	_put(hero, from, from + Vector3.RIGHT)
	for k: int in [1, 2]:
		var target := match_node.kart_of(k)
		var at := lane + Vector3(-4.6 + 1.8 * (k - 1), 0.0, 0.0)
		_put(target, at, at + Vector3.BACK)
		target.frozen = true
	var steer := _drive(hero, lane + Vector3(20.0, 0.0, 0.0), 0.0)
	steer.boosting = true
	set_meta("ram", steer)
	_bystanders(3, [Vector3(2.5, 0.0, -3.5)], Vector3(-3.0, 0.0, 0.0))


func _tick_ram(t: float) -> void:
	if _once("go", t >= -0.85):
		(get_meta("ram") as Steer).speed = 1.0
	if _once("thaw", t >= -0.3):
		for k: int in [1, 2]:
			match_node.kart_of(k).frozen = false


## A kart driven into one of the Yard's live cabinets as the beat starts and electrocuted against
## it, the others looking on round it so the match's camera frames it close, see [LiveCabinet].
func _stage_shock() -> void:
	if match_node.arena.cabinets.is_empty():
		return
	var cabinet: LiveCabinet = match_node.arena.cabinets[0]
	var at := cabinet.global_position
	var pad := _junction()
	var inward := ((pad - at) * Vector3(1.0, 0.0, 1.0)).normalized()
	var side := inward.cross(Vector3.UP)
	var victim := match_node.kart_of(1)
	_put(victim, at + inward * 4.6, at)
	_drive(victim, at, 0.0)
	var round_it: Array[Vector3] = [
		at + inward * 3.6 + side * 2.6, at + inward * 3.6 - side * 2.6, at + inward * 6.0
	]
	var k := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.kart == null or slot.kart == victim:
			continue
		var place: Vector3 = round_it[k % round_it.size()]
		_put(slot.kart, place, at)
		slot.kart.frozen = true
		k += 1
	set_meta("cabinet", cabinet)


func _tick_shock(t: float) -> void:
	if not has_meta("cabinet"):
		return
	var victim := match_node.kart_of(1)
	var cabinet: LiveCabinet = get_meta("cabinet")
	if _once("go", t >= -0.5):
		_steer[victim.slot].speed = 1.0
	# Caught as it reaches the cabinet, inside the beat, so the beat sees it drive in and go.
	var against := victim.global_position.distance_to(cabinet.global_position) < 1.25
	if victim.alive and t >= 0.12 and (against or t >= 0.3) and _once("zap", true):
		cabinet.shock(victim)


## A bomb going off on Lucky Crossing's Junction among three karts, each carrying a pot that
## spills, the hero looking on from clear of it: dropped a moment before the beat, blinking, and
## set off on it, before it arms, which a bomb among karts would do by itself
## [constant Bomb.ARM_TIME] after landing.
func _stage_bomb() -> void:
	var pad := _junction()
	var at := pad + Vector3(0.5, 0.0, 0.0)
	_put(match_node.kart_of(0), pad + Vector3(-4.5, 0.0, 0.0), at)
	for k: int in [1, 2, 3]:
		var near := match_node.kart_of(k)
		var angle := TAU * k / 3.0
		_put(near, at + Vector3(cos(angle), 0.0, sin(angle)) * 1.4, at)
		near.pot.add_coins(16)
	_bystanders(4, [Vector3(4.5, 0.0, 0.0)], Vector3(0.5, 0.0, 0.0))
	_hold_others(null)
	set_meta("bomb_at", at)


func _tick_bomb(t: float) -> void:
	if _once("drop", t >= -0.4) and has_meta("bomb_at"):
		var bomb := Bomb.new()
		bomb.color = Palette.player_color(0)
		match_node.add_child(bomb)
		bomb.global_position = get_meta("bomb_at")
		set_meta("bomb", bomb)
	if _once("boom", t >= 0.05) and has_meta("bomb"):
		var bomb: Object = get_meta("bomb")
		if is_instance_valid(bomb):
			(bomb as Bomb).explode()


## A railgun's bolt from the hero piercing a line of karts side on across Pin Alley's Junction,
## each on its last life, so the bolt takes them all.
func _stage_railgun() -> void:
	var lane := _junction() + Vector3(0.0, 0.0, 1.25)
	var hero := match_node.kart_of(0)
	var from := lane + Vector3(-7.5, 0.0, 0.0)
	_put(hero, from, from + Vector3.RIGHT)
	_drive(hero, from, 0.0)
	for k: int in range(1, match_node.slots.size()):
		var target := match_node.kart_of(k)
		var at := lane + Vector3(-3.6 + 2.0 * (k - 1), 0.0, 0.0)
		_put(target, at, at + (Vector3.BACK if k % 2 == 0 else Vector3.FORWARD))
		target.frozen = true
		target.lives = 1


func _tick_railgun(t: float) -> void:
	var hero := match_node.kart_of(0)
	if _once("arm", t >= -0.5):
		hero.hold_item(load("res://data/powerups/railgun.tres"), 0.0)
		hero.item_reveal_left = 0.0
		hero.use_item()
	if _once("fire", t >= 0.0):
		_steer[0].shooting = true
	if _once("hold", t >= 0.12):
		_steer[0].shooting = false


## Every kart in a ring round the Junction, facing out, opening fire on the beat, each with a shot
## power-up of its own, see [constant VOLLEY]: a burst of everything the game shoots.
func _stage_volley() -> void:
	var pad := _junction()
	var count := match_node.slots.size()
	for i: int in count:
		var kart := match_node.kart_of(i)
		var angle := TAU * i / count + 0.3
		var out := Vector3(cos(angle), 0.0, sin(angle))
		_put(kart, pad + out * 3.8, pad + out * 10.0)
		_drive(kart, pad + out * 3.8, 0.0)


func _tick_volley(t: float) -> void:
	if _once("arm", t >= -0.3):
		for slot: PlayerSlot in match_node.slots:
			var kart := slot.kart
			if kart == null or not kart.alive:
				continue
			kart.hold_item(
				load("res://data/powerups/%s.tres" % VOLLEY[slot.index % VOLLEY.size()]), 0.0
			)
			kart.item_reveal_left = 0.0
			kart.use_item()
	if _once("fire", t >= -0.12):
		for steer: Steer in _steer.values():
			steer.shooting = true


## Two karts facing off across the Vault's Junction and firing at once, both knocked out on the
## same beat: a trade. Two of the bots, the hero looking on, so no joker is offered over it.
func _stage_trade() -> void:
	var pad := _junction()
	var a := match_node.kart_of(1)
	var b := match_node.kart_of(2)
	_put(a, pad + Vector3(-3.5, 0.0, 0.0), pad)
	_put(b, pad + Vector3(3.5, 0.0, 0.0), pad)
	for kart: Kart in [a, b]:
		_drive(kart, pad, 0.0)
	_put(match_node.kart_of(0), pad + Vector3(0.0, 0.0, -3.75), pad)
	match_node.kart_of(0).frozen = true
	_bystanders(3, [Vector3(0.0, 0.0, 3.75)])


func _tick_trade(t: float) -> void:
	if _once("fire", t >= -0.3):
		for k: int in [1, 2]:
			_steer[k].shooting = true
	if _once("trade", t >= 0.25):
		var a := match_node.kart_of(1)
		var b := match_node.kart_of(2)
		a.pot.add_coins(12)
		b.pot.add_coins(12)
		_knock_out(a, 0, 2)
		_knock_out(b, 0, 1)


## Watchers' reactions floating up from the bottom of the screen, as a live stream's do, one every
## [constant REACT_EVERY] seconds from a moment before the shot so a few are on their way up as it
## starts, and the karts' own drivers putting a bubble up over theirs.
func _react(t: float) -> void:
	var count := roundi((t + REACT_FROM) / REACT_EVERY)
	for i: int in clampi(count, 0, REACT_MOST):
		if not _once("react%d" % i, true):
			continue
		var watchers := match_node.find_children("*", "WatcherEmotes", true, false)
		if watchers.is_empty():
			return
		var named: String = PlayerNames.WATCHER_NAMES[(i * 7) % PlayerNames.WATCHER_NAMES.size()]
		var emotes := watchers[0] as WatcherEmotes
		var ink := Palette.PLAYER_COLORS[(i * 3) % Palette.PLAYER_COLORS.size()]
		emotes.float_up(named, ink, i % EmoteArt.EMOTES.size())
		var bubble := emotes.get_child(emotes.get_child_count() - 1) as Control
		bubble.pivot_offset = bubble.size * Vector2(0.5, 1.0)
		bubble.scale = Vector2.ONE * REACT_SIZE
		var across: float = REACT_ACROSS[i % REACT_ACROSS.size()]
		bubble.position.x = emotes.size.x * across - bubble.size.x * 0.5
	for k: int in mini(3, match_node.slots.size()):
		if _once("bubble%d" % k, t >= -0.3 + k * 0.2):
			Events.emoted.emit(k, (k + 1) % EmoteArt.EMOTES.size())
