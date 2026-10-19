class_name Crowd
extends Node3D
## The people who came to watch, GAME.md 8.1: a band of small figures standing on the table all
## the way round the arena, and a DJ booth along the top edge of it.
##
## They bob along while the room is quiet. Once the excitement meter of 8.4 reaches the top two
## levels they are on their feet, and a kill sets them jumping for a couple of seconds whatever
## the meter says, so the loudest thing in a match is answered by the room rather than only by
## the HUD. The booth's speakers pulse on the beat with them.
##
## There are getting on for a thousand of them, so none of them is a node. The whole crowd is one
## [MultiMesh] of one two-surface figure, drawn in two calls, and the bobbing and leaning happens
## in the vertex shader off a single beat that the whole room shares. Nothing is touched per
## figure per frame, so a fuller house costs a longer instance buffer rather than more work, and
## the crowd never shows up in a frame time. Who stands where, how big they are, which way they
## face, what they are wearing and where in the beat they are is rolled once at build time, since
## a row of identical people evenly spaced reads as a fence rather than as a crowd.
##
## Everything here is scenery: no collision, nothing to drive into, nothing that decides
## anything. A client runs its own crowd off the same events, GAME.md 10.3.

## Meters between two places along a row, between the first rows, and between the wall and the
## front row. A house is packed at the rail and thins out behind it, so both the gap along a row
## and the gap to the next one grow by [constant SPREAD] a row as they go back: the front rows
## are shoulder to shoulder and the back ones are knots of people with space around them.
const SPACING := 0.6
const ROW_DEPTH := 0.7
const ROWS := 8
const SPREAD := 0.12
const STANDOFF := 1.1
## How many rows the tribunes are stepped over. The rest of the house stands on the flat behind
## them, which is what a stand at the front of a crowd looks like from outside it.
const TIERS := 4
## How far off their spot somebody may stand, and how often a place is taken at all: a gap in a
## crowd is what makes the rest of it look like people rather than like a pattern.
const JITTER := 0.28
## The shortest and the tallest of them, as a share of the usual size.
const SIZE_RANGE := Vector2(0.82, 1.18)
## How full the front row is and how full the back one is. Everything between is taken across the
## rows, so the house fades out rather than ending in a line.
const PACKED := 0.94
const THINNED := 0.3
## The stands: how long one stretch of tribune is, how far each row of it is lifted over the row
## in front, how far one keeps off a corner, and how far its steps run past the last person on
## them so that nobody is standing on the edge of one.
const STAND_LENGTH := Vector2(7.0, 13.0)
const TIER := 0.4
const CORNER_CLEARANCE := 2.5
const STAND_MARGIN := 0.7
## How far out into the band the booth stands, in meters, and the patch of table it is given: the
## booth is in the crowd rather than behind it, so people who would be standing where it is go
## somewhere else instead. In meters rather than in rows, because the rows are not evenly spaced:
## it has to leave a couple of them in front of it whatever the spacing behind it does.
const BOOTH_OUT := 2.9
const BOOTH_CLEARANCE := Vector2(7.4, 1.5)
## How many places a stand is allowed to try before it gives up on that side, so a stand never
## ends up built through the booth.
const STAND_TRIES := 8
## Away from the arena, on each of the four sides.
const OUTWARD: Array[Vector3] = [
	Vector3(0.0, 0.0, -1.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(-1.0, 0.0, 0.0),
	Vector3(1.0, 0.0, 0.0),
]
## The table top, which is where they stand: the felt is a slab of this thickness on top of it.
const TABLE_TOP := -Arena.FLOOR_THICKNESS
const BODY := 0.42
const HEAD := 0.17
## How wide the cream margin round a paper doll is.
const MARGIN := 0.03
## The excitement level at which the room is on its feet, GAME.md 8.4.
const DANCING_LEVEL := 5
## How high a jump goes, how far a dancer leans with it, and how long a kill keeps them at it.
const JUMP := 0.4
const DANCING_LEAN := 0.28
const DANCING_RATE := 7.0
const CHEER := 1.8
## The same three while the room is quiet: a shuffle rather than a dance.
const RESTING_LIFT := 0.045
const RESTING_LEAN := 0.05
const RESTING_RATE := 1.7
## The Final Hand's house, STORY.md 6.9: how far everybody leans in toward the candidate, a meter
## up, and the applause at the whistle, quick and small and all at once.
const WATCH_LEAN := 0.3
## Before the Final Hand, STORY.md 6.9: the figures ranked for watching the player's kart, those
## most in view first, and where in that order the one who never falls into step stands.
const ODD_ONE_AT := 30
const APPLAUSE_LIFT := 0.08
const APPLAUSE_RATE := 16.0
## How fast the room takes up a new mood, and the beat's own period, which it is wrapped at so
## that an hour-long match never runs it out of float precision or jumps when it comes round.
## How many frames the house waits before standing up again at a new size of the setting, GAME.md
## 8.5, so a slider dragged across the page stands it up once rather than at every step.
const REBUILD_WAIT := 2
const SETTLE := 5.0
const PERIOD := TAU * 2.0
## What a crowd wears when its room does not say: a carnival, which is what the first room in
## the game was. A room with a wardrobe of its own, GAME.md 8.1, overrides this.
const SHIRTS: Array[Color] = [
	Color("#E23D3D"),
	Color("#3D6FE2"),
	Color("#F2D23D"),
	Color("#43C463"),
	Color("#9B4FE2"),
	Color("#F28C3D"),
	Color("#3DD9E2"),
	Color("#F26BB8"),
	Color("#E8D8A0"),
]
## What the figures are drawn by, see crowd_shirt.gdshader and crowd_face.gdshader beside this
## script and crowd_figure.gdshaderinc, which is the part they share: the animation, run on the
## figures themselves rather than on their transforms, and the room's light on them.
const SHIRT_SHADER: Shader = preload("res://scenes/arena/crowd_shirt.gdshader")
const FACE_SHADER: Shader = preload("res://scenes/arena/crowd_face.gdshader")

## The room this crowd is standing in, GAME.md 8.1: what they are wearing, how brightly they
## are lit and what color the light on their edges is.
var room: RoomLook
## The excitement level of the match, 0 to 6. The match keeps it up to date.
var level := 0
## Scenery can be switched off: the Garage in 9.4 is not a party, GAME.md 8.1.
var enabled := true
## How far up the booth stands, on a riser somebody else puts under it, and how much bigger than
## usual it is. A room is played in with the booth at table height; the end of a Grand Prix puts
## it up on a stage where it can be seen over the podium, GAME.md 9.7.
var booth_lift := 0.0
var booth_scale := 1.0
## Everybody holding their breath, the DJ too: the moment before a drop, GAME.md 9.7. Stands the
## whole house still whatever the meter says, and lets it go again where the meter has it.
var still := false
## How much of their own place in the beat each of them keeps, 1 for all of it and 0 for a house
## moving as one: the story's, STORY.md 6.9, set by whoever dresses the room.
var spread := 1.0:
	set = _set_spread

## Where everybody is standing, kept after the build because it is the record of the house.
var _spots: Array[Transform3D] = []
## The footprints of the tribunes, flat on the table: inside one, a row stands a step higher.
var _footprints: Array[Rect2] = []
## Patches of table nobody stands in and no stand is built over: the booth's, and whatever else
## has been put out there since, such as the score tanks of GAME.md 8.1.
var _clear: Array[Rect2] = []
## The size of the arena this house was raised around, so it can be raised again.
var _size := Vector2.ZERO
var _stands: Node3D
var _shirts: PackedColorArray = []
var _traits: PackedColorArray = []
## The house, one [MultiMeshInstance3D] a side of the table under this, GAME.md 10.7: a
## MultiMesh is culled whole, so a camera zoomed onto one end of the table drops the far
## side's people before a vertex of them is run, where one house for the lot was always drawn.
var _onlookers: Node3D
var _houses: Array[MultiMeshInstance3D] = []
## Which side of the table each spot stands on, 0 to 3, in step with [member _spots].
var _sides: PackedInt32Array = []
var _skins: Array[ShaderMaterial] = []
var _speakers: Array[Node3D] = []
## Whoever is behind the decks, who dances in the booth's own space rather than on the table.
var _dj: Node3D
var _cheer := 0.0
## The kart the whole house is watching at the Final Hand, see [method watch], and whether the
## whistle has gone on it.
var _watched: Node3D
var _applause := false
## The kart the few who have stopped to watch follow, and how many of them, see
## [method watched_by].
var _followed: Node3D
var _followers := 0
## Frames left until the house goes up again, 0 when it is standing as it should be.
var _rebuild_wait := 0
## Whether the house is to be stood up again at the end of this frame, see [method keep_clear].
var _restanding := false
## The share of the house that came, GAME.md 8.5, as it was when the house was built: a change
## to the setting stands the house up again at the new size.
var _built_size := 1.0
## The Count Room's house, STORY.md 3.9: exact rows of figures all the same, undressed, facing the
## table, no tribune, and nobody at the console.
var _uniform := false
var _places := 0
var _beat := 0.0
var _rate := RESTING_RATE
var _lift := RESTING_LIFT
var _lean := RESTING_LEAN
var _rng := RandomNumberGenerator.new()


## Fills the table around an arena of [param size] meters with onlookers.
static func add_to(
	parent: Node3D, size: Vector2, in_room: RoomLook = null, booth_lift := 0.0, booth_scale := 1.0
) -> Crowd:
	var crowd := Crowd.new()
	crowd.name = "Crowd"
	crowd.room = in_room if in_room != null else RoomLook.fallback()
	crowd.booth_lift = booth_lift
	crowd.booth_scale = booth_scale
	parent.add_child(crowd)
	crowd._build(size)
	return crowd


func _ready() -> void:
	Events.kart_killed.connect(_on_kart_killed)


func _exit_tree() -> void:
	if Events.kart_killed.is_connected(_on_kart_killed):
		Events.kart_killed.disconnect(_on_kart_killed)


## How many people came.
func count() -> int:
	return _spots.size()


func _process(delta: float) -> void:
	# A new size stands the house up again; Off only hides it, so turning it back on is at once.
	var wanted := Game.settings.crowd_size
	if _rebuild_wait == 0 and _size != Vector2.ZERO and wanted > 0.0 and _built_size != wanted:
		_rebuild_wait = REBUILD_WAIT
	if _rebuild_wait > 0:
		_rebuild_wait -= 1
		if _rebuild_wait == 0:
			_build(_size)
	visible = enabled
	if not enabled:
		return
	# A player who would rather have the table to themselves keeps the booth and loses the house,
	# GAME.md 8.5. Hidden rather than never built, since the setting can be changed mid-match.
	var watching := Game.settings.crowd_size > 0.0
	_onlookers.visible = watching
	if _stands != null:
		_stands.visible = watching
	_cheer = maxf(_cheer - delta, 0.0)
	var dancing := level >= DANCING_LEVEL or _cheer > 0.0
	var blend := 1.0 - exp(-delta * SETTLE)
	var hold := 0.0 if still else 1.0
	var rate := DANCING_RATE if dancing else RESTING_RATE
	var lift := JUMP if dancing else RESTING_LIFT
	var lean := DANCING_LEAN if dancing else RESTING_LEAN
	if _applause:
		rate = APPLAUSE_RATE
		lift = APPLAUSE_LIFT
		lean = 0.0
	_rate = lerpf(_rate, rate * hold, blend)
	_lift = lerpf(_lift, lift * hold, blend)
	_lean = lerpf(_lean, lean * hold, blend)
	_beat = fmod(_beat + delta * _rate, PERIOD)
	if watching:
		var watched := is_instance_valid(_watched)
		for skin: ShaderMaterial in _skins:
			skin.set_shader_parameter(&"beat", _beat)
			skin.set_shader_parameter(&"lift", _lift)
			skin.set_shader_parameter(&"lean", _lean)
			if watched:
				skin.set_shader_parameter(&"watch_point", _watched.global_position)
			if is_instance_valid(_followed):
				skin.set_shader_parameter(&"watcher_point", _followed.global_position)
	_step_booth()


## The booth is four nodes rather than a thousand, so it is animated the ordinary way.
func _step_booth() -> void:
	if _dj != null:
		_dj.position.y = absf(sin(_beat)) * _lift
		_dj.rotation.z = sin(_beat * 0.5) * _lean
	var thump := 1.0 + (_lean * 0.8) * (1.0 - Audio.music_beat())
	for speaker: Node3D in _speakers:
		speaker.scale = Vector3(thump, thump, thump)


## The Final Hand, STORY.md 6.9: the whole house stops dancing, in step and still, and leans in
## toward [param kart] wherever it goes, until [method applaud]. Null lets them go back to the beat.
func watch(kart: Node3D) -> void:
	_watched = kart
	_applause = false
	still = kart != null
	if kart != null:
		spread = 0.0
	for skin: ShaderMaterial in _skins:
		skin.set_shader_parameter(&"watch", WATCH_LEAN if kart != null else 0.0)


## Before the Final Hand, STORY.md 6.9: the [param many] most in view stop dancing and lean in
## toward [param kart] wherever it goes, the rest dancing on; none for none.
func watched_by(many: int, kart: Node3D) -> void:
	_followed = kart
	_followers = many
	for skin: ShaderMaterial in _skins:
		skin.set_shader_parameter(&"watchers", _watchers_share())
		skin.set_shader_parameter(&"watcher_lean", WATCH_LEAN)


## The rank under which a figure is one of those watching, see [method _rank].
func _watchers_share() -> float:
	if _followers <= 0 or _spots.is_empty():
		return 0.0
	return 0.01 + 0.98 * (float(mini(_followers, _spots.size())) / float(_spots.size()))


## How many of the house are watching the one kart before the Final Hand, for the tests.
func watchers() -> int:
	if _skins.is_empty():
		return 0
	var share := float(_skins[0].get_shader_parameter(&"watchers"))
	if share <= 0.0:
		return 0
	return roundi((share - 0.01) / 0.98 * float(_spots.size()))


## The whistle at the Final Hand: the whole house applauding together, still facing the
## candidate.
func applaud() -> void:
	still = false
	_applause = true


func _set_spread(to: float) -> void:
	spread = clampf(to, 0.0, 1.0)
	for skin: ShaderMaterial in _skins:
		skin.set_shader_parameter(&"spread", spread)


## Somebody went down, GAME.md 3.6. Worth getting up for whatever the meter says.
func _on_kart_killed(_victim: int, _killer: int, _cause: StringName) -> void:
	_cheer = CHEER


## Keeps a patch of table free and stands the house up again around it. For whatever else ends
## up out here: a crowd standing in front of a thing put there to be looked at is worse than a
## slightly smaller crowd.
func keep_clear(area: Rect2) -> void:
	_clear.append(area)
	# Stood up again at the end of this frame rather than here and now, and once however many
	# bays are asked for in it: the tanks and the clock board each want one, and a house rebuilt
	# per asker is a thousand people put down and picked up again over and over, which is long
	# enough to be felt. And not a frame or two later: the match's own askers ask in the frame the
	# loading screen goes, GAME.md 8.6, and a house stood up again once it is on the screen reads
	# as people popping in.
	if _size != Vector2.ZERO and not _restanding:
		_restanding = true
		_stand_again.call_deferred()


## The house stood up again round every bay asked for this frame, see [method keep_clear].
func _stand_again() -> void:
	_restanding = false
	if is_inside_tree():
		_build(_size)


## The patches of table that are already spoken for: the booth, the hoardings, the tanks. Anybody
## putting something else down out here asks for these rather than guessing where they are.
func taken_bays() -> Array[Rect2]:
	return _clear.duplicate()


## Whether [param at] falls in a patch that is being kept clear, grown by [param slack].
func _blocked(at: Vector2, slack: float) -> bool:
	for area: Rect2 in _clear:
		if area.grow(slack).has_point(at):
			return true
	return false


## Whether [param box] runs into a patch that is being kept clear, grown by [param slack].
func _overlaps(box: Rect2, slack: float) -> bool:
	for area: Rect2 in _clear:
		if box.intersects(area.grow(slack)):
			return true
	return false


func _build(size: Vector2) -> void:
	_rng.seed = hash(size)
	_size = size
	_built_size = Game.settings.crowd_size
	_uniform = room.crowd_dress == RoomLook.Dress.UNIFORM
	_places = 0
	# A rebuild starts from an empty table: the booth puts its own patch back as it goes down.
	# Freed on the spot rather than queued: a node taken out of the tree and left waiting for a
	# queued free is a node with no parent, which is what Godot counts as an orphan, and a house
	# that rebuilt itself just before a test finished left two dozen of them lying about.
	for child: Node in get_children():
		child.free()
	_spots.clear()
	_sides.clear()
	_shirts.clear()
	_traits.clear()
	_footprints.clear()
	_skins.clear()
	_speakers.clear()
	_onlookers = null
	_houses.clear()
	_stands = null
	_dj = null
	var kept := _clear.duplicate()
	_clear.clear()
	var half := size * 0.5
	var outer := half + Vector2.ONE * _row_out(ROWS - 1)
	# The booth goes down first because everything else is placed around it: it stands a couple
	# of rows into the crowd, with people in front of it and people behind it, rather than out on
	# its own behind the back row where it read as a thing parked next to the party.
	_booth(Vector3(0.0, TABLE_TOP, -(half.y + BOOTH_OUT)))
	for area: Rect2 in kept:
		if not _clear.has(area):
			_clear.append(area)
	if not _uniform:
		_raise_stands(half)
	for row: int in ROWS:
		_ring(half + Vector2.ONE * _row_out(row), row)
	_rank(half)
	_raise_house(outer)


## Ranks everybody for watching the player's kart, STORY.md 6.9, in the fraction of the lean's
## phase each carries, the phase kept to a 64th of a radian: the far side's front row, in the
## camera's view, first and its middle before its ends, the rest after them; and the one ranked
## 0, a little further back, the one who never falls into step.
func _rank(half: Vector2) -> void:
	var order: Array[Vector2] = []
	for i: int in _spots.size():
		var at := _spots[i].origin
		var away := (0.0 if _sides[i] == 0 else 100.0) + (absf(at.z) - half.y) * 3.0
		order.append(Vector2(away + absf(at.x) * 0.25 + _rng.randf() * 0.6, float(i)))
	order.sort()
	var count := order.size()
	for k: int in count:
		var i := int(order[k].y)
		var traits := _traits[i]
		var rank := 0.0 if k == mini(ODD_ONE_AT, count - 1) else 0.01 + 0.98 * (k + 0.5) / count
		traits.a = floorf(traits.a * 64.0) + rank
		_traits[i] = traits


## One row of onlookers, walked round the four edges of a rectangle. Each edge leaves its far
## corner to the edge after it, so nobody is standing inside anybody.
func _ring(half: Vector2, row: int) -> void:
	var corners: Array[Vector3] = [
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, half.y),
	]
	for i: int in 4:
		_line(corners[i], corners[(i + 1) % 4], row, i)


## How far out from the arena wall row [param row] stands, and how far apart the people in it
## are. Both grow with the row: a house is packed at the rail and thins out behind it.
static func _row_out(row: int) -> float:
	var out := STANDOFF
	for i: int in row:
		out += ROW_DEPTH * (1.0 + float(i) * SPREAD)
	return out


static func _row_spacing(row: int) -> float:
	return SPACING * (1.0 + float(row) * SPREAD)


## How full a row is: the front one is shoulder to shoulder and the back one is a scattering.
static func _row_density(row: int) -> float:
	return lerpf(PACKED, THINNED, float(row) / maxf(float(ROWS - 1), 1.0))


func _line(from: Vector3, to: Vector3, row: int, side: int) -> void:
	var steps := maxi(int(from.distance_to(to) / _row_spacing(row)), 1)
	for i: int in steps:
		_stand(from.lerp(to, float(i) / float(steps)), row, side)


## Rolls one onlooker onto a spot on [param side] of the table, or leaves the spot empty.
func _stand(at: Vector3, row: int, side: int) -> void:
	# Grown by the jitter, since the spot is rolled off this point and could wander in.
	if _blocked(Vector2(at.x, at.z), JITTER):
		return
	if _uniform:
		_stand_in_line(at, side)
		return
	if _rng.randf() > _row_density(row) * _built_size:
		return
	var spot := Vector3(
		at.x + _rng.randf_range(-JITTER, JITTER),
		TABLE_TOP + _tier_at(at, row),
		at.z + _rng.randf_range(-JITTER, JITTER)
	)
	var turned := Basis.from_euler(Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0))
	var size := _rng.randf_range(SIZE_RANGE.x, SIZE_RANGE.y)
	_spots.append(Transform3D(turned.scaled(Vector3.ONE * size), spot))
	_sides.append(side)
	var shirt := _wardrobe().srgb_to_linear()
	# The alpha is not transparency: it is how dark this one's face is, carried along with the
	# shirt so that one instance color dresses both surfaces.
	shirt.a = _rng.randf_range(0.0, 1.0)
	_shirts.append(shirt)
	_traits.append(
		Color(
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(0.7, 1.3),
			_rng.randf_range(0.5, 1.5),
			_rng.randf_range(0.0, TAU)
		)
	)


## One of the Count Room's house at [param at] on [param side]: on the spot, the usual size, facing
## the table, in the one gray, every one at the same point in the beat. Every place is taken, or
## every other one for half a house.
func _stand_in_line(at: Vector3, side: int) -> void:
	_places += 1
	if _built_size < 1.0 and _places % 2 == 0:
		return
	var facing := -OUTWARD[side]
	var turned := Basis.from_euler(Vector3(0.0, atan2(facing.x, facing.z), 0.0))
	_spots.append(Transform3D(turned, Vector3(at.x, TABLE_TOP, at.z)))
	_sides.append(side)
	var shirt := _wardrobe().srgb_to_linear()
	shirt.a = 0.5
	_shirts.append(shirt)
	_traits.append(Color(0.0, 1.0, 1.0, 0.0))


## How high somebody in [param row] stands at [param at]: on the table, unless a tribune has
## been built under that stretch of the band, in which case one step per row behind the front.
func _tier_at(at: Vector3, row: int) -> float:
	if row <= 0:
		return 0.0
	for stand: Rect2 in _footprints:
		if stand.has_point(Vector2(at.x, at.z)):
			return mini(row, TIERS - 1) * TIER
	return 0.0


## Builds a tribune into one stretch of each side of the band, GAME.md 8.1. Somewhere along a
## side rather than the whole of it: a stand that goes all the way round is a bowl, and this is a
## table with people standing at it.
func _raise_stands(half: Vector2) -> void:
	_stands = Node3D.new()
	_stands.name = "Stands"
	add_child(_stands)
	var tread := _paint(room.stand)
	var back := _paint(room.stand.darkened(0.25))
	for side: int in 4:
		var out := OUTWARD[side]
		var sideways := Vector3(absf(out.z), 0.0, absf(out.x))
		var along := half.x if sideways.x > 0.5 else half.y
		var across := half.y if sideways.x > 0.5 else half.x
		var run := _rng.randf_range(STAND_LENGTH.x, STAND_LENGTH.y)
		var room := along - run * 0.5 - CORNER_CLEARANCE
		if room <= 0.0:
			continue
		var edge := out * (across + STANDOFF - ROW_DEPTH * 0.5)
		var near := edge
		var footprint := Rect2()
		for attempt: int in STAND_TRIES:
			near = edge + sideways * _rng.randf_range(-room, room)
			footprint = _footprint(near, out, sideways, run)
			if not _overlaps(footprint, STAND_MARGIN):
				break
			footprint = Rect2()
		if footprint.get_area() <= 0.0:
			continue
		_footprints.append(footprint)
		_step_up(near, out, run, _stands, tread, back)
	# Every tread wears one material and every back wall the other, and none of it moves: two
	# meshes rather than one a step, GAME.md 10.7.
	Bake.merge(_stands)


## The footprint of one stand, flat on the table, which is what decides who is standing on it.
static func _footprint(near: Vector3, out: Vector3, sideways: Vector3, run: float) -> Rect2:
	var corner := near - sideways * (run * 0.5)
	var far := near + out * _row_out(TIERS) + sideways * (run * 0.5)
	return Rect2(
		Vector2(minf(corner.x, far.x), minf(corner.z, far.z)),
		Vector2(absf(far.x - corner.x), absf(far.z - corner.z))
	)


## The steps themselves: one solid block per lifted row, rising away from the arena, with a wall
## across the back of the top one.
func _step_up(
	near: Vector3, out: Vector3, run: float, parent: Node3D, tread: Material, back: Material
) -> void:
	var wide := run + STAND_MARGIN
	for row: int in range(1, TIERS):
		var high := row * TIER
		var step := MeshInstance3D.new()
		step.mesh = _slab(_spread(out, wide, ROW_DEPTH, high))
		step.material_override = tread
		step.position = (
			near + out * (ROW_DEPTH * (row + 0.5)) + Vector3.UP * (TABLE_TOP + high * 0.5)
		)
		parent.add_child(step)
	var wall := MeshInstance3D.new()
	var high := (TIERS - 1) * TIER + 0.55
	wall.mesh = _slab(_spread(out, wide, 0.3, high))
	wall.material_override = back
	wall.position = near + out * (_row_out(TIERS) + 0.15) + Vector3.UP * (TABLE_TOP + high * 0.5)
	parent.add_child(wall)


## A box laid out for a stand facing [param out]: [param wide] along the stand, [param deep] away
## from the arena.
static func _spread(out: Vector3, wide: float, deep: float, high: float) -> Vector3:
	if absf(out.z) > 0.5:
		return Vector3(wide, high, deep)
	return Vector3(deep, high, wide)


static func _slab(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## Puts the house up as one [MultiMesh] a side of the table, all four drawing the one mesh in the
## one pair of materials. Everything that varies between two people is in the instance buffers,
## which are written once and never touched again.
func _raise_house(_outer: Vector2) -> void:
	var mesh := _figure_mesh()
	mesh.surface_set_material(0, _skin(SHIRT_SHADER))
	mesh.surface_set_material(1, _skin(FACE_SHADER))
	_onlookers = Node3D.new()
	_onlookers.name = "Onlookers"
	add_child(_onlookers)
	for side: int in 4:
		var house := _raise_side(mesh, side)
		if house != null:
			_houses.append(house)


## The people on [param side] of the table as one [MultiMeshInstance3D], or null when nobody is
## standing there.
func _raise_side(mesh: Mesh, side: int) -> MultiMeshInstance3D:
	var mine: PackedInt32Array = []
	for i: int in _spots.size():
		if _sides[i] == side:
			mine.append(i)
	if mine.is_empty():
		return null
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = mine.size()
	# The box the side is culled by: round everybody's feet, out by the biggest of them and the
	# jitter they were rolled off their spots with, and up by the jump the shader lifts them by.
	var low := _spots[mine[0]].origin
	var high := low
	for at: int in mine.size():
		var spot := _spots[mine[at]]
		low = low.min(spot.origin)
		high = high.max(spot.origin)
		multimesh.set_instance_transform(at, spot)
		multimesh.set_instance_color(at, _shirts[mine[at]])
		multimesh.set_instance_custom_data(at, _traits[mine[at]])
	var house := MultiMeshInstance3D.new()
	house.name = "Side%d" % side
	house.multimesh = multimesh
	# A crowd this size casting a thousand shadows costs more than the crowd does, and they are
	# standing off the floor where nothing of the match ever reaches them.
	house.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var room := (SIZE_RANGE.y * 0.5 + JITTER) * Vector3(1.0, 0.0, 1.0)
	var tall := Vector3(0.0, (BODY + HEAD * 2.0) * SIZE_RANGE.y + JUMP + 1.0, 0.0)
	house.custom_aabb = AABB(low - room - Vector3(0.0, 0.5, 0.0), high - low + room * 2.0 + tall)
	_onlookers.add_child(house)
	return house


## How many onlookers the houses hold between them, for the tests.
func drawn() -> int:
	var total := 0
	for house: MultiMeshInstance3D in _houses:
		total += house.multimesh.instance_count
	return total


## One onlooker as a single mesh with its feet at the origin: a paper doll the House die-cut and
## printed, GAME.md 8.1b, a flat figure facing its own +Z with a margin of cream card round it, as
## a sticker sheet's are. Two surfaces still, the body and the head, so the shirt and the face are
## told apart as they were; a vertex's UV.x says whether it is the figure or the margin behind it.
## Flat is cheaper than round: a doll is sixty triangles, and it faces the camera from wherever it
## stands, see crowd_figure.gdshaderinc.
static func _figure_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shoulder := BODY + 0.04
	var parts: Array[PackedVector2Array] = [
		# The legs, the body and the arms hanging at the sides.
		PackedVector2Array(
			[Vector2(-0.1, 0.0), Vector2(-0.015, 0.0), Vector2(-0.02, 0.24), Vector2(-0.1, 0.24)]
		),
		PackedVector2Array(
			[Vector2(0.015, 0.0), Vector2(0.1, 0.0), Vector2(0.1, 0.24), Vector2(0.02, 0.24)]
		),
		PackedVector2Array(
			[
				Vector2(-0.13, 0.2),
				Vector2(0.13, 0.2),
				Vector2(0.16, shoulder),
				Vector2(-0.16, shoulder)
			]
		),
		PackedVector2Array(
			[
				Vector2(-0.2, 0.22),
				Vector2(-0.14, 0.22),
				Vector2(-0.12, shoulder),
				Vector2(-0.18, shoulder)
			]
		),
		PackedVector2Array(
			[
				Vector2(0.14, 0.22),
				Vector2(0.2, 0.22),
				Vector2(0.18, shoulder),
				Vector2(0.12, shoulder)
			]
		),
	]
	for part: PackedVector2Array in parts:
		_flat(body, part, MARGIN, -0.004, 1.0)
		_flat(body, part, 0.0, 0.0, 0.0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, body.commit_to_arrays())
	var head := SurfaceTool.new()
	head.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face := PackedVector2Array()
	for k: int in 10:
		face.append(
			Vector2.from_angle(k * TAU / 10.0) * HEAD * 0.72 + Vector2(0.0, BODY + HEAD * 0.9)
		)
	_flat(head, face, MARGIN, -0.004, 1.0)
	_flat(head, face, 0.0, 0.0, 0.0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, head.commit_to_arrays())
	return mesh


## A flat convex [param shape] facing +Z into [param tool], grown by [param grow] round its middle
## and set [param depth] behind, its UV.x [param margin]: 1 for the cream card round the figure.
## Wound clockwise seen from +Z, which is the side Godot takes for a triangle's front.
static func _flat(
	tool: SurfaceTool, shape: PackedVector2Array, grow: float, depth: float, margin: float
) -> void:
	var middle := Vector2.ZERO
	for point: Vector2 in shape:
		middle += point
	middle /= shape.size()
	var points := PackedVector2Array()
	for point: Vector2 in shape:
		points.append(point + (point - middle).normalized() * grow)
	for i: int in range(1, points.size() - 1):
		for point: Vector2 in [points[0], points[i + 1], points[i]]:
			tool.set_normal(Vector3(0.0, 0.0, 1.0))
			tool.set_uv(Vector2(margin, 0.0))
			tool.add_vertex(Vector3(point.x, point.y, depth))


## The same mesh arrays with every vertex moved up, so both surfaces stand on the same feet.
static func _lifted(arrays: Array, by: float) -> Array:
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i: int in points.size():
		points[i] += Vector3(0.0, by, 0.0)
	arrays[Mesh.ARRAY_VERTEX] = points
	return arrays


## What this one is wearing: a color from the room's own wardrobe, GAME.md 8.1, or from the
## carnival when the room names none.
func _wardrobe() -> Color:
	if room.crowd_colors.is_empty():
		return SHIRTS[_rng.randi_range(0, SHIRTS.size() - 1)]
	return room.crowd_colors[_rng.randi_range(0, room.crowd_colors.size() - 1)]


func _skin(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	# A room in the dark puts a light on the edge of everybody standing in it, GAME.md 8.1.
	var silhouette := room.crowd_dress == RoomLook.Dress.SILHOUETTE
	material.set_shader_parameter(&"rim_color", room.crowd_rim)
	material.set_shader_parameter(&"rim_strength", 0.7 if silhouette else 0.0)
	material.set_shader_parameter(&"dim", room.crowd_light)
	material.set_shader_parameter(&"spread", spread)
	if _watched != null:
		material.set_shader_parameter(&"watch", WATCH_LEAN)
	material.set_shader_parameter(&"watchers", _watchers_share())
	material.set_shader_parameter(&"watcher_lean", WATCH_LEAN)
	_skins.append(material)
	return material


## The booth at the top: a desk, a pair of speakers that pulse on the beat, and somebody behind
## it who never stops dancing.
func _booth(at: Vector3) -> void:
	var clearance := BOOTH_CLEARANCE * booth_scale
	_clear.append(Rect2(Vector2(at.x, at.z) - clearance * 0.5, clearance))
	var booth := Node3D.new()
	booth.name = "DjBooth"
	booth.position = at + Vector3(0.0, booth_lift, 0.0)
	booth.scale = Vector3.ONE * booth_scale
	add_child(booth)
	var desk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.4, 0.9, 1.0)
	desk.mesh = box
	desk.material_override = _paint(Color(0.14, 0.14, 0.18))
	desk.position = Vector3(0.0, 0.45, 0.0)
	booth.add_child(desk)
	var deck := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(2.6, 0.08, 0.7)
	deck.mesh = plate
	# The Count Room's is a console in the room's green, and nobody stands at it.
	deck.material_override = _glow(room.trim) if _uniform else _paint(Palette.NEON_MAGENTA)
	deck.position = Vector3(0.0, 0.94, 0.0)
	booth.add_child(deck)
	for side: int in [-1, 1]:
		var speaker := Node3D.new()
		speaker.position = Vector3(side * 2.6, 0.0, 0.0)
		var cabinet := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(1.0, 1.7, 1.0)
		cabinet.mesh = shape
		cabinet.material_override = _paint(Color(0.1, 0.1, 0.13))
		cabinet.position = Vector3(0.0, 0.85, 0.0)
		speaker.add_child(cabinet)
		var cone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.3
		disc.bottom_radius = 0.3
		disc.height = 0.08
		disc.radial_segments = 16
		disc.rings = 1
		cone.mesh = disc
		cone.material_override = _glow(room.trim if _uniform else Palette.NEON_CYAN)
		cone.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		cone.position = Vector3(0.0, 1.0, 0.54)
		speaker.add_child(cone)
		booth.add_child(speaker)
		_speakers.append(speaker)
	if _uniform:
		return
	var dj := Node3D.new()
	dj.position = Vector3(0.0, 0.0, -0.9)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.7
	# The DJ is one person the size of the onlookers, cut like the rest of the room's small
	# things, GAME.md 10.7.
	capsule.radial_segments = 12
	capsule.rings = 3
	body.mesh = capsule
	body.material_override = _paint(Palette.CHIP_GOLD)
	body.position = Vector3(0.0, 0.7, 0.0)
	dj.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	sphere.radial_segments = 12
	sphere.rings = 6
	head.mesh = sphere
	head.material_override = _paint(Palette.CHIP_WHITE)
	head.position = Vector3(0.0, 1.25, 0.0)
	dj.add_child(head)
	booth.add_child(dj)
	_dj = dj


func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func _glow(color: Color) -> StandardMaterial3D:
	var material := _paint(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	return material
