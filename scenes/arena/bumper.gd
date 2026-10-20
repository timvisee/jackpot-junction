class_name Bumper
extends StaticBody3D
## A pop bumper, GAME.md 6.2: a solid round post on the floor, `@` on a map, that kicks a kart
## driving into it straight back off its middle, lights its cap and sounds, as a pinball machine's
## bumper fires at the ball. It is never shot away: it kicks every shot back, whether or not the
## shot has a bounce left in it, and lights and sounds for that too, see [method Bullet._bounce];
## and a shot is bent toward one for want of anything else, see [method Bullet.nearest_target]. A
## kart is kicked ten times in a run at most, and then let be a while, see
## [constant KartMotor.KICK_CAP].
##
## The kick is movement, and is the same on every machine, GAME.md 10.3. A bumper stands in the
## same place on all of them, so a client driving its own kart throws it off one on the tick it
## touches, exactly as the host does a tick later on the same claim, and nothing has to be put
## right; the throw is in the motor's state, [member KartMotor.thrown_left], which the client
## sends with the rest. What a player sees and hears of it, the lit cap and the knock, is the
## host's to say for everybody's karts and relayed, [signal Events.bumper_kicked], and a client
## lights and sounds its own kart's at once and does not do so again when the host's word comes.
##
## What it looks like is its room's, [method RoomStyle.bumper], inside the cylinder its collider
## is; a room that builds none gets a plain one, chrome under a red cap. Whatever the style names
## `Lamp` is lit when it fires.

## The cylinder a kart meets: a little smaller than a box's cube is across, so the floor between
## two bumpers two cells apart is wide enough for a kart to get through straight.
const RADIUS := 0.55
const HEIGHT := 1.0
## How long after one firing before the next is shown and heard: a kart pinned against one by
## another kart touches it every tick, and a rattle of knocks is not a pop bumper.
const REFIRE := 0.15
## How long the cap stays lit, fading back down, and how bright it is at the top of it.
const FLASH_TIME := 0.32
const FLASH_ENERGY := 3.2
## How long a client's own word that its kart was kicked stands against the host's, so the host's
## for the same kick is not shown a second time, GAME.md 10.3.
const AHEAD_HOLD := 1.0
## How far round a bumper a shot that lands is a shot that lands on it, past its radius, and how
## much quieter its pop is for a shot than for a kart.
const SHOT_REACH := 0.2
const SHOT_DB := -4.0
## The bulb under the cap, and the plain look's chrome and red.
const BULB := Color("#FFD9A0")
const CHROME := Color("#AEB2BA")
const CAP := Color("#B4473C")

## The bumper's number in its arena, the same on every machine: what the host names it by.
var index := -1

## The lit parts' materials, this bumper's own, and how bright each is at rest.
var _lamps: Array[StandardMaterial3D] = []
var _rest: Array[float] = []
var _look: Node3D
var _flash_left := 0.0
var _quiet_left := 0.0
var _shot_quiet_left := 0.0
## For each slot whose kick this machine showed itself, until when it waits for the host's.
var _ahead: Dictionary[int, int] = {}


## A bumper for every `@` of [param arena]'s grid, into its [member Arena.bumpers].
static func add_to(arena: Arena) -> void:
	var holder := Node3D.new()
	holder.name = "Bumpers"
	arena.add_child(holder)
	var grid := arena.grid
	for i: int in grid.bumpers.size():
		var bumper := Bumper.new()
		bumper.name = "Bumper%d" % i
		bumper.index = i
		bumper.position = grid.cell_center(grid.bumpers[i])
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = RADIUS
		cylinder.height = HEIGHT
		shape.shape = cylinder
		shape.position = Vector3(0.0, HEIGHT * 0.5, 0.0)
		bumper.add_child(shape)
		bumper.dress(arena.kit.style, arena.surfaces, arena.bake_scenery)
		holder.add_child(bumper)
		arena.bumpers.append(bumper)


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	add_to_group(&"bumpers")
	# Aimed at, GAME.md 5.1, though only for want of anything else, see [method Bullet.nearest_target].
	add_to_group(Bullet.TARGET_GROUP)
	Events.bumper_kicked.connect(_on_kicked)
	Events.bullet_struck.connect(_on_shot)


func _exit_tree() -> void:
	if Events.bumper_kicked.is_connected(_on_kicked):
		Events.bumper_kicked.disconnect(_on_kicked)
	if Events.bullet_struck.is_connected(_on_shot):
		Events.bullet_struck.disconnect(_on_shot)


## Builds the look under the bumper, its room's [param style] first, and gives each lit part a
## material of its own to flash. Baked once dressed when [param bake] says, as a box is.
func dress(style: RoomStyle, surfaces: Surfaces, bake := true) -> void:
	_look = Node3D.new()
	_look.name = "Look"
	add_child(_look)
	if style == null or not style.bumper(_look, RADIUS, HEIGHT):
		_plain(surfaces)
	_own_lamps(_look)
	if bake:
		Bake.merge(_look)


## Throws [param kart] off, see [method KartMotor.throw_off]: straight away from the middle, from
## where the kart is rather than from where it touched, so every kick off one bumper is the same
## kick. [param travel] is what the kart was driving at before it met the bumper. [param quiet] is a
## client predicting its own kart, which throws it and leaves the showing of it to [method ahead].
func throw(kart: Kart, travel: Vector3, quiet := false) -> void:
	var away := kart.global_position - global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = -travel
	kart.motor.throw_off(away, travel)
	kart.velocity = kart.motor.velocity
	if not quiet:
		fire(kart.slot)


## The host's word that this bumper kicked [param slot]'s kart, for every machine, unless it was
## heard a moment ago.
func fire(slot: int) -> void:
	if _quiet_left > 0.0:
		return
	_quiet_left = REFIRE
	Events.bumper_kicked.emit(slot, index)


## A client's own kart kicked here, GAME.md 10.3: lit and heard now, a round trip before the host's
## word for it comes, which is then not shown again.
func ahead(slot: int) -> void:
	if _quiet_left > 0.0:
		return
	_quiet_left = REFIRE
	_ahead[slot] = Time.get_ticks_msec() + int(AHEAD_HOLD * 1000.0)
	Audio.ahead(&"bumper_kicked", [slot, index])
	light()


## Whether a shot may be bent toward this bumper, GAME.md 5.1: always, since it is never shot away
## and kicks every shot back, see [method Bullet.nearest_target] for how little it is worth.
func is_targetable() -> bool:
	return true


## Whether the cap is lit just now, for the tests.
func lit() -> bool:
	return _flash_left > 0.0


func _on_kicked(slot: int, which: int) -> void:
	if which != index:
		return
	if _ahead.get(slot, 0) > Time.get_ticks_msec():
		_ahead.erase(slot)
		return
	light()


## A shot landing on the bumper, which kicks it back, GAME.md 6.2, lights it and sounds it as a kart
## does, a little quieter, on every machine from the same word; at most once in [constant REFIRE],
## so a shot rattling round a three is a run of pops rather than a roar.
func _on_shot(at: Vector3, _normal: Vector3, _color: Color) -> void:
	if not is_inside_tree():
		return
	var flat := Vector2(at.x - global_position.x, at.z - global_position.z)
	if flat.length() > RADIUS + SHOT_REACH:
		return
	light()
	if _shot_quiet_left <= 0.0:
		_shot_quiet_left = REFIRE
		Audio.pop_bumper(SHOT_DB)


## Lights the cap, and a ring of light pops off the floor round it where there is a screen to
## see one.
func light() -> void:
	_flash_left = FLASH_TIME
	if is_inside_tree() and not Game.is_headless():
		var pop := SpawnRing.spawn(get_parent(), global_position, BULB)
		pop.scale = Vector3.ONE * 0.32


func _physics_process(delta: float) -> void:
	_quiet_left = maxf(_quiet_left - delta, 0.0)
	_shot_quiet_left = maxf(_shot_quiet_left - delta, 0.0)


func _process(delta: float) -> void:
	if _flash_left <= 0.0 and _look.scale == Vector3.ONE:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	var share := _flash_left / FLASH_TIME
	for i: int in _lamps.size():
		_lamps[i].emission_energy_multiplier = lerpf(_rest[i], FLASH_ENERGY, share * share)
	# The ring pulls down as it fires and the cap bobs with it, then both come back up.
	_look.scale = Vector3(1.0, 1.0 - 0.08 * sin(share * PI), 1.0)


## Gives every part named Lamp under [param node] a material of this bumper's own, so it lights
## alone.
func _own_lamps(node: Node) -> void:
	for child: Node in node.get_children():
		_own_lamps(child)
		var part := child as MeshInstance3D
		if part == null or not String(part.name).begins_with("Lamp"):
			continue
		var worn := part.material_override as StandardMaterial3D
		if worn == null:
			continue
		var own := worn.duplicate() as StandardMaterial3D
		own.emission_enabled = true
		part.material_override = own
		_lamps.append(own)
		_rest.append(own.emission_energy_multiplier)


## The plain bumper of a room with none of its own: a chrome body under a red cap with the bulb
## lit under its lens.
func _plain(surfaces: Surfaces) -> void:
	var chrome := surfaces.metal(CHROME)
	ToyParts.cylinder(_look, RADIUS * 0.96, 0.06, chrome, Vector3(0.0, 0.03, 0.0), 16)
	ToyParts.cylinder(_look, RADIUS * 0.6, 0.6, chrome, Vector3(0.0, 0.36, 0.0), 12)
	ToyParts.ring(_look, RADIUS * 0.6, RADIUS * 0.94, chrome, Vector3(0.0, 0.5, 0.0), 16, 4)
	ToyParts.cylinder(_look, RADIUS * 0.9, 0.18, surfaces.sheet(CAP), Vector3(0.0, 0.75, 0.0), 16)
	var lens := ToyParts.dome(
		_look, RADIUS * 0.74, 0.1, surfaces.neon(BULB, 0.3), Vector3.UP * 0.84
	)
	lens.name = "Lamp"
