class_name PinballMachine
extends RefCounted
## The Arcade's machine round its table, GAME.md 8.1c, for [PinballStyle]: the rest of the pinball
## machine whose playfield the table is, where the camera over the table sees it. Below the near
## rail, where a player would stand at the machine, its flippers lie either side of the drain with
## a ball waiting between them and a slingshot over each; past the far rail on the right are its
## top lanes, where a ball comes in; and down the right flank runs the shooter lane, a ball in it
## and the plunger's knob out past the near corner. The crowd stands back from all three. Behind
## the far crowd is the machine's head with its backglass lit, and round the rest of the table lie
## a pinball's spares. None of it collides, and nothing on the near side stands up.
##
## Loaded by path when the table goes up, as [VaultLounge] is, so loading the room does not
## compile its props.

const SQUARE := RoomBuild.Turned.SQUARE
const FLAT := RoomBuild.Turned.FLAT
const TOP := RoomBuild.TOP
## The flippers: where a pivot stands, across from the middle and out from the near rail; how
## far its tip is from it and how it is angled down to the drain; how wide the bat is at either
## end and how tall it stands.
const PIVOT := Vector2(3.6, 2.3)
const BAT := 2.5
const BAT_TURN := 0.44
const BAT_WIDE := 0.45
const BAT_NARROW := 0.2
const BAT_TALL := 0.42
## A slingshot over each flipper, by its corners out from the near rail: the top, the foot on the
## outside and the foot over the flipper.
const SLING: Array[Vector2] = [Vector2(6.3, 0.4), Vector2(6.3, 2.0), Vector2(4.65, 2.75)]
const SLING_TALL := 0.5
## The top lanes: where the first guide stands, along the far edge and out past it; how many
## lanes there are and how wide, and how wide and long a guide between them is.
const LANES := Vector2(0.58, 1.6)
const LANES_ACROSS := 3
const LANE_GAP := 1.2
const GUIDE_WIDE := 0.36
const GUIDE_LONG := 2.4
## The shooter lane: how far down the right flank it runs from the near corner, and how wide.
const LANE := 8.0
const LANE_WIDE := 0.8

var style: PinballStyle
var props: RoomProps


func _init(for_style: PinballStyle, into: RoomProps) -> void:
	style = for_style
	props = into


## Builds the room round the table, the machine first and the spares after it, so they keep off
## what the machine stands on.
func lay() -> void:
	var arena := props.arena
	var shell := props.shell
	shell.enclose(Color("#0E0A10"), Color("#1A1220"), 32.0, 80.0)
	shell.skirt(PinballStyle.WALNUT.darkened(0.25), 2.4)
	shell.legs(Color("#8E929A"))
	var half := arena.world_size() * 0.5
	var back := -(half.y + RoomBuild.BACK_FAR + RoomBuild.BACK_WALL)
	_backbox(shell, arena, Vector3(0.0, TOP, back))
	_side_rails(shell)
	_flippers(half)
	_top_lanes(half)
	_shooter_lane(half)
	var balls := [Rect2(-2.5, -1.0, 5.0, 2.0), SQUARE, _balls]
	var rubbers := [Rect2(-1.6, -1.6, 3.2, 3.2), FLAT, _rubbers]
	var near := {
		&"balls": balls,
		&"rubbers": rubbers,
		&"bulbs": [Rect2(-2.5, -1.0, 5.0, 2.0), SQUARE, _bulbs],
		&"quarters": [Rect2(-2.1, -0.8, 4.2, 1.6), SQUARE, _quarters],
	}
	var far := {
		&"targets": [Rect2(-2.8, -1.0, 5.6, 2.0), SQUARE, _targets],
		&"balls": balls,
	}
	ToyParts.deal_round(props, 14, near, far)
	var card := [Rect2(-3.2, -2.0, 6.4, 4.0), RoomBuild.Turned.ALONG, _card]
	ToyParts.deal_apron(props, 4, {&"card": card, &"rubbers": rubbers})


# --- the machine ------------------------------------------------------------------


## The foot of the playfield below the near rail: a flipper either side of the drain, angled down
## to it, an ivory bat in red rubber on a chrome pivot; a slingshot over each, a lacquered
## triangle in cream rubber on three posts under a plastic; and a ball resting in the drain.
func _flippers(half: Vector2) -> void:
	var near := half.y
	var bay := Rect2(-(PIVOT.x + 3.6), near, (PIVOT.x + 3.6) * 2.0, 6.5)
	_keep_clear(bay)
	var what := [Rect2(bay.position.x, -0.5, bay.size.x, 4.6), FLAT, _foot.bind(near)]
	ToyParts.lay(props, &"flippers", what, Vector3(0.0, TOP, near + 0.5), true)


func _foot(_at: Vector3, _turn: float, near: float) -> void:
	_panel(Rect2(-(PIVOT.x + 3.4), near + 0.02, (PIVOT.x + 3.4) * 2.0, 4.5))
	for side: float in [-1.0, 1.0]:
		var pivot := Vector2(-PIVOT.x * side, near + PIVOT.y)
		var tip := pivot + Vector2(side * cos(BAT_TURN), sin(BAT_TURN)) * BAT
		var rubber := ToyParts.bat(pivot, tip, BAT_WIDE + 0.06, BAT_NARROW + 0.06)
		ToyParts.slab(props, rubber, 0.16, style._rubber(PinballStyle.RED_RUBBER), _up(TOP + 0.05))
		var bat := ToyParts.bat(pivot, tip, BAT_WIDE, BAT_NARROW)
		ToyParts.slab(props, bat, BAT_TALL, style._satin(PinballStyle.IVORY), _up(TOP))
		var nut := Vector3(pivot.x, TOP + BAT_TALL + 0.03, pivot.y)
		ToyParts.cylinder(props, 0.17, 0.06, style._steel(), nut, 10)
		_sling(side, near)
	var drain := Vector3(0.0, TOP + PinballStyle.BALL * 0.5, near + PIVOT.y + 1.45)
	ToyParts.ball(props, PinballStyle.BALL * 0.5, style._chrome(), drain, 12)


## The slingshot over the flipper on [param side].
func _sling(side: float, near: float) -> void:
	var corners := PackedVector2Array()
	for corner: Vector2 in SLING:
		corners.append(Vector2(-corner.x * side, near + corner.y))
	var middle := (corners[0] + corners[1] + corners[2]) / 3.0
	var ring := PackedVector2Array()
	var body := PackedVector2Array()
	for corner: Vector2 in corners:
		ring.append(middle + (corner - middle) * 1.12)
		body.append(middle + (corner - middle) * 0.86)
	var lacquer := style._satin(PinballStyle.LACQUER)
	ToyParts.slab(props, body, SLING_TALL, lacquer, _up(TOP))
	ToyParts.slab(props, ring, 0.16, style._rubber(PinballStyle.RUBBER), _up(TOP + 0.12))
	var plastic := style._satin(PinballStyle.PLASTIC, 0.3)
	ToyParts.flat(ToyParts.slab(props, corners, 0.035, plastic, _up(TOP + SLING_TALL)))
	var face := PackedVector2Array()
	for corner: Vector2 in corners:
		face.append(middle + (corner - middle) * 0.78)
	var panel := style._satin(PinballStyle.PANEL, 0.3)
	ToyParts.flat(ToyParts.slab(props, face, 0.01, panel, _up(TOP + SLING_TALL + 0.035)))
	for corner: Vector2 in ring:
		var post := Vector3(corner.x, TOP + (SLING_TALL + 0.06) * 0.5, corner.y)
		ToyParts.cylinder(props, 0.08, SLING_TALL + 0.06, style._steel(), post, 8)


## The top lanes past the far rail on the right, where a machine's playfield begins: short guides
## in cream rubber on chrome posts under their plastics, with a rollover insert in each lane
## between them, the middle one lit, on a piece of the playfield, the crowd standing back.
func _top_lanes(half: Vector2) -> void:
	var first := Vector2(half.x * LANES.x, -(half.y + LANES.y))
	var pitch := LANE_GAP + GUIDE_WIDE
	var guides := LANES_ACROSS + 1
	var run := pitch * float(LANES_ACROSS) + GUIDE_WIDE
	var box := Rect2(first - Vector2(0.0, GUIDE_LONG), Vector2(run, GUIDE_LONG)).grow(0.5)
	_keep_clear(box.grow(0.8))
	var middle := box.get_center()
	var patch := Rect2(box.position - middle, box.size)
	var build := func(_at: Vector3, _turn: float) -> void:
		_panel(box)
		for i: int in guides:
			var x := first.x + GUIDE_WIDE * 0.5 + pitch * float(i)
			_lane_guide(Vector3(x, TOP, first.y - GUIDE_LONG * 0.5))
		for i: int in LANES_ACROSS:
			var x := first.x + GUIDE_WIDE + LANE_GAP * 0.5 + pitch * float(i)
			var lit := (
				style._lamp(PinballStyle.BULB, 0.5)
				if i == LANES_ACROSS / 2
				else style._satin(PinballStyle.OCHRE.darkened(0.45), 0.3)
			)
			var insert := Vector3(x, TOP + 0.015, first.y - GUIDE_LONG * 0.5)
			ToyParts.flat(ToyParts.cylinder(props, LANE_GAP * 0.3, 0.012, lit, insert, 16))
	ToyParts.lay(props, &"lanes", [patch, FLAT, build], Vector3(middle.x, TOP, middle.y), true)


## One of the top lanes' guides, its middle at [param at], running from the far rail out.
func _lane_guide(at: Vector3) -> void:
	var tall := 0.5
	var lacquer := style._satin(PinballStyle.LACQUER)
	var body := Vector3(GUIDE_WIDE * 0.6, tall, GUIDE_LONG - GUIDE_WIDE * 0.4)
	ToyParts.box(props, body, lacquer, at + _up(tall * 0.5))
	var rubber := Vector3(GUIDE_WIDE, 0.14, GUIDE_LONG)
	var ring := style._rubber(PinballStyle.RUBBER)
	ToyParts.rounded(props, rubber, GUIDE_WIDE * 0.5, ring, at + _up(0.24), 8)
	var plastic := Vector3(GUIDE_WIDE * 0.9, 0.035, GUIDE_LONG - 0.1)
	ToyParts.box(props, plastic, style._satin(PinballStyle.PLASTIC, 0.3), at + _up(tall + 0.02))
	for end: float in [-1.0, 1.0]:
		var post := at + Vector3(0.0, 0.0, end * (GUIDE_LONG * 0.5 - GUIDE_WIDE * 0.5))
		ToyParts.cylinder(
			props, 0.08, tall + 0.08, style._steel(), post + _up((tall + 0.08) * 0.5), 8
		)


## The foot of the shooter lane, down the right flank to the near corner: two steel rails, a ball
## in the lane and the plunger behind it, its spring, its rod and its red knob out past the corner.
func _shooter_lane(half: Vector2) -> void:
	var x := half.x + LANE_WIDE * 0.5 + 0.1
	var foot := half.y + 1.2
	var lane := Rect2(half.x, foot - LANE, LANE_WIDE + 0.4, LANE + 3.0)
	_keep_clear(lane)
	var middle := lane.get_center()
	var patch := Rect2(lane.position - middle, lane.size)
	var build := func(_at: Vector3, _turn: float) -> void:
		for side: float in [-1.0, 1.0]:
			var rail := Vector3(x + side * LANE_WIDE * 0.5, TOP + 0.08, foot - LANE * 0.5)
			ToyParts.box(props, Vector3(0.08, 0.16, LANE), style._steel(), rail)
		var ball := PinballStyle.BALL * 0.5
		ToyParts.ball(props, ball, style._chrome(), Vector3(x, TOP + ball, foot - ball - 0.3), 12)
		var tip := ToyParts.cylinder(
			props, 0.2, 0.3, style._rubber(PinballStyle.RUBBER), Vector3(x, TOP + ball, foot), 10
		)
		tip.rotation.x = PI * 0.5
		var spring := ToyParts.cylinder(
			props, 0.16, 0.9, style._steel(), Vector3(x, TOP + ball, foot + 0.6), 8
		)
		spring.rotation.x = PI * 0.5
		var rod := ToyParts.cylinder(
			props, 0.07, 1.6, style._chrome(), Vector3(x, TOP + ball, foot + 1.6), 8
		)
		rod.rotation.x = PI * 0.5
		var knob := Vector3(x, TOP + ball, foot + 2.5)
		ToyParts.ball(props, 0.3, style._rubber(PinballStyle.RED_RUBBER), knob, 12)
	ToyParts.lay(props, &"shooter", [patch, FLAT, build], Vector3(middle.x, TOP, middle.y), true)


## A piece of the playfield lying on the table over [param area], under a part of the machine that
## stands past the rail, lit from under as the field is, so the part is seen to be the machine's.
func _panel(area: Rect2) -> void:
	var lit := StandardMaterial3D.new()
	lit.albedo_color = PinballPrints.GROUND
	# The playfield's satin coat, as the table's, see [method PinballStyle.floor_top].
	lit.roughness = 0.64
	lit.metallic_specular = 0.38
	var face := PlaneMesh.new()
	face.size = area.size
	var middle := area.get_center()
	ToyParts.flat(ToyParts.put(props, face, lit, Vector3(middle.x, TOP + 0.006, middle.y)))
	DrawnTexture.kept(
		props.arena,
		PinballPrints.panel(),
		Vector2i(area.size * PinballPrints.PANEL_PIXELS),
		func(texture: Texture2D) -> void:
			lit.albedo_color = Color.WHITE
			lit.albedo_texture = texture
			lit.emission_enabled = true
			lit.emission = PinballPrints.COAT_GLOW
			lit.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			lit.emission_texture = texture
			lit.emission_energy_multiplier = PinballStyle.FIELD_GLOW,
		LayoutPrint.SMOOTH
	)


## Asks the crowd to stand back from [param area] of the table, as it does from the tanks and the
## hoardings, so nobody stands in the machine.
func _keep_clear(area: Rect2) -> void:
	if props.arena.crowd != null:
		props.arena.crowd.keep_clear(area)


# --- the room round the table ---------------------------------------------------------


## The machine's head: a walnut box standing on the table behind the far crowd, chrome round its
## glass and the backglass lit from behind. Part of the room rather than its clutter, as the
## Workbench's board is, so what is dealt round the table keeps off its patch.
func _backbox(shell: RoomShell, arena: Arena, at: Vector3) -> void:
	var wide := 40.0
	var tall := 25.0
	var deep := 4.0
	shell._keep(at - Vector3(wide * 0.5, 0.0, 0.0), at + Vector3(wide * 0.5, 0.0, 0.0), deep + 2.0)
	var walnut := style._satin(PinballStyle.WALNUT, 0.45)
	_dim(ToyParts.box(shell, Vector3(wide, tall, deep), walnut, at + _up(tall * 0.5)))
	var glass_at := at + Vector3(0.0, tall * 0.56, deep * 0.5 + 0.05)
	var glass := Vector2(wide - 6.0, (wide - 6.0) * 9.0 / 16.0)
	for side: float in [-1.0, 1.0]:
		var across := Vector3(0.0, side * (glass.y * 0.5 + 0.4), 0.0)
		_dim(
			ToyParts.box(shell, Vector3(glass.x + 1.6, 0.8, 0.5), style._steel(), glass_at + across)
		)
		var down := Vector3(side * (glass.x * 0.5 + 0.4), 0.0, 0.0)
		_dim(ToyParts.box(shell, Vector3(0.8, glass.y, 0.5), style._steel(), glass_at + down))
	var cap := Vector3(wide + 0.6, 0.9, deep + 0.6)
	_dim(ToyParts.box(shell, cap, style._satin(PinballStyle.OCHRE, 0.4), at + _up(tall)))
	# Lit from behind: the picture as it is, whatever light the room has on it.
	var lit := StandardMaterial3D.new()
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lit.albedo_color = Color(0.1, 0.07, 0.11)
	var pane := QuadMesh.new()
	pane.size = glass
	_dim(ToyParts.put(shell, pane, lit, glass_at))
	DrawnTexture.kept(
		arena,
		PinballPrints.glass(),
		PinballPrints.GLASS_PIXELS,
		func(texture: Texture2D) -> void:
			lit.albedo_color = Color(0.85, 0.85, 0.85)
			lit.albedo_texture = texture,
		LayoutPrint.SMOOTH
	)


## The chrome strip down the cabinet's side rails, along the top of the table's edge all round.
func _side_rails(shell: RoomShell) -> void:
	var half := shell._table()
	for side: int in 4:
		var along := side % 2 == 0
		var out := (half.y if along else half.x) * (1.0 if side < 2 else -1.0)
		var run := (
			Vector3(half.x * 2.0 + 0.4, 0.5, 0.4) if along else Vector3(0.4, 0.5, half.y * 2.0)
		)
		var at := (
			Vector3(0.0, RoomBuild.TOP - 0.4, out)
			if along
			else Vector3(out, RoomBuild.TOP - 0.4, 0.0)
		)
		_dim(ToyParts.box(shell, run, style._steel(), at))


func _dim(node: MeshInstance3D) -> MeshInstance3D:
	return ToyParts.flat(node)


## Three spare balls on a little walnut rail, in a row.
func _balls(at: Vector3, turn: float) -> void:
	_turned(
		ToyParts.box(
			props,
			Vector3(4.8, 0.3, 1.8),
			style._satin(PinballStyle.WALNUT, 0.45),
			_local(at, turn, 0.0, 0.15, 0.0)
		),
		turn
	)
	for i: int in 3:
		var spot := _local(at, turn, (float(i) - 1.0) * 1.55, 0.3 + PinballStyle.BALL, 0.0)
		ToyParts.ball(props, PinballStyle.BALL, style._chrome(), spot, 16)


## A stack of spare rubber rings, cream, red and black, each a little off the one under it.
func _rubbers(at: Vector3, _turn: float) -> void:
	var inks: Array[Color] = [
		PinballStyle.RUBBER, PinballStyle.RED_RUBBER, Color("#1D1A1E"), PinballStyle.RUBBER
	]
	var count := props._rng.randi_range(2, 4)
	for i: int in count:
		var spot := at + Vector3(props._rng.randf_range(-0.12, 0.12), 0.18 + 0.3 * float(i), 0.0)
		ToyParts.ring(props, 0.85, 1.35, style._rubber(inks[i]), spot, 24, 6)


## A row of spare bulbs lying on their sides, glass and brass.
func _bulbs(at: Vector3, turn: float) -> void:
	var glass := style._satin(Color("#F1E9D6"), 0.25)
	var brass := style._satin(PinballStyle.OCHRE, 0.35)
	for i: int in 4:
		var x := (float(i) - 1.5) * 1.2
		var bulb := ToyParts.ball(props, 0.42, glass, _local(at, turn, x, 0.42, 0.3), 12)
		bulb.scale = Vector3(1.0, 1.0, 1.25)
		bulb.rotation.y = turn
		var base := ToyParts.cylinder(props, 0.3, 0.6, brass, _local(at, turn, x, 0.32, -0.45), 10)
		base.rotation = Vector3(PI * 0.5, turn, 0.0)


## Quarters for the machine, stacked in front of it.
func _quarters(at: Vector3, turn: float) -> void:
	var silver := style._steel()
	for i: int in 3:
		var high := props._rng.randi_range(3, 9)
		ToyParts.chips(
			props, 0.6, 0.09, high, silver, _local(at, turn, (float(i) - 1.0) * 1.35, 0.0, 0.0)
		)


## A spare bank of drop targets: three ivory targets standing in a steel rail.
func _targets(at: Vector3, turn: float) -> void:
	_turned(
		ToyParts.box(
			props,
			Vector3(5.4, 0.7, 1.8),
			style._satin(PinballStyle.DARK_STEEL, 0.4),
			_local(at, turn, 0.0, 0.35, 0.0)
		),
		turn
	)
	var ace := style.surfaces.printed(Surfaces.CARD_FACES[props._rng.randi_range(0, 3)])
	var card := QuadMesh.new()
	card.size = Vector2(1.0, 1.4)
	for i: int in 3:
		var x := (float(i) - 1.0) * 1.75
		_turned(
			ToyParts.box(
				props,
				Vector3(1.5, 2.2, 0.7),
				style._satin(PinballStyle.IVORY),
				_local(at, turn, x, 1.8, 0.0)
			),
			turn
		)
		var face := ToyParts.put(props, card, ace, _local(at, turn, x, 1.8, 0.36))
		face.rotation.y = turn


## An instruction card left on the table, the kind a machine keeps under its glass: cream, with
## its lines of print.
func _card(at: Vector3, turn: float) -> void:
	_turned(
		ToyParts.box(
			props,
			Vector3(6.0, 0.06, 3.6),
			style._satin(PinballStyle.PLASTIC, 0.3),
			_local(at, turn, 0.0, 0.03, 0.0)
		),
		turn
	)
	var ink := style._satin(Color("#5A3E46"), 0.3)
	for i: int in 5:
		var line := Vector3(4.6 - float(i % 2) * 1.2, 0.02, 0.16)
		_turned(
			ToyParts.box(props, line, ink, _local(at, turn, 0.0, 0.07, -1.1 + 0.55 * float(i))),
			turn
		)


## Where a point [param x] across, [param y] up and [param z] along a prop standing at [param at]
## turned [param turn] is, in the room: across and along as [method RoomProps._ground] has them.
func _local(at: Vector3, turn: float, x: float, y: float, z: float) -> Vector3:
	var across := Vector3(cos(turn), 0.0, -sin(turn))
	var along := Vector3(sin(turn), 0.0, cos(turn))
	return at + across * x + along * z + Vector3(0.0, y, 0.0)


func _turned(node: MeshInstance3D, turn: float) -> MeshInstance3D:
	node.rotation.y = turn
	return node


func _up(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)
