class_name ResultsPodium
extends SubViewportContainer
## The top three on a victory podium at the head of the results screen, GAME.md 3.8: the winner
## on the tallest step in the middle, second a little lower on one side and third the lowest on
## the other, each with their own kart standing on top of it turning slowly on the spot. In team
## play a step a team, GAME.md 3.14, as wide as the team, its karts side by side on it.
##
## A little 3D scene of its own in a viewport rather than a picture, because the karts are
## already models and a kart turning under a light says more about who won than a name in a list
## does. Its own world too, so none of the arena the match was played in leaks into it.
##
## The steps are the House's podium of the party at the end of a Grand Prix, GAME.md 9.7, small:
## a block of what the room the match was played in is made of, see [PartyDress], or of the House's
## stock where the slip does not know the room; a ticket in the player's color laid on top of it,
## its corners punched; and on its front a plaque of the House's stock with a hairline of the
## player's color and the place in foil.

## The top three have been stood on it, see [method show_top].
signal stood

const SIZE := Vector2(940.0, 272.0)
## Where each place stands and how tall its step is, in meters: the winner in the middle, second
## to the left a little lower, third to the right and lowest of all.
const PLACES: Array[Vector2] = [Vector2(0.0, 1.15), Vector2(-2.3, 0.88), Vector2(2.3, 0.66)]
const STEP_WIDTH := 1.9
const STEP_DEPTH := 1.9
## How far apart steps stand, how much room a kart takes beside its teammates on a team's step,
## and how wide the picture has room for, past which the whole podium is drawn smaller.
const STEP_GAP := 0.4
const KART_ROOM := 1.75
const FRAME := 13.0
## Seconds for a kart to turn all the way round.
const SPIN_SECONDS := 7.0
## Room over the karts for the tallest hat anybody can wear, GAME.md 4.4, without the picture
## being mostly sky for everybody who is not wearing one.
const KART_SCALE := 1.05
## The ticket on top of a step: how thick, and how deep its corners are punched, which is how far
## in the block under it stands; and how far over it a kart's wheels are.
const CAP := 0.1
const CAP_NOTCH := 0.12
const TOP_LIFT := 0.0
## The plaque on a step's front, the same on every step, sized to the lowest: its size, its corners,
## how thick, its hairline, how far in and how wide, and how tall its place is in foil.
const PLAQUE := Vector2(0.9, 0.44)
const PLAQUE_NOTCH := 0.07
const PLAQUE_THICK := 0.02
const PLAQUE_LINE_IN := 0.07
const PLAQUE_LINE := 0.02
## The place's height in foil: well short of the hairline frame inside the plaque, 0.44 - 2 * 0.07
## tall, so it sits within it with air around it rather than pressed against it.
const NUMBER_HEIGHT := 0.2

## How high over a kart on the podium its player's emote pops up, clear of the tallest hat, and how
## big it is drawn there, the picture being small, see [method Emotes.pop_over].
const EMOTE_HEIGHT := 1.72
const EMOTE_BIG := 0.62

## What the steps are built of, the room the match was played in's, see [PartyDress]; none for
## the House's stock.
var dress: PartyDress

var _viewport: SubViewport
var _stage: Node3D
var _steps: Node3D
var _paints: Dictionary[String, StandardMaterial3D] = {}
var _karts: Array[Node3D] = []
## Who stands on each step, by the step, for their emotes, see [method _on_emoted].
var _standing: Array[PlayerSlot] = []


static func create() -> ResultsPodium:
	var podium := ResultsPodium.new()
	podium.name = "Podium"
	podium._build()
	return podium


## Stands the top three on it, tallest first, each kart with the plate it wore in the match on
## its back, GAME.md 4.4, the learner's L or its license plate, a bot's too. Called every time
## the screen is filled in, so it clears whatever was standing there before.
func show_top(standings: Array[PlayerSlot]) -> void:
	for child: Node in _stage.get_children():
		_stage.remove_child(child)
		child.free()
	_karts.clear()
	_standing.clear()
	_steps = Node3D.new()
	_steps.name = "Steps"
	_stage.add_child(_steps)
	var sides := Teams.sides_of(standings)
	var shown := mini(sides.size(), PLACES.size())
	var widths: Array[float] = []
	for place: int in shown:
		widths.append(step_width((sides[place] as Array).size(), STEP_WIDTH, KART_ROOM))
	var across := spread(widths, STEP_GAP)
	var left := 0.0
	var right := 0.0
	for place: int in shown:
		_add_step(sides[place], place, across[place], widths[place])
		left = minf(left, across[place] - widths[place] * 0.5)
		right = maxf(right, across[place] + widths[place] * 0.5)
	# A full podium is already centered on the winner. A short one is not, so the whole thing is
	# slid over until what is standing on it sits in the middle of the picture; and a podium of
	# teams too wide for the picture is drawn smaller.
	# The steps never move, so they are baked into a mesh for each of their materials.
	Bake.merge(_steps)
	var fit := minf(1.0, FRAME / maxf(right - left, 0.001))
	_stage.scale = Vector3.ONE * fit
	_stage.position.x = -(left + right) * 0.5 * fit
	visible = not _karts.is_empty()
	stood.emit()
	# Nothing is drawn until there is something to draw. A viewport set to update always does so
	# whether or not anybody can see it, and this one is hidden for the whole match.
	draw_while(visible)


## Where the winner stands in the picture, as a share of it across and down: the top of the
## middle of the tallest step, slid over with the rest on a short podium, for the lamps over the
## photo finish to be aimed at, see [PhotoBackdrop]. Worked out from the camera rather than asked
## of it, so it is known before anything is drawn.
func winner_at() -> Vector2:
	var camera := _viewport.get_node("Camera") as Camera3D
	var top := _stage.transform * Vector3(PLACES[0].x, PLACES[0].y, 0.0)
	var seen := camera.transform.affine_inverse() * top
	if seen.z >= 0.0:
		return Vector2(0.5, 0.5)
	# Over the distance in front of the camera, against how far the picture's half height reaches.
	var reach := tan(deg_to_rad(camera.fov) * 0.5) * -seen.z
	var aspect := size.x / maxf(size.y, 1.0) if size.y > 0.0 else SIZE.x / SIZE.y
	return Vector2(0.5 + seen.x / (reach * aspect) * 0.5, 0.5 - seen.y / reach * 0.5)


## Drawn while [param seen], and not while it is not: hidden, or scrolled off the screen on a long
## slip, see [PayoutBill].
func draw_while(seen: bool) -> void:
	var mode := (
		SubViewport.UPDATE_ALWAYS if seen and not _karts.is_empty() else SubViewport.UPDATE_DISABLED
	)
	if _viewport.render_target_update_mode != mode:
		_viewport.render_target_update_mode = mode


func _process(delta: float) -> void:
	# Only while its world is being drawn: a podium frozen off-screen or under a scroll, see
	# [method draw_while] and [PayoutBill], holds its karts still, so they stand where they stood
	# when it is drawn again rather than having spun on unseen and jumping.
	if _viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		return
	for kart: Node3D in _karts:
		kart.rotate_y(TAU * delta / SPIN_SECONDS)


## How wide a step is for [param karts] side by side: [param least] for one, and for a team as wide
## as they need at [param room] a kart, GAME.md 3.14.
static func step_width(karts: int, least: float, room: float) -> float:
	return least if karts <= 1 else maxf(least, karts * room + 0.3)


## Where each step [param widths] wide stands across a podium: the winner's in the middle, second's
## to the left and third's to the right, [param gap] apart.
static func spread(widths: Array[float], gap: float) -> Array[float]:
	var across: Array[float] = []
	for place: int in widths.size():
		if place == 0:
			across.append(0.0)
		elif place == 1:
			across.append(-(widths[0] * 0.5 + gap + widths[1] * 0.5))
		else:
			across.append(widths[0] * 0.5 + gap + widths[place] * 0.5)
	return across


## One step [param width] wide at [param x] with [param side]'s karts on top, side by side: the
## block, the ticket of the step's color on it and the plaque with the place on its front; and each
## kart with the plate it wore.
func _add_step(side: Array, place: int, x: float, width: float) -> void:
	var at := Vector2(x, PLACES[place].y)
	var first: PlayerSlot = side[0]
	var color := first.color()
	var high := at.y - CAP
	var block := Vector3(width - CAP_NOTCH * 2.0, high, STEP_DEPTH - CAP_NOTCH * 2.0)
	var body: Material = dress.body if dress != null else _paint(HouseTheme.STOCK_RAISED)
	var mesh := BoxMesh.new()
	mesh.size = block
	var step := MeshInstance3D.new()
	step.mesh = mesh
	step.material_override = body
	step.position = Vector3(at.x, high * 0.5, 0.0)
	_steps.add_child(step)
	var cap := HousePieces.ticket(Vector2(width, STEP_DEPTH), CAP_NOTCH, CAP)
	var plaque := HousePieces.ticket(PLAQUE, PLAQUE_NOTCH, PLAQUE_THICK)
	var front := HousePieces.standing(Vector3(at.x, high * 0.5, block.z * 0.5))
	var top := Transform3D(Basis.IDENTITY, Vector3(at.x, high, 0.0))
	var pieces: Array[Array] = [[cap, top, color], [plaque, front, HouseTheme.STOCK]]
	var cut := MeshInstance3D.new()
	cut.mesh = Bake.tinted(pieces)
	cut.material_override = Bake.tinted_look(false)
	_steps.add_child(cut)
	var framed := Rect2(-PLAQUE * 0.5, PLAQUE).grow(-PLAQUE_LINE_IN)
	var over := front * Transform3D(Basis.IDENTITY, Vector3.UP * (PLAQUE_THICK + 0.003))
	HousePieces.hairline(
		_steps, framed, PLAQUE_LINE, HousePieces.lit(color, GrandPrixFinale.LINE_GLOW), over
	)
	var number := HousePieces.words(
		_stage, str(place + 1), NUMBER_HEIGHT, PLAQUE.x, HousePieces.FOIL, 0.0
	)
	number.position = Vector3(at.x, high * 0.5, block.z * 0.5 + PLAQUE_THICK + 0.008)
	for k: int in side.size():
		var slot: PlayerSlot = side[k]
		var kart := Node3D.new()
		kart.name = "Kart%d_%d" % [place, k]
		var along := at.x + (float(k) - float(side.size() - 1) * 0.5) * KART_ROOM
		# Its wheels on the step: a model stands lifted in what is hung round it, see
		# [constant KartVisuals.MODEL_LIFT].
		kart.position = Vector3(along, at.y + TOP_LIFT - KartVisuals.MODEL_LIFT * KART_SCALE, 0.0)
		kart.scale = Vector3.ONE * KART_SCALE
		kart.rotation.y = KartVisuals.facing_soon(SPIN_SECONDS)
		var model := KartVisuals.display_model(slot.paint_index(), slot.style)
		kart.add_child(model)
		KartVisuals.plate_like(model, KartVisuals.plate_worn(slot.kart))
		_stage.add_child(kart)
		_karts.append(kart)
		_standing.append(slot)


func _ready() -> void:
	Events.emoted.connect(_on_emoted)


func _exit_tree() -> void:
	if Events.emoted.is_connected(_on_emoted):
		Events.emoted.disconnect(_on_emoted)


## Somebody on the podium has emoted, GAME.md 3.8: up it pops over their kart in the photo finish
## as well as over the kart itself, so it is seen where everybody is looking.
func _on_emoted(index: int, emote: int) -> void:
	if not visible:
		return
	for place: int in _standing.size():
		var slot := _standing[place]
		if slot.index == index:
			Emotes.pop_over(_karts[place], emote, slot.color(), EMOTE_HEIGHT, EMOTE_BIG)


## Plain paint in [param color], one for each color.
func _paint(color: Color) -> StandardMaterial3D:
	var key := color.to_html(false)
	if not _paints.has(key):
		_paints[key] = PartyDress.plain(color)
	return _paints[key]


func _build() -> void:
	custom_minimum_size = SIZE
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.name = "Stage"
	_viewport.size = Vector2i(SIZE)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.world_3d = _world()
	add_child(_viewport)
	_stage = Node3D.new()
	_stage.name = "Podium"
	_viewport.add_child(_stage)
	_viewport.add_child(_camera())
	_viewport.add_child(_key_light())


## A world of its own with nothing in it but an even light, so the podium is lit the same
## whatever the arena behind it was doing.
func _world() -> World3D:
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	environment.ambient_light_energy = 1.0
	world.environment = environment
	return world


## Aimed a little above the steps rather than at them, so the karts have air over their heads
## instead of being cut off by the top edge and the picture is not all sky underneath them.
func _camera() -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.fov = 40.0
	camera.position = Vector3(0.0, 2.15, 6.6)
	camera.look_at_from_position(camera.position, Vector3(0.0, 1.25, 0.0), Vector3.UP)
	return camera


func _key_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "Key"
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-38.0, -32.0, 0.0)
	light.shadow_enabled = false
	return light
