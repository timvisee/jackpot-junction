class_name HighLimitSalon
extends RefCounted
## The House's private salon round the showdown's table, GAME.md 8.1c and 9.7a, for
## [HighLimitStyle]: a polished floor of smoky marble the crowd stands on, its edge a step of
## black lacquer under a chrome nosing, and plain walls far enough off that the table is still the
## thing in the room. Past the far side, where the opening shot of every match looks, the House's
## pair stands on a black lacquer plinth: an ace of spades and an ace of hearts fanned, a tie, the
## cards the SHOWDOWN plate is dressed in, with a torchère either side of it lit into its bowl.
## Round the rest of the table, few things and each put down by hand: stacks of the House's sealed
## decks, the boxes' cartons, and on the near side a hand laid down face down, flat. No chips
## anywhere: there is no money in this room.
##
## Built through the room's [RoomProps] and its [RoomShell], so it is baked with them, in the
## style's one plain paint and its chrome, see [method HighLimitStyle.tinted_box], and the cards'
## own printed faces.

const TOP := RoomBuild.TOP
## The salon's floor under the dais the table is, how far down it is, and its walls.
const FLOOR := Color("#5E5953")
const WALLS := Color("#4C4844")
const DROP := 1.4
const HEIGHT := 60.0
## The nosing round the dais's edge: how thick, and how far out from the top it stands.
const NOSING := 0.3
## The pair: how big a card is, how thick, how far each is fanned out from upright and how far
## both lean back; how far apart their feet stand; the plinth under them; and the tint their faces
## are printed in, a step down from the paper so the pair never glares in the lamp.
const CARD := Vector2(4.4, 6.1)
const CARD_THICK := 0.14
const FAN := 0.2
const LEAN := 0.14
const FEET := 0.8
const PLINTH := Vector3(9.6, 1.2, 3.2)
const FACE_TINT := Color(0.96, 0.95, 0.92)
## The torchères: how far out from the pair's middle each stands and how far behind it, kept out
## of the top of the picture the match is played in, its height and the bowl on it.
const LAMP_OUT := 8.4
const LAMP_BACK := 3.0
const LAMP_HIGH := 7.6
const BOWL := 1.3
## A carton in a stack of the House's decks, and how far each is turned on the one under it.
const DECKS := Vector3(2.2, 1.0, 3.0)
const TWISTS: Array[float] = [0.0, 0.1, -0.05]

var style: HighLimitStyle
var props: RoomProps
var shell: RoomShell
var half: Vector2


func _init(for_style: HighLimitStyle, into: RoomProps) -> void:
	style = for_style
	props = into
	shell = into.shell
	half = into.arena.world_size() * 0.5


## Builds the salon and puts everything down in it.
func lay() -> void:
	shell.enclose(FLOOR, WALLS, DROP, HEIGHT)
	shell.skirt(HighLimitStyle.LACQUER, DROP)
	_nosing()
	var back := -(half.y + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL)
	_pair(Vector3(0.0, TOP, back))
	for side: float in [-1.0, 1.0]:
		_torchere(Vector3(side * LAMP_OUT, TOP, back - LAMP_BACK))
	_set_out()


# --- the room ----------------------------------------------------------------


## A chrome nosing round the top of the dais's edge, over its black lacquer step.
func _nosing() -> void:
	var table := props._table()
	for side: int in 4:
		var along := side % 2 == 0
		var out := 1.0 if side < 2 else -1.0
		var run := Vector3(table.x * 2.0, NOSING, NOSING)
		var at := Vector3(0.0, TOP - NOSING * 0.5 + 0.02, out * (table.y - NOSING * 0.5))
		if not along:
			run = Vector3(NOSING, NOSING, table.y * 2.0)
			at = Vector3(out * (table.x - NOSING * 0.5), at.y, 0.0)
		_dim(style.tinted_box(shell, run, HighLimitStyle.CHROME, at, true))


## The House's pair standing on [param foot], facing the table: the plinth of black lacquer with a
## chrome nosing along its front, and on it the ace of spades and the ace of hearts fanned out
## from feet a little apart, the heart in front, both leaning back a little toward the far wall.
func _pair(foot: Vector3) -> void:
	_dim(style.tinted_box(shell, PLINTH, HighLimitStyle.LACQUER, foot + _up(PLINTH.y * 0.5)))
	var nose := foot + Vector3(0.0, PLINTH.y - 0.08, PLINTH.z * 0.5)
	var lip := Vector3(PLINTH.x + 0.1, 0.16, 0.16)
	_dim(style.tinted_box(shell, lip, HighLimitStyle.CHROME, nose, true))
	var faces: Array[Texture2D] = [Surfaces.CARD_FACES[2], Surfaces.CARD_FACES[0]]
	for i: int in 2:
		var side := -1.0 if i == 0 else 1.0
		var turn := Basis.from_euler(Vector3(-LEAN, 0.0, -side * FAN))
		var pivot := foot + Vector3(side * FEET * 0.5, PLINTH.y, -0.3 + 0.32 * float(i))
		var middle := pivot + turn * _up(CARD.y * 0.5)
		var slab := Vector3(CARD.x, CARD.y, CARD_THICK)
		var card := _dim(style.tinted_box(shell, slab, HighLimitStyle.BAND_INK, middle))
		card.basis = turn
		var picture := QuadMesh.new()
		picture.size = CARD - Vector2.ONE * 0.08
		var front := middle + turn * Vector3(0.0, 0.0, CARD_THICK * 0.5 + 0.01)
		var face := _dim(shell._put(picture, style.surfaces.printed(faces[i], FACE_TINT), front))
		face.basis = turn
	var wide := PLINTH.x + 1.0
	shell._keep(foot - Vector3(wide * 0.5, 0.0, 0.0), foot + Vector3(wide * 0.5, 0.0, 0.0), 4.0)


## A torchère standing at [param at]: a lacquer foot, a chrome stem and an ivory bowl on top of it,
## lit inside, the light thrown up the wall rather than onto the table.
func _torchere(at: Vector3) -> void:
	var chrome := HighLimitStyle.CHROME
	_dim(style.tinted_cylinder(shell, 0.9, 0.24, HighLimitStyle.LACQUER, at + _up(0.12), false, 16))
	_dim(style.tinted_cylinder(shell, 0.11, LAMP_HIGH, chrome, at + _up(LAMP_HIGH * 0.5), true))
	var bowl := at + _up(LAMP_HIGH + 0.5)
	var ivory := HighLimitStyle.IVORY
	_dim(style.tinted_cylinder(shell, BOWL * 0.55, 1.0, ivory, bowl, false, 16, BOWL))
	var lit := style.surfaces.neon(props.room.lamp_color, 0.6)
	_dim(shell._cylinder(BOWL * 0.92, 0.06, lit, bowl + _up(0.42)))
	shell._keep(at - Vector3(1.4, 0.0, 0.0), at + Vector3(1.4, 0.0, 0.0), 3.0)


# --- what is set down about the table ----------------------------------------


## The few things the salon has set out, each on a spot of its own: stacks of the House's sealed
## decks either side of the back and down each flank, and a hand laid down on the near side.
func _set_out() -> void:
	var back := -(half.y + 10.0)
	var out := half.x + 11.0
	_put_down(&"deck", [Vector3(-12.0, TOP, back), Vector3(-14.0, TOP, back)], _decks.bind(3))
	_put_down(&"deck", [Vector3(12.0, TOP, back), Vector3(14.0, TOP, back)], _decks.bind(2))
	var left := [Vector3(-out, TOP, -half.y * 0.4), Vector3(-out, TOP, 0.0)]
	_put_down(&"deck", left, _decks.bind(2))
	var right := [Vector3(out, TOP, -half.y * 0.7), Vector3(out, TOP, -half.y * 0.3)]
	_put_down(&"deck", right, _decks.bind(2))
	_put_down(&"cards", [Vector3(-half.x * 0.4, TOP, half.y + 11.5)], _hand)


## Puts a [param kind] down at the first of [param spots] that is free, trying each a few times,
## since the turn of a patch is rolled anew every time, and turns what [param build] built there
## about its upright the way the patch was turned, so it stays on its patch.
func _put_down(kind: StringName, spots: Array, build: Callable) -> void:
	var turned := func(at: Vector3, turn: float) -> void:
		var from := props.get_child_count()
		build.call(at, turn)
		for i: int in range(from, props.get_child_count()):
			var part := props.get_child(i) as Node3D
			part.position = at + (part.position - at).rotated(Vector3.UP, turn)
			part.rotate_y(turn)
	for spot: Vector3 in spots:
		for attempt: int in 8:
			if props._lay(kind, spot, turned):
				return


## The House's sealed decks, [param count] cartons stacked, each a little turned on the one under
## it.
func _decks(at: Vector3, _turn: float, count: int) -> void:
	var high := DECKS.y * (HighLimitStyle.CARTON_HIGH + HighLimitStyle.LID_HIGH - 0.02)
	for k: int in count:
		var from := props.get_child_count()
		style.carton(props, DECKS, at + _up(high * float(k)))
		var twist: float = TWISTS[k % TWISTS.size()]
		for i: int in range(from, props.get_child_count()):
			var part := props.get_child(i) as Node3D
			part.position = at + (part.position - at).rotated(Vector3.UP, twist)
			part.rotate_y(twist)


## A hand laid down on the near side, flat: two cards face down, the top one a little turned.
func _hand(at: Vector3, _turn: float) -> void:
	var back := style.surfaces.printed(Surfaces.card_back(), Color(0.86, 0.84, 0.82))
	for i: int in 2:
		var card := PlaneMesh.new()
		card.size = Vector2(2.6, 3.6)
		var lying := props._put(card, back, at + _up(0.03 + float(i) * 0.04))
		lying.rotation.y = float(i) * 0.3
		lying.position += Vector3(sin(lying.rotation.y), 0.0, cos(lying.rotation.y)) * 0.5


# --- the parts ---------------------------------------------------------------


## Lies flat or stands far off: casts no shadow, see [method RoomBuild._dim].
func _dim(node: MeshInstance3D) -> MeshInstance3D:
	return shell._dim(node)


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)
