class_name HighLimitStyle
extends RoomStyle
## High Limit, the showdown's own room, GAME.md 8.1c and 9.7a: the House's private table, where
## drivers level on points settle it and nobody's money is on the felt. After Hours is the House
## showing off at night; this is the House at its most exact, under one even lamp. The floor is a
## navy felt with the House's layout on it in platinum and ivory; a wall is a bolster of ivory
## leather on a black lacquer plinth, chrome piping where the two meet and its top rolled round; a
## box is a carton of the House's sealed decks in black card, its lid a little wider than it and an
## ivory band over the lid. So the table is navy, ivory and black, and the players' colors are the
## strongest things on it. Round the table, see [HighLimitSalon], a floor of polished smoky marble,
## and past its far side the House's pair on a black lacquer plinth: two aces fanned, which is what
## a tie is and what the SHOWDOWN plate is dressed in.
##
## The showdown's floor has no Junction, Jackpot, pit or turbo plate, GAME.md 6.3, so those are
## left to the room's kit. Few materials: everything plain in one paint with its colors on its
## vertices, the leather in a satin one and the chrome in a third, see [method Bake.tinted], so the
## walls draw in three meshes, a box in one and the room round the table in a handful, all on
## shaders the title's warm-up has compiled, GAME.md 10.7.

const SALON := "res://scenes/arena/styles/high_limit_salon.gd"

## The leather of the walls, a warm ivory a step down from white so it never glares under the
## lamp; the black lacquer under it and the chrome between them.
const IVORY := Color("#C4BAA9")
const LACQUER := Color("#18171C")
const CHROME := Color("#B9BEC6")
## The House's sealed decks: the black card of a carton, its lid a shade darker, and the band.
const CARTON_INK := Color("#26252B")
const CARTON_LID := Color("#1C1B20")
const BAND_INK := Color("#BFB4A2")
## The layout's inks, GAME.md 8.1b: platinum for the lines and ivory for the words, both a step
## down so the navy stays the quiet thing under the karts and gold stays the House's own.
const PLATINUM := Color("#959EAE")
const IVORY_WORD := Color("#D4CBB8")

## A wall's parts: the plinth's height, the piping on it and how far in it stands, how far in the
## leather stands from the plinth, how high its rolled top rises over it, how far the roll stops
## short of the leather's ends, how far two parts sink into each other, and how many sides the
## roll has.
const PLINTH := 0.12
const PIPING := 0.026
const PIPING_IN := 0.03
const INSET := 0.055
const CROWN := 0.2
const CROWN_SHORT := 0.012
const BITE := 0.01
const SIDES := 16
## A carton, as shares of the box's cube: how wide and how tall its body is, how wide and tall its
## lid, and how wide the band over the lid is and how thick.
const CARTON := 0.84
const CARTON_HIGH := 0.6
const LID_WIDE := 0.9
const LID_HIGH := 0.2
const BAND := 0.12
const BAND_THICK := 0.012
## How rough the marble round the table is: polished, not glass.
const MARBLE_ROUGH := 0.34

var _satin: StandardMaterial3D
var _marble: StandardMaterial3D


## A bolster the block the wall was: a black lacquer plinth the wall's whole footprint, chrome
## piping along its top, the ivory leather standing in from it and its top rolled round, so a run
## of wall reads as one long cushion.
func wall(holder: Node3D, size: Vector3, _index: int) -> bool:
	var foot := -size.y * 0.5
	tinted_box(holder, Vector3(size.x, PLINTH, size.z), LACQUER, _up(foot + PLINTH * 0.5))
	var piping := Vector3(size.x - PIPING_IN * 2.0, PIPING, size.z - PIPING_IN * 2.0)
	tinted_box(holder, piping, CHROME, _up(foot + PLINTH - BITE + PIPING * 0.5), true)
	var high := size.y - PLINTH - CROWN + BITE
	var body := Vector3(size.x - INSET * 2.0, high, size.z - INSET * 2.0)
	var middle := _up(foot + PLINTH - BITE + high * 0.5)
	_leather(holder, _box_mesh(body), Transform3D(Basis.IDENTITY, middle))
	_crown(holder, body, size.y * 0.5 - CROWN)
	return true


## A carton of the House's sealed decks standing in for the box, inside its cube: black card, a
## lid a little wider than it, and an ivory band over the lid and down its front and back, the
## seal on a box nobody has opened yet.
func crate(holder: Node3D, size: Vector3) -> bool:
	carton(holder, size, _up(-size.y * 0.5))
	holder.rotation.y = rng.randf_range(-0.05, 0.05)
	return true


## The room round the table, built by [HighLimitSalon]: the salon's walls and its marble, the
## House's pair past the far side between two lamps, and the few things set down about the table.
##
## The salon is asked for by its path as the room goes up rather than named here, as the
## Workbench's bench is, see [method WorkbenchStyle.room_round]: naming it and the room's parts it
## builds with would have this script wait on them as it compiles.
func room_round(props: RoomProps) -> bool:
	load(SALON).new(self, props).lay()
	return true


## The salon's marble round the table, in the room's own table color: the kit's stone, polished,
## so the lamp lies on it as on a floor somebody keeps, and the same shader as the kit's.
func surround() -> StandardMaterial3D:
	if _marble == null:
		_marble = surfaces._stone(room.table, MARBLE_ROUGH, true)
		_marble.metallic_specular = 0.6
	return _marble


## The House's layout in platinum and ivory, GAME.md 8.1b.
func layout_inks() -> Array[Color]:
	return [PLATINUM, IVORY_WORD]


# --- the parts ---------------------------------------------------------------


## A carton of sealed decks [param size] over all, standing on [param foot] under [param into]:
## the black body, the lid a little wider than it and the band over the lid and down its front
## and back, the band a share of the carton's width and as thin whatever its size.
func carton(into: Node3D, size: Vector3, foot: Vector3) -> void:
	var body := Vector3(size.x * CARTON, size.y * CARTON_HIGH, size.z * CARTON)
	tinted_box(into, body, CARTON_INK, foot + _up(body.y * 0.5))
	var lid := Vector3(size.x * LID_WIDE, size.y * LID_HIGH, size.z * LID_WIDE)
	var lid_at := body.y - BITE + lid.y * 0.5
	tinted_box(into, lid, CARTON_LID, foot + _up(lid_at))
	var wide := size.x * BAND
	var over := Vector3(wide, BAND_THICK, lid.z + BAND_THICK * 2.0)
	tinted_box(into, over, BAND_INK, foot + _up(lid_at + (lid.y + BAND_THICK) * 0.5))
	for side: float in [-1.0, 1.0]:
		var down := Vector3(wide, lid.y + BAND_THICK, BAND_THICK)
		var at := Vector3(0.0, lid_at + BAND_THICK * 0.5, side * (lid.z + BAND_THICK) * 0.5)
		tinted_box(into, down, BAND_INK, foot + at)


## The rolled top of a bolster whose leather is [param body], its middle [param at] up: a
## cylinder laid along the bolster and squashed so it rises [constant CROWN] over the leather, the
## lower half of it inside.
func _crown(holder: Node3D, body: Vector3, at: float) -> void:
	var roll := CylinderMesh.new()
	roll.top_radius = 0.5
	roll.bottom_radius = 0.5
	roll.height = 1.0
	roll.radial_segments = SIDES
	roll.rings = 1
	var long := maxf(body.x, body.z) - CROWN_SHORT * 2.0
	var across := minf(body.x, body.z) - BITE
	# The cylinder's own upright laid along the bolster's length, its round across and up.
	var shape := (
		Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3(CROWN * 2.0, long, across))
	)
	if body.z > body.x:
		shape = (
			Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(across, long, CROWN * 2.0))
		)
	_leather(holder, roll, Transform3D(shape, _up(at)))


## A piece of the leather, [param mesh] put where [param at] says, its shape baked into it so the
## satin lies on it the right way however it is squashed.
func _leather(into: Node3D, mesh: Mesh, at: Transform3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = Bake.tinted([[mesh, at, IVORY]])
	node.material_override = satin()
	into.add_child(node)
	return node


## The leather's look: the plain paint's, its colors off its vertices, with a satin sheen, so it is
## the same shader the warm-up has compiled for the paint and a material of its own only so the
## lamp lies on it softly.
func satin() -> StandardMaterial3D:
	if _satin == null:
		_satin = Bake.tinted_look(false).duplicate()
		_satin.roughness = 0.42
		_satin.metallic_specular = 0.55
	return _satin


## A box of [param size] in plain paint of [param ink] under [param into], or in chrome for
## [param metal]: its color on its vertices, so every one of them in the room bakes into one mesh,
## see [method Bake.tinted].
func tinted_box(
	into: Node3D, size: Vector3, ink: Color, at: Vector3, metal := false
) -> MeshInstance3D:
	return tinted(into, _box_mesh(size), ink, at, metal)


## An upright cylinder of [param radius] and [param height] in plain paint or chrome, [param sides]
## round, tapering to [param top] at its top when that is given.
func tinted_cylinder(
	into: Node3D,
	radius: float,
	height: float,
	ink: Color,
	at: Vector3,
	metal := false,
	sides := 12,
	top := -1.0
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0.0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return tinted(into, mesh, ink, at, metal)


## [param mesh] in plain paint of [param ink], or chrome, standing at [param at] under
## [param into].
func tinted(into: Node3D, mesh: Mesh, ink: Color, at: Vector3, metal := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = Bake.tinted([[mesh, Transform3D.IDENTITY, ink]])
	node.material_override = Bake.tinted_look(metal)
	node.position = at
	into.add_child(node)
	return node


func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


## The House's word on the front of the pair's plinth, STORY.md 6.1, in ivory leaf as the
## lettering on a private room's door is: under the aces where the shot a match opens on looks,
## GAME.md 8.2, see [HighLimitSalon].
func house_word(word: HouseWord, arena: Arena) -> bool:
	var half := arena.world_size() * 0.5
	var back := -(half.y + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL)
	var plinth: Vector3 = load("res://scenes/arena/styles/high_limit_salon.gd").PLINTH
	var at := Vector3(0.0, RoomBuild.TOP + plinth.y * 0.5, back + plinth.z * 0.5 + 0.01)
	word.lay(at, Vector2(plinth.x * 0.7, plinth.y * 0.6), IVORY_WORD, HouseWord.Medium.GILT)
	return true
