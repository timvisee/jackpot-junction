extends Node
## Renders the pictures the game's page on itch.io wears, docs/ITCH.md, into build/itch and quits,
## which is what `make itch-art` runs: the cover, a shot of the Vault with karts drifting round its
## Junction under the seal and the name, and the page's background, what is behind the title screen,
## dark on purpose so the page's words stay what it is about. Both are the game's own pieces: the
## arena, its room and lighting, the karts as the podium shows them and the pickups, put up in a
## world of their own, and the title's sunburst, so they follow the game as it changes.
##
## The karts are driven round their arcs for a while before the picture is taken, so their sparks,
## smoke and trails stream behind them as in a match. Run at a fixed frame rate, so they are where
## they are meant to be; the room's signs and the particles still differ a little from run to run.
##
## Windowed rather than headless: reading a viewport back needs a rendering device.

const OUT := "res://build/itch"
## itch.io's own size for a cover, drawn this many times over and scaled down so its edges are
## smooth.
const COVER := Vector2i(630, 500)
const OVER := 2
## The background: wide enough for a wide screen, its middle under the page's column. A JPEG, since
## the engraving's fine lines make a PNG of it bigger than itch.io takes; at this quality they hold.
const BACKGROUND := Vector2i(2560, 1440)
const BACKGROUND_QUALITY := 0.9
const MAP := &"vault"
## How long the karts drive before the picture is taken, in frames at 60 a second.
const DRIVE_FRAMES := 50
## The room's excitement, as a match nearing its end has it: lights and crowd up.
const EXCITEMENT := 4

## The cover's camera: where it is and what it looks at.
const COVER_EYE := Vector3(0.0, 5.2, 10.0)
const COVER_AT := Vector3(0.0, 0.6, 0.5)
const COVER_FOV := 42.0
## Where the title's sunburst is centered on the background, as a share of it: high, so its beams
## and rings fan out round the top of the page's column. And how big the mark it is centered on
## would be, which sets where its rays start.
const TITLE_FOCUS := Vector2(0.5, 0.2)
const TITLE_MARK := 360.0

## Each kart on the cover: its seat's color, its dress, the circle it drives round, the angle on
## it it is at when the picture is taken, which way round it goes, and whether it drifts or burns
## its nitro.
const KARTS: Array[Dictionary] = [
	{
		"seat": 0,
		"style": {"paint": 5, "hat": 2, "flag": 3, "trail": 4, "body": 1},
		"center": Vector3(6.0, 0.0, 2.0),
		"radius": 5.3,
		"at": PI - 0.3,
		"way": -1.0,
		"drift": true,
	},
	{
		"seat": 1,
		"style": {"paint": 6, "hat": 1, "flag": 1, "trail": 1, "body": 3},
		"center": Vector3(-8.0, 0.0, 0.0),
		"radius": 5.0,
		"at": 0.3,
		"way": -1.0,
		"nitro": true,
	},
	{
		"seat": 2,
		"style": {"paint": 4, "hat": 6, "flag": 4, "trail": 2, "body": 2},
		"center": Vector3(0.0, 0.0, 0.0),
		"radius": 3.6,
		"at": -0.9,
		"way": 1.0,
		"drift": true,
	},
]
## How fast the karts go round, in meters a second, as a kart at speed does.
const SPEED := 9.0
## The drift as the kart dialog poses it: the nose turned past the way it goes, the body leaning
## out of the turn and the front wheels turned against it.
const DRIFT_SLIP := 0.62
const LEAN := 0.075
const COUNTERSTEER := 0.75
## The chips and the rest on the felt round the Junction.
const GOLD_CHIPS: Array[Vector3] = [Vector3(-1.4, 0, 4.2), Vector3(2.4, 0, 4.6)]
const CHIPS: Array[Vector3] = [Vector3(-2.6, 0, 3.0), Vector3(-0.4, 0, 5.4), Vector3(3.4, 0, 3.0)]
const DIE := Vector3(-1.0, 0, 2.4)
const BOX := Vector3(3.7, 0, 0.9)
const BOX_ITEM := "res://data/powerups/shield.tres"

## The seal and the name over the cover's top, as the title sets them, on a band of the house's
## stock fading into the room: in pixels of the cover, before it is drawn over.
const MARK := 140
const NAME_SIZE := 76
const LOCKUP_GAP := 18
const LOCKUP_TOP := 18
## The name's two lines closer than a label sets them, its capitals all it has.
const LINES_CLOSER := 16
const BAND := 0.6
const BAND_INK := 0.92
## Where down the band it starts to fade, and how dark it still is there.
const BAND_HOLD := 0.45
const BAND_HELD := 0.7

var _runners: Array[Dictionary] = []
var _frame := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Nothing in it is for the game: keep the editor and the export from looking inside.
	var ignore := FileAccess.open(OUT + "/.gdignore", FileAccess.WRITE)
	if ignore != null:
		ignore.close()
	_save(await _cover(), OUT + "/cover.png", COVER)
	_save(await _background(), OUT + "/background.jpg", BACKGROUND)
	get_tree().quit()


func _process(delta: float) -> void:
	_frame += 1
	for runner: Dictionary in _runners:
		_drive(runner, delta)


## The Vault with the karts round its Junction, the seal and the name over it.
func _cover() -> Image:
	var size := COVER * OVER
	var stage := _stage(size)
	var viewport: SubViewport = stage["viewport"]
	var arena: Arena = stage["arena"]
	_look(stage, COVER_EYE, COVER_AT, COVER_FOV)
	for kart: Dictionary in KARTS:
		_runners.append(_kart(viewport, kart))
	_lay_pickups(arena)
	viewport.add_child(_lockup(size))
	var image := await _taken(viewport, DRIVE_FRAMES)
	# Gone with the viewport: nothing left to drive.
	_runners.clear()
	return image


## What is behind the title screen, its sunburst centered high over the page's column.
func _background() -> Image:
	var viewport := SubViewport.new()
	viewport.size = BACKGROUND
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := Control.new()
	screen.size = Vector2(BACKGROUND)
	viewport.add_child(screen)
	MenuTheme.background(screen)
	var back := TitleBackground.add_to(screen)
	var focus := Control.new()
	focus.size = Vector2.ONE * TITLE_MARK
	focus.position = Vector2(BACKGROUND) * TITLE_FOCUS - focus.size / 2.0
	screen.add_child(focus)
	back.anchor = focus
	return await _taken(viewport, 20)


## A world of its own at [param size] with the map's arena in it, lit as its room is, and the
## room's lights and crowd up as a match would have them.
func _stage(size: Vector2i) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = size
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var lighting := ArenaEnvironment.add_to(viewport)
	var arena := Arena.new()
	arena.layout = ArenaMaps.layout(MAP)
	viewport.add_child(arena)
	lighting.floor_size = arena.world_size()
	lighting.dress(arena.room)
	if arena.disco != null:
		arena.disco.level = EXCITEMENT
	if arena.crowd != null:
		arena.crowd.level = EXCITEMENT
	return {"viewport": viewport, "arena": arena}


## A camera at [param eye] looking at [param at], its far focus the room's, as the match's own.
func _look(stage: Dictionary, eye: Vector3, at: Vector3, fov: float) -> void:
	var arena: Arena = stage["arena"]
	var camera := Camera3D.new()
	camera.fov = fov
	camera.near = 0.5
	camera.far = 300.0
	(stage["viewport"] as SubViewport).add_child(camera)
	camera.look_at_from_position(eye, at, Vector3.UP)
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = true
	lens.dof_blur_far_distance = eye.distance_to(at) + arena.room.focus_from
	lens.dof_blur_far_transition = 22.0
	lens.dof_blur_amount = arena.room.focus_blur
	camera.attributes = lens


## The kart [param kart] says, in [param viewport], set at the start of its arc.
func _kart(viewport: SubViewport, kart: Dictionary) -> Dictionary:
	var style := KartStyle.new()
	for field: String in kart["style"]:
		style.set(field, kart["style"][field])
	var seat: int = kart["seat"]
	var holder := Node3D.new()
	var model := KartVisuals.display_model(seat, style)
	# A model stands for display with its wheels the model's lift off the ground; here they are on it.
	model.position.y = -KartVisuals.MODEL_LIFT
	holder.add_child(model)
	# In the world before its sparks and flame, which build themselves as they come into it.
	viewport.add_child(holder)
	var runner := kart.duplicate()
	runner["node"] = holder
	runner["model"] = model
	runner["wheels"] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var called := node.name.to_lower()
		if called.begins_with("wheel"):
			(runner["wheels"] as Array).append(
				[node, (node as MeshInstance3D).transform, not called.contains("back")]
			)
	var smoke := ExhaustSmoke.new()
	smoke.position = KartStage.EXHAUST
	smoke.dress(Palette.player_color(seat), style.trail, style.finish(3))
	model.add_child(smoke)
	smoke.update_state(1.0, kart.get("drift", false), kart.get("nitro", false))
	smoke.emitting = true
	if kart.get("drift", false):
		var sparks := DriftSparks.new()
		model.add_child(sparks)
		sparks.set_state(true, true)
	if kart.get("nitro", false):
		var flame := NitroFlame.new()
		flame.position = Vector3(0.0, 0.4, 0.75)
		model.add_child(flame)
		flame.set_active(true)
	# Started as far back along its arc as it drives before the picture.
	var angle_speed: float = SPEED / float(kart["radius"]) * float(kart["way"])
	runner["angle"] = float(kart["at"]) - angle_speed * DRIVE_FRAMES / 60.0
	runner["angle_speed"] = angle_speed
	_drive(runner, 0.0)
	return runner


## Moves [param runner] round its circle by [param delta] seconds, turned the way it goes, and
## drifting into the turn if it drifts.
func _drive(runner: Dictionary, delta: float) -> void:
	runner["angle"] = float(runner["angle"]) + float(runner["angle_speed"]) * delta
	var angle: float = runner["angle"]
	var center: Vector3 = runner["center"]
	var radius: float = runner["radius"]
	var way: float = runner["way"]
	var at := center + Vector3(cos(angle), 0.0, sin(angle)) * radius
	var going := Vector3(-sin(angle), 0.0, cos(angle)) * way
	# A kart's nose is its -Z.
	var heading := atan2(-going.x, -going.z)
	var drifting: bool = runner.get("drift", false)
	# Into the turn: toward the middle of the circle.
	var inward := 1.0 if (center - at).dot(going.rotated(Vector3.UP, PI / 2.0)) > 0.0 else -1.0
	var slip := inward * DRIFT_SLIP if drifting else 0.0
	var roll := -inward * LEAN if drifting else 0.0
	var node: Node3D = runner["node"]
	node.transform = Transform3D(Basis.from_euler(Vector3(0.0, heading + slip, roll)), at)
	var steer := -slip * COUNTERSTEER
	for wheel: Array in runner["wheels"]:
		var mesh: MeshInstance3D = wheel[0]
		var rest: Transform3D = wheel[1]
		var turned := Basis(Vector3.UP, steer if wheel[2] else 0.0)
		mesh.transform = Transform3D(
			turned * rest.basis * Basis(Vector3.RIGHT, -_frame * 0.5), rest.origin
		)


## The seal with the name beside it in two lines, over a band of stock across the top of
## [param size] that fades into the room under it.
func _lockup(size: Vector2i) -> Control:
	var over := Control.new()
	over.size = Vector2(size)
	var band := TextureRect.new()
	var fade := GradientTexture2D.new()
	fade.gradient = Gradient.new()
	fade.gradient.set_color(0, Color(HouseTheme.STOCK, BAND_INK))
	fade.gradient.set_color(1, Color(HouseTheme.STOCK, 0.0))
	fade.gradient.add_point(BAND_HOLD, Color(HouseTheme.STOCK, BAND_HELD))
	fade.fill_from = Vector2(0.5, 0.0)
	fade.fill_to = Vector2(0.5, 1.0)
	fade.width = 4
	fade.height = 256
	band.texture = fade
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.size = Vector2(size.x, size.y * BAND)
	over.add_child(band)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", LOCKUP_GAP * OVER)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size = Vector2(size.x, MARK * OVER)
	row.position = Vector2(0.0, LOCKUP_TOP * OVER)
	var seal := LogoArt.new()
	seal.plate = false
	seal.custom_minimum_size = Vector2.ONE * MARK * OVER
	row.add_child(seal)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", -LINES_CLOSER * OVER)
	var font := Type.mark_font().duplicate() as FontVariation
	font.spacing_glyph = roundi(3.0 * NAME_SIZE * OVER / Type.HERO)
	for word: String in ["Jackpot", "Junction"]:
		var label := MenuTheme.title(word, NAME_SIZE * OVER)
		Type.set_font(label, font, NAME_SIZE * OVER)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		words.add_child(label)
	row.add_child(words)
	over.add_child(row)
	return over


## Chips, a multiplier die and a power-up's box on the felt round the Junction.
func _lay_pickups(arena: Arena) -> void:
	for spot: Vector3 in GOLD_CHIPS + CHIPS:
		var chip := Chip.new()
		chip.gold = GOLD_CHIPS.has(spot)
		chip.position = spot
		arena.pickups.add_child(chip)
	var die := MultDie.new()
	die.position = DIE
	arena.pickups.add_child(die)
	var box := ItemBox.new()
	box.fixed_item = load(BOX_ITEM)
	box.position = BOX
	arena.pickups.add_child(box)


## What [param viewport] shows after [param frames] frames, its pieces gone after.
func _taken(viewport: SubViewport, frames: int) -> Image:
	for i: int in frames:
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	viewport.queue_free()
	return image


## [param image] at [param size] in [param path].
func _save(image: Image, path: String, size: Vector2i) -> void:
	var scaled := image.duplicate() as Image
	if scaled.get_size() != size:
		scaled.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var saved := (
		scaled.save_jpg(path, BACKGROUND_QUALITY)
		if path.ends_with(".jpg")
		else scaled.save_png(path)
	)
	if saved != OK:
		push_error("could not write %s" % path)
		return
	print("itch %s: %dx%d" % [path, size.x, size.y])
