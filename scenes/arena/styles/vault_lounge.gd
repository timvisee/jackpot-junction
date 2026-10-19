class_name VaultLounge
extends RefCounted
## The House's glamour room round its table, GAME.md 8.1 and STORY.md 3.9, for [VaultStyle]: the
## walls of a dark room, the title's gilded sunburst over the back one and again on a stand just
## past the crowd, the pictures either side of the House's poster, the rope line's brass stanchions
## behind the crowd, two deco lamps hung over the far side, and the things the House keeps for show
## squared off on the black lacquer: stacks of catalin chips in the room's colors and never the
## coins' blue, sealed decks with the House's seal on them, coupes of champagne, dice, and a hand
## fanned out on the near side. Dealt the way every room deals, so it gets one of everything before
## it gets two of anything, and kept few, so the table is still the thing in the room.

const GLASS := Color("#CAD3DA")
const CHAMPAGNE := Color("#D9B866")
## The colors the House's chips come in here, none of them the coins' blue.
const CHIPS: Array[Color] = [
	VaultStyle.CHERRY, VaultStyle.BUTTERSCOTCH, VaultStyle.JADE, VaultStyle.CREAM, Color("#1E1B21")
]

var style: VaultStyle
var props: RoomProps


func _init(for_style: VaultStyle, into: RoomProps) -> void:
	style = for_style
	props = into


## Builds the room, hangs the lamps and deals the rest.
func lay() -> void:
	var shell := props.shell
	var wall := shell.enclose(Color(0.06, 0.04, 0.06), Color(0.13, 0.06, 0.09), 32.0, 80.0)
	# One over the whole of the back wall behind the House's poster, and one standing just past the
	# crowd where the camera reaches further than the wall, low enough to leave the poster in sight
	# from over the table.
	var face := wall + RoomBuild.WALL_THICKNESS * 0.5
	_sunburst(shell, Vector3(0.0, RoomBuild.TOP + 1.0, face), 36.0, false)
	var back := props.arena.world_size().y * 0.5 + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL
	_sunburst(shell, Vector3(0.0, RoomBuild.TOP + 1.0, -back), 5.4, true)
	shell.pictures(wall)
	shell.skirt(style.room.table.darkened(0.2), 2.4)
	shell.legs(style.room.table.darkened(0.3))
	shell.rope_line()
	var half := props.arena.world_size() * 0.5
	for side: float in [-1.0, 1.0]:
		props._lay(
			&"pendant",
			Vector3(side * half.x * 0.62, RoomBuild.TOP, -(half.y + 10.0)),
			func(at: Vector3, _turn: float) -> void: _pendant(at),
			true
		)
	props._ring(
		12,
		{&"chips": _chips, &"deck": _decks, &"glass": _coupe, &"dice": props._dice},
		{&"chips": _chips, &"deck": _decks}
	)
	props._apron(4, {&"cards": props._fanned_cards, &"dice": props._dice})


## The gilded sunburst, the title's own, rising [param radius] high from [param foot] in front of
## a wall facing the table: rays of foil round a half sun with nothing between them, lit a little
## from inside so it glows in the dark room and the bloom takes it, on a step of black lacquer with
## a brass line along its nose. With [param backed] a half disc of black lacquer stands behind the
## rays, for one that stands out in the room rather than against a wall.
func _sunburst(shell: RoomShell, foot: Vector3, radius: float, backed: bool) -> void:
	var fan := QuadMesh.new()
	fan.size = Vector2(radius * 2.0, radius)
	shell._dim(shell._put(fan, style.gilt(), foot + Vector3(0.0, radius * 0.5, 0.3)))
	if backed:
		var disc := shell._cylinder(radius * 1.03, 0.2, style.lacquer(), foot)
		disc.rotation.x = PI * 0.5
		(disc.mesh as CylinderMesh).radial_segments = 48
		shell._dim(disc)
	var wide := radius * 2.0 + 1.2
	# The step's back stands at the foot, against whatever the sunburst stands in front of, rather
	# than sunk the better part of a meter into the wall behind it.
	var step := shell._box(Vector3(wide, 1.0, 1.8), style.lacquer(), foot + Vector3(0.0, -0.5, 0.9))
	shell._dim(step)
	var nose := foot + Vector3(0.0, 0.0, 1.8)
	shell._dim(shell._box(Vector3(wide, 0.16, 0.16), style.metal(VaultStyle.BRASS), nose))
	shell._keep(foot - Vector3(wide * 0.5, 0.0, 0.0), foot + Vector3(wide * 0.5, 0.0, 0.0), 3.0)


## A deco lamp hung over the far side of the table: a brass rod, a shade stepping up like a
## ziggurat with a black band round its rim, and the bulb's glow under it. Dressing rather than
## light: the room's one lamp is the one over the table.
func _pendant(at: Vector3) -> void:
	var brass := style.metal(VaultStyle.BRASS)
	var high := 11.0
	props._cylinder(0.2, 14.0, brass, at + Vector3(0.0, high + 8.4, 0.0))
	var tiers: Array[float] = [4.0, 3.0, 1.9]
	for i: int in tiers.size():
		props._cylinder(tiers[i], 0.7, brass, at + Vector3(0.0, high + 0.35 + 0.7 * float(i), 0.0))
	props._cylinder(4.06, 0.22, style.lacquer(), at + Vector3(0.0, high + 0.1, 0.0))
	props._cylinder(
		3.6, 0.3, style.neon(props.room.lamp_color, 0.45), at + Vector3(0, high - 0.2, 0)
	)


## Three stacks of chips squared off in a row, each one color, the way a dealer leaves them.
func _chips(at: Vector3, turn: float) -> void:
	var side := Vector3(cos(turn), 0.0, -sin(turn))
	for stack: int in 3:
		var ink: Color = CHIPS[props._rng.randi_range(0, CHIPS.size() - 1)]
		var foot := at + side * (float(stack) - 1.0) * 2.3
		for i: int in props._rng.randi_range(4, 10):
			props._cylinder(1.0, 0.27, style.chip(ink), foot + Vector3(0.0, 0.14 + 0.28 * i, 0.0))


## A deck or three in black lacquer, sealed: a cream band round each and the House's gold seal on
## its top, squared up on each other.
func _decks(at: Vector3, turn: float) -> void:
	var black := style.lacquer()
	var band := style.catalin(VaultStyle.CREAM)
	var seal := style.metal(VaultStyle.BRASS)
	for i: int in props._rng.randi_range(1, 3):
		var lift := Vector3(0.0, 0.4 + float(i) * 0.82, 0.0)
		var twist := turn + props._rng.randf_range(-0.06, 0.06)
		props._turned(props._box(Vector3(2.4, 0.8, 3.4), black, at + lift), twist)
		props._turned(props._box(Vector3(2.44, 0.82, 0.5), band, at + lift), twist)
		props._cylinder(0.36, 0.06, seal, at + lift + Vector3(0.0, 0.42, 0.0))


## A coupe of champagne: a foot, a stem and a shallow bowl with the gold of the wine in it.
func _coupe(at: Vector3, _turn: float) -> void:
	var glass := style.catalin(GLASS)
	props._cylinder(1.0, 0.12, glass, at + Vector3(0.0, 0.06, 0.0))
	props._cylinder(0.12, 2.0, glass, at + Vector3(0.0, 1.1, 0.0))
	props._taper(0.5, 1.25, 0.8, glass, at + Vector3(0.0, 2.5, 0.0))
	props._cylinder(1.15, 0.06, style.catalin(CHAMPAGNE), at + Vector3(0.0, 2.84, 0.0))
