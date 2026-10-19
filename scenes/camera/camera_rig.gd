class_name CameraRig
extends Node3D
## The tilted camera from GAME.md 8.2. It frames the karts rather than the arena: it comes in as
## close as it can while keeping every kart it tracks on screen, follows them about the floor,
## and can shake. It moves smoothly whatever it is asked: a kart that appears somewhere new comes
## into the framing over a moment, see [FramedSpots], and the camera eases toward the framing in
## two steps that never start or stop a move with a jolt, see [CameraEase].
##
## Framing the whole room meant the room was always the subject. Most of a match happens in a
## corner of it, and the table, the crowd and two empty thirds of the felt were taking up the
## screen while the karts were eight pixels of it. What has to be visible is every kart; the rest
## of the arena is scenery and can go off the edge.

## What a unit of tremble is worth as a shake. A beat at the top level should land between a
## kart being wrecked and a bomb going off: felt through the floor, not read off the screen.
const TREMBLE_SHAKE := 0.2
## How many halvings the aim is solved in, see [method _aim_lift]. Fourteen take it to a couple of
## millimeters over the whole arena, under a pixel on any screen anybody has, an 8K one included;
## it is worked out every frame, so it takes no more than it needs, GAME.md 10.7.
const AIM_STEPS := 14
## And how many the look-ahead is trimmed in, see [method _afforded]. Fewer, because the answer is
## a lead in meters rather than a position on the screen: a tenth of a meter is nobody's business.
const LEAD_STEPS := 10
## How wide the band between sharp and soft is, in meters: wide enough that nothing snaps into
## focus as the rig comes in or pulls out.
const FOCUS_BAND := 22.0
## Meters of floor left round the arena in the shot a match opens on, on top of the margin the
## rig always leaves. A player who has just picked a map should see the place, the table and the
## room round it with the room's own things in it, before the rig comes in and makes the karts the
## subject, GAME.md 8.2.
const ROOM_MARGIN := 9.0
## The opening shot looks past the table's middle toward where the room keeps what it is proudest
## of, as a share of the table's half-size, see [member RoomLook.opening_toward], and lower, in
## degrees off the rig's pitch, so it looks across the table at the room rather than down on it.
## The rig comes in from it over about as long as the countdown runs, eased in and out, the karts
## the subject by the green.
const OPENING_TOWARD := Vector2(0.0, -0.4)
const OPENING_TILT := -22.0
const OPENING_SECONDS := 3.4
## How often the rig works out again how far further back to sit and how far to slide its aim to
## keep the karts out from under the HUD, see [ClearView], in seconds. In between it keeps what it
## found on top of the framing it works out every frame, which is cheap, GAME.md 10.7.
const CLEAR_EVERY := 0.1
## How many slides of a look the rig tries in one frame, see [method ClearView.step]: a look takes
## a few frames, and no one frame carries the whole of it.
const CLEAR_TRIES := 4
## How high over the floor a kart's middle is, for keeping it clear of the HUD, and how far in
## from the arena's walls the fixed camera keeps the floor clear, and every how far along them, in
## meters: no kart's middle gets closer to a wall than about that.
const KART_MIDDLE := 0.5
const RIM_IN := 1.2
const RIM_STEP := 5.0
## How much quicker the rig goes back than it comes in, as a share of the time it takes.
const OUT_QUICKER := 0.25
## The floor kept in view ahead of each kart driven here, GAME.md 8.2, so its player sees what they
## are driving toward: as far as the kart gets in [constant AHEAD_SECONDS] of its travel, never less
## than [constant AHEAD_LEAST] nor more than [constant AHEAD_MOST] meters, the way it faces while it
## goes slower than [constant AHEAD_MOVING]; held on the screen and out from under the HUD as the
## kart itself is, and inside the walls, past which there is nothing to drive toward.
const AHEAD_SECONDS := 0.6
const AHEAD_LEAST := 3.0
const AHEAD_MOVING := 1.5
const AHEAD_MOST := 7.0
## How far ahead of where a kart is the camera keeps clear of the HUD, as seconds of its travel
## and at most in meters: about how long the rig takes to ease back, so a kart driven fast at a
## panel finds the camera already clear of it rather than catching up, see [method _rooms].
const SOON := 0.25
const SOON_MOST := 3.0

@export var pitch_degrees := 55.0
@export var base_fov := 35.0
@export var margin := 1.0
@export var pan_weight := 1.0
@export var pan_limit := 2.0
## The fit is worked out against a slightly narrower view than the camera really has, which is
## the margin that keeps a kart off the very edge of the screen.
@export var zoom_min := 0.93
## How long the pan takes to catch up with karts moving steadily, in seconds, see [CameraEase].
@export var smoothing := 0.6
## Meters of floor left around the karts when the camera comes in on them, and the closest it is
## ever allowed to get however tightly they are packed.
@export var follow_margin := 4.0
@export var follow_min_distance := 24.0
## How fast the distance follows the karts spreading out and closing up. Slower than the pan on
## purpose: a camera that pumps in and out with every bump is worse than one that is too far off.
@export var distance_smoothing := 1.2
@export var shake_decay := 4.0
## How far ahead of the karts being driven on this machine the camera looks: seconds of travel at
## whatever speed they are doing, and the most that is ever worth in meters, so a turbo does not
## fling the aim off across the floor. Zero looks straight at them.
@export var lead_seconds := 0.45
@export var lead_limit := 6.0
## And what the look-ahead may cost, as a fraction of the distance the rig would be at without it.
## Sliding the aim ahead pushes whatever is behind towards the edge of the screen and the fit
## answers by pulling back: given its head, seven meters of lead took the camera half again as far
## out in a close fight, which is a worse picture than the one it was fixing.
@export var lead_cost := 0.12
## And how much of the margin of floor behind the karts it may take while it is at it. Floor
## behind a kart is floor nobody is looking at: handed to the road ahead it comes off the trailing
## side of what is framed rather than out of the distance, so the first few meters of lead are
## free rather than merely cheap.
@export var lead_margin := 0.7
## How far above the floor the ears sit, so a kart right under them is not at zero distance.
## [member KartSoundStats.unit_size] has to match it: that is the distance a kart plays at its
## written level, so the two moving apart quietly changes every level in the kart mix.
@export var listener_height := 2.5
## The thump of the room at its most frantic, fed every frame and shaped by whoever sets it.
var tremble := 0.0

var targets: Array[Node3D] = []
## The karts somebody is driving on this machine. The ears sit over them rather than up at the
## camera, which frames the whole room from far enough away that every kart would sound the
## same distance off, GAME.md 8.4. Facing is the camera's, so left on screen is left in the mix.
var listener_targets: Array[Node3D] = []
var camera: Camera3D
## How far past what it is looking at the room starts going soft, and how soft it goes. Set by
## the room, GAME.md 8.1.
var focus_margin := 10.0
var focus_blur := 0.16
var listener: AudioListener3D
## What the HUD lays over the screen, in shares of it, x right and y down, kept up by [MatchHud].
## No kart is let stay under one, GAME.md 8.2: the rig goes further back, or slides its aim, until
## every kart it is following is clear of them all, see [ClearView]. Turned into the camera's own
## terms once as it is set, rather than every frame it is used.
var covers: Array[Rect2] = []:
	set(value):
		covers = value
		_covers_flat = ClearView.flat(value)

## Whether the karts' voices have been moved off them for two or more players here, so they are
## put back once there is one again.
var _voices_moved := false
var _lens: CameraAttributesPractical
var _center := Vector3.ZERO
var _arena_size := Vector2(40.0, 22.5)
var _wall_height := 1.0
var _distance := 40.0
## The furthest back it ever goes, and the aim that goes with it: the framing that holds the
## whole arena, which is where it sits when there is nobody to follow.
var _arena_distance := 40.0
var _arena_lift := 0.0
## The same, with the room round the arena in it as well: the shot a match opens on.
var _room_distance := 40.0
var _room_lift := 0.0
## And the same with the margin given back, which is where the fixed camera of 8.5 sits. The
## framing the rig waits at leaves a meter of floor round the arena because it is a shot waiting
## for karts to arrive into; one held for a whole match knows where they are and can spare it.
var _fixed_distance := 40.0
var _fixed_lift := 0.0
var _pan := Vector3.ZERO
## The pan, and the distance with the lift and the slide across, as they are eased toward what the
## framing asks for, see [CameraEase]: the members above are what they come to each frame.
var _pan_ease := CameraEase.new()
var _frame_ease := CameraEase.new()
## Where each kart counts for the framing, gliding into it as it comes into the shot somewhere new,
## see [FramedSpots]; and the rig's own clock, in seconds, which the glides are timed by.
var _spots := FramedSpots.new()
var _clock := 0.0
var _zoom := 1.0
var _shake := 0.0
var _framed := false
## Set at the whistle: the karts stop being the subject and the room becomes it again.
var _opening_up := false
## Whether this room has had its opening shot yet. One to a room: a match that waits in a lobby
## and then counts down opens once, not once for each. And how long is left of coming in from it.
var _opened := false
var _opening_left := 0.0
## The opening shot as distance, lift and pan, which the camera comes in from, see
## [method open_on_the_room]; and how far it is tilted off its pitch, in degrees.
var _opening_from := Vector3.ZERO
var _opening_pan := Vector3.ZERO
var _tilt := 0.0
## How far the aim is slid along the camera's up axis to put the slack on both sides of what is
## being framed rather than all of it above, see [method _frame_points].
var _lift := 0.0
## The look-ahead in force, worked out with the pan and used again by the framing so that the two
## agree about where the camera is looking and what it has to hold on screen.
var _led := Vector3.ZERO
## How far the aim slides across to keep the karts clear of the HUD, in meters, eased toward what
## the looks ask for; and the slide of the screen that asked for it, held between looks for a
## better one, a look every [constant CLEAR_EVERY] seconds.
var _across := 0.0
var _slide := Vector2.ZERO
var _clear_left := 0.0
## What the last look asked to add to the framing for the karts' sake, further back, up and across,
## in meters, kept on top of the framing until the next look; and what is added just now, faded
## over to that from what was added as it was asked, over [constant CLEAR_EVERY] seconds, so a
## panel coming up, or a kart going under one, moves the camera over in one move rather than at a
## jump ten times a second, see [method _fade_clear].
var _clear_wanted := Vector3.ZERO
var _clear_shown := Vector3.ZERO
var _clear_from := Vector3.ZERO
var _clear_fading := 0.0
## The look still being taken, a few slides a frame, see [constant CLEAR_TRIES], with the framing
## it was taken from.
var _look: ClearView
var _look_far := 0.0
## [member covers] as [ClearView] takes them, and which of the far slides its next look tries.
var _covers_flat := PackedFloat32Array()
var _probe := 0
## The floor ahead of each kart driven here, see [constant AHEAD_SECONDS], worked out once a frame.
var _ahead: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# The camera and the ears are placed every drawn frame, smoothed here rather than by the
	# engine: they follow karts that move on the physics tick, but the following itself is what
	# the smoothing in [method _process] is for. Left interpolated, the engine would smooth an
	# already smoothed transform and warn on every frame that it was moved outside a physics
	# tick, which is the only place this rig ever moves it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.5
	camera.far = 300.0
	camera.fov = base_fov
	# The room goes soft behind whatever the camera is looking at, GAME.md 8.1, which is what
	# makes a table read as a model of a room rather than as a room. It follows the camera rather
	# than sitting at a fixed distance: the rig comes in and pulls out, and the table has to stay
	# sharp at both ends of that.
	_lens = CameraAttributesPractical.new()
	_lens.dof_blur_far_transition = FOCUS_BAND
	camera.attributes = _lens
	add_child(camera)
	camera.make_current()
	listener = AudioListener3D.new()
	listener.name = "Listener"
	listener.top_level = true
	add_child(listener)
	listener.make_current()
	get_viewport().size_changed.connect(_refit)
	_settle()
	_place(_distance, Vector3.ZERO, 1.0)
	_place_listener()


## Takes an arena to work in: its middle to pan around, and its size for the furthest the camera
## ever pulls back to. From there the framing is the karts' business, see [method _target_framing].
func frame_arena(bounds: AABB) -> void:
	_center = Vector3(bounds.get_center().x, 0.0, bounds.get_center().z)
	_arena_size = Vector2(bounds.size.x, bounds.size.z)
	_wall_height = bounds.size.y
	_framed = true
	_opening_up = false
	var widest := _fit_arena()
	_arena_distance = widest.x
	_arena_lift = widest.y
	var wider := _fit_arena(ROOM_MARGIN)
	_room_distance = wider.x
	_room_lift = wider.y
	var tighter := _fit_arena(-margin)
	_fixed_distance = tighter.x
	_fixed_lift = tighter.y
	_opened = false
	_opening_left = 0.0
	_tilt = 0.0
	_distance = _arena_distance
	_lift = _arena_lift
	# Far enough to follow the karts anywhere on the floor, and no further: the look-at point
	# stays over the table, so the camera never ends up studying the crowd.
	pan_limit = maxf(_arena_size.x, _arena_size.y) * 0.5
	_pan = Vector3.ZERO
	_zoom = 1.0
	_across = 0.0
	_clear_wanted = Vector3.ZERO
	_clear_shown = Vector3.ZERO
	_clear_fading = 0.0
	_slide = Vector2.ZERO
	_look = null
	_spots.reset()
	_settle()
	_place(_distance, _pan, _zoom)


## Opens back out to the whole arena over [param seconds] and stays there, for the lap of
## honor at the whistle, GAME.md 8.2. A slow pull rather than a cut: the match is over, and the
## last thing it does is hand the room back.
func show_the_room(seconds: float) -> void:
	_opening_up = true
	# And it holds still for it. The tremble is only refreshed while a match is being played, so
	# one that ends at the top level would otherwise keep its last value and shake all the way
	# through the pull-out and on under the podium.
	tremble = 0.0
	_shake = 0.0
	# A time constant of about a third of the run gets most of the way there in the time given
	# while still easing rather than arriving and stopping.
	smoothing = maxf(seconds, 0.1) * 0.34
	distance_smoothing = smoothing


## The shot a match opens on, GAME.md 8.2: the arena, the crowd round it and a little of the
## room past that. Placed rather than eased into, since this happens while the map is being built
## behind the loading screen of 8.6 and there is nothing on the screen for a cut to be a cut in.
##
## Nothing is held. From the first frame the rig is doing what it always does -- coming in on the
## karts -- so the opening shot is where the move starts rather than a wait before it; only slower,
## for the length of the countdown, so the room is seen while nothing can move yet. It looks
## [param toward] a share of the table's half-size past its middle, the room's own way to look,
## see [member RoomLook.opening_toward].
func open_on_the_room(toward := OPENING_TOWARD) -> void:
	if _opened or not _framed:
		return
	_opened = true
	_opening_left = OPENING_SECONDS
	_opening_from = Vector3(_room_distance, _room_lift, 0.0)
	_opening_pan = Vector3(toward.x * _arena_size.x, 0.0, toward.y * _arena_size.y) * 0.5
	_tilt = OPENING_TILT
	_distance = _room_distance
	_lift = _room_lift
	_pan = _opening_pan
	_place(_distance, _pan, _zoom)


## Follows its targets from close in rather than framing the whole arena, for the tutorial's
## roads of GAME.md 9.4a and the development scene: a kart twenty pixels tall tells you nothing
## about how it drives.
func follow_close(distance: float) -> void:
	_framed = false
	_distance = distance
	pan_weight = 1.0
	pan_limit = 1000.0
	smoothing = 0.25
	_settle()


## Holds the camera where it has just been put, standing still: what follows eases on from there
## rather than from wherever it was eased to before, see [method CameraEase.place].
func _settle() -> void:
	_pan_ease.place(_pan)
	_frame_ease.place(Vector3(_distance, _lift, _across))


func _refit() -> void:
	if _framed:
		var widest := _fit_arena()
		_arena_distance = widest.x
		_arena_lift = widest.y
		var wider := _fit_arena(ROOM_MARGIN)
		_room_distance = wider.x
		_room_lift = wider.y
		var tighter := _fit_arena(-margin)
		_fixed_distance = tighter.x
		_fixed_lift = tighter.y


## Kicks the camera; the offset decays on its own. Nothing kicks it once the whistle has gone:
## the pull-out is a deliberate move and a bomb still in the air, or a death still resolving, is
## not a reason to rattle the last thing the match does.
func shake(strength: float) -> void:
	if _opening_up or not Game.settings.screen_shake:
		return
	_shake = maxf(_shake, strength)


func _process(delta: float) -> void:
	_clock += delta
	_pan_ease.follow(_target_pan(), smoothing, delta)
	_pan = _pan_ease.value
	_zoom = lerpf(_zoom, _target_zoom(), 1.0 - exp(-delta / maxf(smoothing, 0.001)))
	_clear_left -= delta
	_fade_clear(delta)
	var framing := _target_framing()
	# Out quicker than in: a kart driven off the edge or in under the HUD is seen again at once,
	# and one that comes in slowly still does not pump. Not the whistle's pull-out, which is slow on
	# purpose. Which way it is going is the aim's, see [CameraEase], so the camera's own speed
	# never switches it back and forth.
	var easing := distance_smoothing
	if framing.x > _frame_ease.aim.x and not _opening_up:
		easing *= OUT_QUICKER
	_frame_ease.follow(Vector3(framing.x, framing.y, _clear_shown.z), easing, delta)
	_distance = _frame_ease.value.x
	_lift = _frame_ease.value.y
	_across = _frame_ease.value.z
	_come_in(delta)
	_shake = maxf(_shake - shake_decay * delta * maxf(_shake, 0.1), 0.0)
	if tremble > 0.0:
		shake(tremble * TREMBLE_SHAKE)
	_place(_distance, _pan, _zoom)
	_place_listener()


## Coming in from the opening shot, see [method open_on_the_room]: the framing the rig works
## out every frame is blended in over the opening, eased in and out, so the camera leaves the room
## gently and lands on the karts by the green.
func _come_in(delta: float) -> void:
	if _opening_left <= 0.0:
		_tilt = 0.0
		return
	_opening_left = maxf(_opening_left - delta, 0.0)
	var done := smoothstep(0.0, 1.0, 1.0 - _opening_left / OPENING_SECONDS)
	_distance = lerpf(_opening_from.x, _distance, done)
	_lift = lerpf(_opening_from.y, _lift, done)
	_pan = _opening_pan.lerp(_pan, done)
	_tilt = OPENING_TILT * (1.0 - done)


## Puts the ears over the karts being driven here, facing the way the camera does. With nobody
## to follow they sit where the camera is looking, so the room still sounds like it is in front.
func _place_listener() -> void:
	if listener == null:
		return
	var center := _center + _pan
	var alive := _valid(listener_targets)
	if not alive.is_empty():
		center = Vector3.ZERO
		for target: Node3D in alive:
			center += target.global_position
		center /= alive.size()
	listener.global_position = Vector3(center.x, listener_height, center.z)
	listener.global_basis = camera.global_basis
	_place_voices(center, alive)


## With two or more karts driven here the ears sit between them, and each player would hear their
## own kart from halfway across the room. So every kart's voice is put where it would be if the ears
## were over whichever kart driven here is nearest it, GAME.md 8.4: each player hears their own at
## the level it is written for, and the others as they sound from where that player is.
func _place_voices(center: Vector3, here: Array[Node3D]) -> void:
	var moved := here.size() > 1
	if not moved and not _voices_moved:
		return
	_voices_moved = moved
	for target: Node3D in _valid(targets):
		var kart := target as Kart
		if kart == null or kart.sound == null:
			continue
		kart.sound.top_level = moved
		if not moved:
			kart.sound.position = Vector3.ZERO
			continue
		var nearest := here[0]
		var gap := nearest.global_position.distance_squared_to(kart.global_position)
		for each: Node3D in here:
			var this_gap := each.global_position.distance_squared_to(kart.global_position)
			if this_gap < gap:
				nearest = each
				gap = this_gap
		var offset := kart.global_position - nearest.global_position
		kart.sound.global_position = Vector3(center.x, 0.0, center.z) + offset


## Whether the rig is holding the whole arena rather than following anybody: the fixed camera of
## GAME.md 8.5. It is the framing it waits at when there is nobody to follow, so a match played
## with it on is a match watched from where the rig starts.
##
## The opening shot of 8.2 still happens and the rig still comes in from it. That move is the map
## being shown rather than the karts being chased, and a fixed camera that also refused to arrive
## would leave every match three meters further out than it belongs. What it never does is go
## anywhere the karts go.
##
## Off in the driving rooms of 9.4a, which have no arena to hold and are following a kart down a
## road on purpose.
func _fixed() -> bool:
	return _framed and Game.settings.fixed_camera


func _alive_targets() -> Array[Node3D]:
	return _valid(targets)


static func _valid(list: Array[Node3D]) -> Array[Node3D]:
	var alive: Array[Node3D] = []
	for target: Node3D in list:
		if is_instance_valid(target) and target.is_inside_tree():
			alive.append(target)
	return alive


## The middle of everybody rather than the average of them: with the camera framing the karts,
## what has to sit in the middle of the screen is the middle of the box they are all in, or the
## one furthest out is the one that falls off the edge. Slid the way the karts being driven here
## are going, see [method _lead].
##
## The lead goes on before the limit rather than after it, so a player already driving at the wall
## gets none of it. There is nothing out there to look ahead at, and the rule that the aim stays
## over the table is what keeps the camera off the crowd.
func _target_pan() -> Vector3:
	var alive := _alive_targets()
	_spots.place(alive, _clock, _center + _pan)
	_ahead.clear()
	if _opening_up or _fixed() or alive.is_empty():
		return Vector3.ZERO
	_ahead = _aheads()
	var offset := (_target_box(_spots.placed).get_center() - _center) * pan_weight
	offset.y = 0.0
	_led = _lead(_center + offset)
	return (offset + _led).limit_length(pan_limit)


## The floor ahead of each kart driven here, at a kart's middle: see [constant AHEAD_SECONDS]. From
## where the kart counts for the framing, so it comes into the shot with the kart, see
## [FramedSpots].
func _aheads() -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not _framed:
		return points
	var half := _arena_size * 0.5 - Vector2.ONE * RIM_IN
	for target: Node3D in _valid(listener_targets):
		var kart := target as Kart
		if kart != null and not kart.alive:
			continue
		var travel := Vector3.ZERO
		var body := target as CharacterBody3D
		if body != null:
			travel = Vector3(body.velocity.x, 0.0, body.velocity.z)
		var speed := travel.length()
		var way := travel / speed if speed > AHEAD_MOVING else -target.global_basis.z
		way.y = 0.0
		if way.is_zero_approx():
			continue
		var reach := clampf(speed * AHEAD_SECONDS, AHEAD_LEAST, AHEAD_MOST)
		var at := _spots.place_of(target)
		var ahead := at + way.normalized() * reach
		ahead.x = clampf(ahead.x, _center.x - half.x, _center.x + half.x)
		ahead.z = clampf(ahead.z, _center.z - half.y, _center.z + half.y)
		ahead.y = at.y + KART_MIDDLE
		points.append(ahead)
	return points


## How far to slide the aim towards where the karts being driven on this machine are going,
## GAME.md 8.2, with [param at] where the rig would be looking without it.
##
## The rig frames every kart, which puts the middle of all of them in the middle of the screen; for
## the player at the wheel that is as much screen behind their kart as in front, and what a driver
## needs is the road ahead. This slides the aim the way they are actually traveling -- travel
## rather than facing, so a kart sliding out of a corner leads the way it is really going -- by
## however far they would get in [member lead_seconds]. Standing still it is nothing, so a kart
## waiting on the grid still sits in the middle.
##
## Only the karts somebody is driving here get it. A rival's kart is something to watch, not
## somewhere to look, and leading for all four would be four leads canceling each other out.
func _lead(at: Vector3) -> Vector3:
	var driven := _valid(listener_targets)
	if lead_seconds <= 0.0 or driven.is_empty():
		return Vector3.ZERO
	var ahead := Vector3.ZERO
	for target: Node3D in driven:
		var body := target as CharacterBody3D
		if body != null:
			ahead += Vector3(body.velocity.x, 0.0, body.velocity.z)
	var want := (ahead * (lead_seconds / float(driven.size()))).limit_length(lead_limit)
	return _afforded(want, _spots.placed, at)


## As much of [param want] as the framing can pay for. The fit in [method _target_framing] still
## has to hold every kart on screen from wherever the aim ends up, so a lead that slides the aim
## off the middle of the field is paid for in distance. Whatever it can have for
## [member lead_cost] it takes, and the rest it gives up: a camera that pulls back to look ahead
## has made everything smaller to show more of it, which is the trade the other way round.
##
## With one kart to follow it is nearly all free, since the rig is already as close as it is
## allowed to get and the slack under that clamp costs nothing to spend.
##
## Solved by halving rather than in closed form: which corner of the framing binds changes as the
## aim slides, so what a lead costs is not a straight line in how far it goes. [param places] are
## where the karts being framed count, see [FramedSpots].
func _afforded(want: Vector3, places: PackedVector3Array, at: Vector3) -> Vector3:
	if not _framed or places.is_empty() or want.is_zero_approx():
		return want
	var plain := _needed_distance(_framed_corners(places, Vector3.ZERO), at)
	var budget := maxf(plain, follow_min_distance) * (1.0 + lead_cost)
	if _needed_distance(_framed_corners(places, want), at + want) <= budget:
		return want
	var low := 0.0
	var high := 1.0
	for i: int in LEAD_STEPS:
		var mid := (low + high) * 0.5
		var tried := want * mid
		if _needed_distance(_framed_corners(places, tried), at + tried) <= budget:
			low = mid
		else:
			high = mid
	return want * low


## How far back the camera has to be for every kart, with its margin of floor, to be on screen:
## the whole point of the rig, GAME.md 8.2. Never closer than [member follow_min_distance] and,
## for the screen's edges, never further than the distance that holds the whole arena, which is
## where it waits when there is nobody to follow; further only to keep a kart out from under the
## HUD, see [method _clear].
func _target_framing() -> Vector2:
	if not _framed:
		_want_clear(Vector3.ZERO)
		return Vector2(_distance, 0.0)
	# Before the whistle's own framing as well as before the karts': opening back out at the end
	# is a move, and a camera that was asked not to move should not make one. It still keeps the
	# floor out from under the HUD: all of it, since it never goes where the karts go.
	if _fixed():
		var rim := _arena_points(-RIM_IN)
		var whole := _arena_points(0.0, true)
		return _clear(rim, whole, _center, _fixed_distance, _fixed_lift, _fixed_distance)
	var alive := _alive_targets()
	if _opening_up or alive.is_empty():
		_want_clear(Vector3.ZERO)
		return Vector2(_arena_distance, _arena_lift)
	# Where the karts count, gliding in as they come into the shot: again, for a frame that has not
	# asked yet, and the same answer for one that has.
	_spots.place(alive, _clock, _center + _pan)
	var corners := _framed_corners(_spots.placed, _led)
	# The aim is worked out at the distance actually used, since a clamp changes what sits where.
	var at := _center + _pan
	var far := clampf(_needed_distance(corners, at), follow_min_distance, _arena_distance)
	var middles: Array[Vector3] = []
	for place: Vector3 in _spots.placed:
		middles.append(place + Vector3.UP * KART_MIDDLE)
	# And the floor ahead of each kart driven here, kept out from under the HUD as the karts are.
	middles.append_array(_ahead)
	var rooms := _rooms(alive)
	return _clear(
		middles, corners, at, far, _aim_lift(corners, at, far), follow_min_distance, rooms
	)


## How far round each of [param alive] the HUD is kept off, see [constant SOON]: a kart and a little
## air round it, and as far as it gets in a moment more on the move. The floor ahead of a kart
## driven here, which comes after them, keeps the room of a kart standing still.
static func _rooms(alive: Array[Node3D]) -> PackedFloat32Array:
	var rooms := PackedFloat32Array()
	for target: Node3D in alive:
		var body := target as CharacterBody3D
		var speed := Vector2(body.velocity.x, body.velocity.z).length() if body != null else 0.0
		rooms.append(ClearView.KART_ROOM + minf(speed * SOON, SOON_MOST))
	return rooms


## The framing that keeps every one of [param points] out from under the HUD's [member covers],
## see [ClearView], with every one of [param corners] still on the screen: [param far] and
## [param lift] the framing for the corners alone looking at [param at], and [param closest] the
## nearest the rig may come. Sets the slide across the aim eases to. Worked out afresh a few times a
## second, and kept on top of the framing in between, see [constant CLEAR_EVERY], each answer faded
## over to, see [member _clear_shown]; with nothing over the screen, faded back out.
func _clear(
	points: Array[Vector3],
	corners: Array[Vector3],
	at: Vector3,
	far: float,
	lift: float,
	closest: float,
	rooms := PackedFloat32Array()
) -> Vector2:
	if _covers_flat.is_empty():
		_slide = Vector2.ZERO
		_want_clear(Vector3.ZERO)
		_look = null
		return Vector2(far + _clear_shown.x, lift + _clear_shown.y)
	if _look != null:
		if _look.step(CLEAR_TRIES):
			_take(_look.answer(), _look_far)
			_look = null
	elif _clear_left <= 0.0:
		_clear_left = CLEAR_EVERY
		_probe += 1
		var tan_v := tan(deg_to_rad(base_fov) * 0.5)
		var tan_fit := tan(deg_to_rad(base_fov * zoom_min) * 0.5)
		_look = ClearView.start(
			_covers_flat,
			_in_view(points, at),
			_in_view(corners, at),
			far,
			lift,
			closest,
			maxf(_arena_distance, far),
			Vector2(tan_fit * _aspect(), tan_fit),
			Vector2(tan_v * _aspect(), tan_v),
			_slide,
			_probe,
			rooms
		)
		_look_far = far
		# The slide in use, answered afresh at once; the others over the next few frames.
		_take(_look.held(), far)
		if _look.step(CLEAR_TRIES - 1):
			_take(_look.answer(), far)
			_look = null
	return Vector2(far + _clear_shown.x, lift + _clear_shown.y)


## [param clear], a look's answer for the framing [param far] back, kept on top of the framing
## until the next, see [member _clear_wanted].
func _take(clear: ClearView, far: float) -> void:
	_slide = clear.slide
	_want_clear(Vector3(clear.distance - far, clear.lift, clear.across))


## Asks for [param clear] on top of the framing, back, up and across, faded over to from what is
## on it now, see [member _clear_shown]. Asked again for the same, the fade goes on as it was.
func _want_clear(clear: Vector3) -> void:
	if clear == _clear_wanted:
		return
	_clear_wanted = clear
	_clear_from = _clear_shown
	_clear_fading = CLEAR_EVERY


## What is on top of the framing [param delta] seconds further over to what the last look asked
## for: in a straight line, over [constant CLEAR_EVERY] seconds, so one look's answer has come in
## as the next is asked for and the camera is taken from one to the next without a jump.
func _fade_clear(delta: float) -> void:
	_clear_fading = maxf(_clear_fading - delta, 0.0)
	_clear_shown = _clear_wanted.lerp(_clear_from, _clear_fading / CLEAR_EVERY)


## The corners of the box the rig has to hold on screen: every kart it is tracking, where it counts
## for the framing, see [FramedSpots], with its margin of floor round it, and the floor ahead of
## each kart driven here, see [constant AHEAD_SECONDS], from the floor to the top of the walls.
##
## With a [param lead] on, up to [member lead_margin] of that margin comes off the trailing side.
## Floor behind a kart is floor nobody is looking at, and taking it there rather than out of the
## distance is what makes the first few meters of look-ahead free: the trailing corner ends up
## exactly as far from the aim as it was before the aim moved.
func _framed_corners(places: PackedVector3Array, lead: Vector3) -> Array[Vector3]:
	var box := _target_box(places).grow(follow_margin)
	for axis: int in [Vector3.AXIS_X, Vector3.AXIS_Z]:
		var give := minf(absf(lead[axis]), follow_margin * lead_margin)
		box.size[axis] -= give
		if lead[axis] > 0.0:
			box.position[axis] += give
	for ahead: Vector3 in _ahead:
		box = box.expand(Vector3(ahead.x, box.position.y, ahead.z))
	box.position.y = 0.0
	box.size.y = maxf(_wall_height, 1.5)
	var corners: Array[Vector3] = []
	for i: int in 8:
		corners.append(box.get_endpoint(i))
	return corners


## The box every one of [param places] is inside: where the tracked karts count for the framing.
static func _target_box(places: PackedVector3Array) -> AABB:
	var box := AABB(places[0], Vector3.ZERO)
	for place: Vector3 in places:
		box = box.expand(place)
	return box


## The zoom is the distance's job now. The field of view stays where it is, so a kart the same
## size on screen is the same distance away wherever it is standing.
func _target_zoom() -> float:
	return 1.0


func _place(distance: float, pan: Vector3, zoom: float) -> void:
	var pitch := deg_to_rad(pitch_degrees + _tilt)
	var look_at_point := _center + pan + _up_axis() * _lift + Vector3.RIGHT * _across
	var offset := Vector3(0.0, sin(pitch), cos(pitch)) * distance
	if _shake > 0.0:
		offset += (
			Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0) * _shake * 0.3
		)
	camera.position = look_at_point + offset
	camera.look_at_from_position(camera.position, look_at_point, Vector3.UP)
	_lens.dof_blur_far_enabled = focus_blur > 0.0
	_lens.dof_blur_far_distance = distance + focus_margin
	_lens.dof_blur_amount = focus_blur
	camera.fov = base_fov * zoom


## The distance and the aim that hold every corner of the arena, with margin, inside the view.
func _fit_arena(extra := 0.0) -> Vector2:
	var corners := _arena_points(margin + extra, true)
	var far := _needed_distance(corners, _center)
	return Vector2(far, _aim_lift(corners, _center, far))


## Points round the arena's floor [param out] meters out past its walls, in for less than none:
## its corners, and with [param tall] the tops of its walls over them; or, without, the corners and
## the points between them every [constant RIM_STEP] meters or so, at a kart's middle, which is what
## the fixed camera keeps clear of the HUD.
func _arena_points(out: float, tall := false) -> Array[Vector3]:
	var half := _arena_size * 0.5 + Vector2.ONE * out
	var points: Array[Vector3] = []
	if tall:
		for x: int in [-1, 1]:
			for z: int in [-1, 1]:
				points.append(_center + Vector3(x * half.x, 0.0, z * half.y))
				points.append(_center + Vector3(x * half.x, _wall_height, z * half.y))
		return points
	var steps := Vector2i(ceili(half.x / RIM_STEP), ceili(half.y / RIM_STEP))
	for i: int in range(-steps.x, steps.x + 1):
		var x := half.x * float(i) / float(steps.x)
		points.append(_center + Vector3(x, KART_MIDDLE, -half.y))
		points.append(_center + Vector3(x, KART_MIDDLE, half.y))
	for j: int in range(-steps.y + 1, steps.y):
		var z := half.y * float(j) / float(steps.y)
		points.append(_center + Vector3(-half.x, KART_MIDDLE, z))
		points.append(_center + Vector3(half.x, KART_MIDDLE, z))
	return points


## Aspect ratio of the viewport the camera renders to.
func _aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	if size.y <= 0.0:
		return 16.0 / 9.0
	return size.x / size.y


## The smallest distance at which every one of [param points] projects inside the view of a
## camera looking at [param at]. Worked out from the camera's own geometry rather than asked of
## Godot, whose frustum queries only answer after a frame has rendered, and this has to answer at
## load and again every frame.
##
## The camera only ever slides along one line, so in its own coordinates moving it back by d
## moves every point d further away and nothing else. A point is on screen while its sideways
## offset fits inside the cone at its depth, which rearranges into a smallest d per point; the
## answer is the largest of those.
## Where [param points] land in the camera's own coordinates, looking at [param at] from a
## distance of zero. Sliding the camera back by d takes d off the z of every one of them and
## changes nothing else, which is what the two below are built on.
func _in_view(points: Array[Vector3], at: Vector3) -> Array[Vector3]:
	var pitch := deg_to_rad(pitch_degrees)
	var back := Vector3(0.0, sin(pitch), cos(pitch))
	var view := Basis.looking_at(-back, Vector3.UP).transposed()
	var seen: Array[Vector3] = []
	for point: Vector3 in points:
		seen.append(view * (point - at))
	return seen


## The smallest distance at which every one of [param points] projects inside the view of a
## camera looking at [param at]. Worked out from the camera's own geometry rather than asked of
## Godot, whose frustum queries only answer after a frame has rendered, and this has to answer at
## load and again every frame.
##
## Sideways it is one inequality per point. Up and down it is a pair, because the aim slides too:
## a point is on screen while |y - L| <= tan_v * (d - z), so d has to be big enough that some L
## satisfies every point at once, which is where the two tightest of them meet.
func _needed_distance(points: Array[Vector3], at: Vector3) -> float:
	var tan_v := tan(deg_to_rad(base_fov * zoom_min) * 0.5)
	var tan_h := tan_v * _aspect()
	var needed := (camera.near if camera != null else 0.5) + 1.0
	var highest := -INF
	var lowest := INF
	for local: Vector3 in _in_view(points, at):
		needed = maxf(needed, local.z + absf(local.x) / tan_h)
		highest = maxf(highest, local.y + tan_v * local.z)
		lowest = minf(lowest, local.y - tan_v * local.z)
	if points.is_empty():
		return needed
	return maxf(needed, (highest - lowest) / (2.0 * tan_v))


## How far to slide the aim along the camera's up axis so that [param points], seen from
## [param distance], sit as far below the middle of the screen as they do above it.
##
## The camera is tilted, so the floor does not project symmetrically: the near edge of a thing
## lands lower than the far edge lands high. Left alone, the fit puts whichever of them binds
## hard against its edge of the frame and piles all the slack on the other side, which is the
## empty band above the arena. Sliding the aim costs nothing and splits the slack in two.
##
## Solved by bisection rather than in closed form: which two points end up at the edges depends on
## the aim, since they sit at different depths and a slide is worth more to the near one. Each
## point's height and depth do not change with the aim, so they are worked out once, and each
## halving only asks how far the highest and lowest miss the middle by, added up: zero when they
## straddle it evenly.
func _aim_lift(points: Array[Vector3], at: Vector3, distance: float) -> float:
	if points.is_empty():
		return 0.0
	var heights := PackedFloat32Array()
	var nearness := PackedFloat32Array()
	var reach := 0.0
	for local: Vector3 in _in_view(points, at):
		heights.append(local.y)
		nearness.append(1.0 / maxf(distance - local.z, 0.001))
		reach = maxf(reach, absf(local.y))
	var count := heights.size()
	var low := -reach
	var high := reach
	for step: int in AIM_STEPS:
		var mid := (low + high) * 0.5
		var above := -INF
		var below := INF
		for i: int in count:
			var ratio := (heights[i] - mid) * nearness[i]
			above = maxf(above, ratio)
			below = minf(below, ratio)
		# Positive means more of it is above the middle than below, so the aim has to come up.
		if above + below > 0.0:
			low = mid
		else:
			high = mid
	return (low + high) * 0.5


## The camera's own up axis in world space, which the aim slides along.
func _up_axis() -> Vector3:
	var pitch := deg_to_rad(pitch_degrees + _tilt)
	return Vector3(0.0, cos(pitch), -sin(pitch))
