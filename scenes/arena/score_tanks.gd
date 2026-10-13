class_name ScoreTanks
extends Node3D
## The race to the target score, standing on the table at the far edge of the arena, GAME.md 8.1:
## a glass tank per player that fills with their own color as they bank, and is full at the
## score that wins the match; in team play a tank per team, GAME.md 3.14, full at the team's.
##
## The standings say who is ahead in numbers. This says how close anybody is to being done, which
## is a different question and the one that decides whether a pot is worth carrying another lap.
## A row of tanks answers it without being read: four a third full is a match with a way to go,
## one brimming is somebody about to take it.
##
## Scenery, like the crowd: no collision, nothing decided here. A room with no clock and nothing
## to reach has no tanks, since a tank that can never fill is furniture.

## How big one tank is and how far apart they stand, in meters.
const RADIUS := 0.45
const HEIGHT := 2.4
const SPACING := 1.7
## How far out from the arena wall the row stands: clear of it, and in front of the crowd. Along
## the edge it sits off to one side, because the middle of that edge is the DJ booth's and a row
## of tanks drawn over a row of speakers is neither.
const STANDOFF := 0.9
const OFFSET := 0.42
## How many tanks the row is drawn for, centered where [constant OFFSET] puts it. A room of more,
## GAME.md 9.3, grows the row away from the booth from where a row of this many ends.
const ROW := 4
## How far the cap sits above the top of the glass. It used to be sunk into it, which put the
## two flat faces in the same plane and ran the glass wall through the middle of the ring: from
## across the table that reads as the cap cutting into the tank. It still dips a hair below, so
## there is no daylight between them, and the ring is wider than the shell, so what overlaps is
## inside the cap rather than through it.
const CAP_LIFT := 0.05
## The glass, the dark of the base and cap, and how much of the tank the fluid can fill.
const GLASS := Color(0.80, 0.88, 0.96, 0.15)
const FITTING := Color(0.11, 0.11, 0.14)
const FLUID_INSET := 0.14
## How fast the level follows the score, and how far the surface rocks while it settles.
const SETTLE := 2.5
const WOBBLE := 0.018
const WOBBLE_RATE := 2.2

var match_node: Match

## One entry per slot: the fluid column to scale, and the level it is showing.
var _columns: Array[MeshInstance3D] = []
var _levels: PackedFloat32Array = []
var _built := 0
var _now := 0.0


## Hangs a row of tanks off [param for_match], to be filled in as its players bank.
static func add_to(for_match: Match) -> ScoreTanks:
	var tanks := ScoreTanks.new()
	tanks.name = "ScoreTanks"
	tanks.match_node = for_match
	for_match.add_child(tanks)
	return tanks


## Whether this room has anything for a tank to measure. A showdown has no score, only who is still
## in, which [ShowdownCards] stand up for in the tanks' place, GAME.md 9.7a.
func wanted() -> bool:
	return (
		match_node != null
		and match_node.rules != null
		and match_node.rules.timed
		and not match_node.rules.showdown()
	)


func _process(delta: float) -> void:
	visible = wanted()
	if not visible:
		return
	var sides := _sides()
	if sides.size() != _built:
		_rebuild(sides)
	_now += delta
	var blend := 1.0 - exp(-delta * SETTLE)
	for i: int in _columns.size():
		if i >= sides.size():
			continue
		_levels[i] = lerpf(_levels[i], sides[i][1], blend)
		_show(i, _levels[i])


## What each tank stands for, as its color and how full it should be: a player each, or in team
## play a team each, GAME.md 3.14, filling toward the team's target.
func _sides() -> Array:
	var rules := match_node.rules
	var target := maxf(float(rules.team_target()), 1.0)
	var result: Array = []
	if rules.teams > 0:
		for team: int in rules.teams:
			var bank := float(Teams.bank(match_node.slots, team))
			result.append([Teams.color(team), clampf(bank / target, 0.0, 1.0)])
		return result
	for slot: PlayerSlot in match_node.slots:
		result.append([slot.color(), clampf(float(slot.banked) / target, 0.0, 1.0)])
	return result


## Puts one column at its level. The surface rocks a little while it is moving and settles flat,
## so a tank being filled reads as liquid going in rather than as a bar being set.
func _show(index: int, level: float) -> void:
	var column := _columns[index]
	var moving := absf(level - _target_level(index))
	var rock := sin(_now * WOBBLE_RATE + index) * WOBBLE * clampf(moving * 12.0, 0.0, 1.0)
	var deep := maxf((level + rock) * (HEIGHT - FLUID_INSET * 2.0), 0.0)
	column.visible = deep > 0.001
	column.scale = Vector3(1.0, maxf(deep, 0.001), 1.0)
	column.position.y = FLUID_INSET + deep * 0.5


func _target_level(index: int) -> float:
	if match_node.rules == null:
		return _levels[index]
	var sides := _sides()
	return sides[index][1] if index < sides.size() else _levels[index]


## A tank for each of [param sides], in a row centered on the far edge of the arena. Rebuilt rather
## than added to when the table changes size, since that only happens between matches or as
## somebody joins.
func _rebuild(sides: Array) -> void:
	var count := sides.size()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_columns.clear()
	_levels.resize(count)
	_levels.fill(0.0)
	_built = count
	if count <= 0:
		return
	var size := match_node.arena.world_size() if match_node.arena != null else Vector2(40.0, 22.5)
	var row := -(size.y * 0.5 + STANDOFF + RADIUS)
	var along := -size.x * OFFSET * 0.5
	var spacing := SPACING
	if count > ROW:
		# Away from the booth rather than into it, GAME.md 8.1, closing up only where the row
		# would otherwise run past the corner of the table.
		var near := along + (ROW - 1) * 0.5 * SPACING
		var far := -size.x * 0.5 + RADIUS
		spacing = minf(SPACING, (near - far) / float(count - 1))
		along = near - (count - 1) * 0.5 * spacing
	var glass := _glass()
	var fitting := _paint(FITTING)
	for i: int in count:
		var at := Vector3(along + (i - (count - 1) * 0.5) * spacing, 0.0, row)
		_columns.append(_tank(at, sides[i][0], glass, fitting))
	# The feet, caps and glass of every tank are baked into one mesh a material, GAME.md 10.7.
	# Each fluid column and each color band wears a material of its own, so they stay as they
	# are, and the columns go on being moved by [method _show].
	Bake.merge(self)
	# Nobody stands in front of them, GAME.md 8.1: a crowd in front of a thing put there to be
	# looked at is worse than a slightly smaller crowd.
	if match_node.arena != null and match_node.arena.crowd != null:
		# A bay rather than a gap, and over the tanks rather than over the middle of the edge:
		# the band is four rows deep and the tanks are only waist high to this camera, so
		# clearing the one row they stand in leaves the three behind them looking like a queue.
		var run := count * spacing + RADIUS * 2.0
		match_node.arena.crowd.keep_clear(Rect2(along - run * 0.5, row - 2.6, run, 4.0))


## One tank: a dark foot, a glass tube standing on it, a cap, and the column of fluid inside that
## the rest of this class moves.
func _tank(at: Vector3, color: Color, glass: Material, fitting: Material) -> MeshInstance3D:
	var tank := Node3D.new()
	tank.name = "Tank"
	tank.position = at
	add_child(tank)
	for foot: bool in [true, false]:
		var ring := _tube(RADIUS * 1.16, 0.12, fitting)
		ring.position.y = 0.06 if foot else HEIGHT + CAP_LIFT
		tank.add_child(ring)
	# The player's own color on the foot, so an empty tank still says whose it is.
	var band := _tube(RADIUS * 1.22, 0.07, _paint(color))
	band.position.y = 0.155
	tank.add_child(band)
	var shell := _tube(RADIUS, HEIGHT, glass)
	shell.position.y = HEIGHT * 0.5
	tank.add_child(shell)
	var fluid := _tube(RADIUS - 0.05, 1.0, _fluid(color))
	fluid.visible = false
	tank.add_child(fluid)
	return fluid


static func _tube(radius: float, height: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	node.mesh = mesh
	node.material_override = material
	return node


static func _glass() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = GLASS
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.12
	material.metallic = 0.1
	return material


## The fluid glows a little on its own, so a tank reads at a glance rather than only when the
## lights are pointing at it.
static func _fluid(color: Color) -> StandardMaterial3D:
	var material := _paint(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.55
	return material


static func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
