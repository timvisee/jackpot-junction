extends Node
## What the exports that dress a store's page in the game's own pieces share, docs/ITCH.md and
## docs/STEAM.md: a world of its own with a map's arena in it, lit as its room is, with its lights
## and crowd up as a match nearing its end has them; karts as the podium shows them, driven round
## arcs for a while before the picture so their sparks, smoke and trails stream behind them; chips,
## a die and a power-up's box on the felt; the seal and the name; and what is behind the title
## screen. Each picture is read back from a viewport, drawn a few times over, and scaled down so its
## edges are smooth.
##
## Run at a fixed frame rate, so the karts are where they are meant to be; the room's signs and the
## particles still differ a little from run to run. Windowed rather than headless: reading a
## viewport back needs a rendering device.

## How long the karts drive before a picture is taken, in frames at 60 a second.
const DRIVE_FRAMES := 50
## The room's excitement, as a match nearing its end has it: lights and crowd up.
const EXCITEMENT := 4
## How fast the karts go round, in meters a second, as a kart at speed does.
const SPEED := 9.0
## The drift as the kart dialog poses it: the nose turned past the way it goes, the body leaning
## out of the turn and the front wheels turned against it.
const DRIFT_SLIP := 0.62
const LEAN := 0.075
const COUNTERSTEER := 0.75
## The name's two lines closer than a label sets them, its capitals all it has, against its size.
const LINES_CLOSER := 0.21
## How many seconds of a kart's arc its tire marks are laid along before it starts to drive, and
## how dark they are, see [TireMarks]: a drift's dark, a kart going straight's barely there. Laid
## twice over, so a still picture shows them as a player sees the dark ones a drift leaves, and
## lifted clear of the Junction's wheel, which a mark on the felt runs under.
const MARKS_BEHIND := 1.6
const DRIFT_MARKS := 1.0
const STRAIGHT_MARKS := 0.2
const MARK_LAYERS := 2
const MARK_LIFT := 0.08
## The most of its circle a kart's marks run round, so a kart on a tight one does not lay its marks
## over its own and darken them twice.
const MARKS_ROUND := 0.7

## The karts round the Junction every picture of the table has, see [method put_kart], each
## driver's face toward a camera in front of the table: the red kart drifting in toward it about to
## scoop a gold chip, its trail of chips behind it; the blue one coming in on its nitro from the
## left; the yellow one drifting round the Junction behind the red one and to its right.
const KARTS: Array[Dictionary] = [
	{
		"seat": 0,
		"style": {"paint": 5, "hat": 2, "flag": 3, "trail": 4, "body": 1},
		"center": Vector3(-3.5, 0.0, 3.0),
		"radius": 5.0,
		"at": 0.0,
		"way": 1.0,
		"drift": true,
	},
	{
		"seat": 1,
		"style": {"paint": 6, "hat": 1, "flag": 1, "trail": 1, "body": 3},
		"center": Vector3(-10.8, 0.0, 7.6),
		"radius": 9.0,
		"at": -0.6435,
		"way": 1.0,
		"nitro": true,
	},
	{
		"seat": 2,
		"style": {"paint": 4, "hat": 6, "flag": 4, "trail": 2, "body": 2},
		"center": Vector3(0.0, 0.0, 0.0),
		"radius": 3.2,
		"at": -0.35,
		"way": 1.0,
		"drift": true,
		# A whole circle round the Junction, clear of its wheel, which a mark would run under, but
		# as light as a kart's going straight, so the tightest circle of the three does not lay
		# the darkest marks.
		"marks_round": 1.0,
		"marks_dark": STRAIGHT_MARKS,
	},
]
## The chips and the rest on the felt round the Junction.
const GOLD_CHIPS: Array[Vector3] = [Vector3(1.3, 0, 5.3), Vector3(-2.2, 0, 4.4)]
const CHIPS: Array[Vector3] = [Vector3(-5.0, 0, 4.4), Vector3(3.6, 0, 3.6), Vector3(5.4, 0, 1.6)]
const DIE := Vector3(-1.2, 0, 2.6)
const BOX := Vector3(-4.6, 0, -2.2)
const BOX_ITEM := "res://data/powerups/shield.tres"

## The studio a thing is shown in on its own, see [method studio]: a key light from the upper left
## that casts the shadows, a fill from the right, and a rim from behind, each [degrees, color,
## energy]; and the air's own light, filling the shaded sides.
const STUDIO_LIGHTS: Array[Array] = [
	[Vector3(-42.0, -38.0, 0.0), Color(1.0, 0.95, 0.86), 1.25],
	[Vector3(-18.0, 70.0, 0.0), Color(0.82, 0.86, 1.0), 0.45],
	[Vector3(-28.0, 165.0, 0.0), Color(1.0, 0.9, 0.7), 0.9],
]
const STUDIO_AIR := Color(0.78, 0.76, 0.84)
const STUDIO_AIR_ENERGY := 0.55

## The language the words drawn in are in, by its locale: English whatever the machine speaks, or
## another the game speaks that `-- --language=<locale>` asks for, as the game says it there.
var language := Lang.ENGLISH

var _runners: Array[Dictionary] = []
var _frame := 0


func _enter_tree() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--language="):
			language = arg.trim_prefix("--language=")
	if language not in Lang.spoken():
		push_error("no translation into %s: drawn in English" % language)
		language = Lang.ENGLISH
	Lang.apply(language)


## Steam's name for [member language], `dutch` for nl: what a picture of words in it is marked with.
func steam_language() -> String:
	return Lang.STEAM_NAMES.find_key(language)


func _process(delta: float) -> void:
	_frame += 1
	for runner: Dictionary in _runners:
		_drive(runner, delta)


## Makes the folder [param path] if it is not there, with a .gdignore in it: nothing in it is for
## the game, so the editor and the export keep out.
static func make_out(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	var ignore := FileAccess.open(path + "/.gdignore", FileAccess.WRITE)
	if ignore != null:
		ignore.close()


## A world of its own at [param size] with the arena of [param map] in it, lit as its room is, and
## the room's lights and crowd up as a match would have them.
func stage(size: Vector2i, map: StringName = &"vault") -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = size
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var lighting := ArenaEnvironment.add_to(viewport)
	var arena := Arena.new()
	arena.layout = ArenaMaps.layout(map)
	viewport.add_child(arena)
	lighting.floor_size = arena.world_size()
	lighting.dress(arena.room)
	if arena.disco != null:
		arena.disco.level = EXCITEMENT
	if arena.crowd != null:
		arena.crowd.level = EXCITEMENT
	return {"viewport": viewport, "arena": arena}


## A camera in [param world] at [param eye] looking at [param at], its far focus the room's, as the
## match's own. [param fov] is up and down, unless [param across] says it is from side to side, for
## a picture taller than it is wide. [param focus], when given, is the far blur's own [distance,
## transition, amount] rather than the room's.
func look(
	world: Dictionary,
	eye: Vector3,
	at: Vector3,
	fov: float,
	across := false,
	focus := Vector3.ZERO,
) -> Camera3D:
	var arena: Arena = world["arena"]
	var camera := Camera3D.new()
	camera.fov = fov
	camera.keep_aspect = Camera3D.KEEP_WIDTH if across else Camera3D.KEEP_HEIGHT
	camera.near = 0.5
	camera.far = 300.0
	(world["viewport"] as SubViewport).add_child(camera)
	camera.look_at_from_position(eye, at, Vector3.UP)
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = true
	lens.dof_blur_far_distance = eye.distance_to(at) + arena.room.focus_from
	lens.dof_blur_far_transition = 22.0
	lens.dof_blur_amount = arena.room.focus_blur
	if focus != Vector3.ZERO:
		lens.dof_blur_far_distance = focus.x
		lens.dof_blur_far_transition = focus.y
		lens.dof_blur_amount = focus.z
	camera.attributes = lens
	return camera


## The kart [param kart] says, in [param viewport], set back along its arc as far as it drives
## before the picture: its seat's color, its dress, the circle it drives round, the angle on it
## it is at when the picture is taken, which way round it goes, whether it drifts or burns its
## nitro, and, where it says, how much of its circle its marks run round and how dark they are, see
## [constant MARKS_ROUND]. Driven every frame from then on.
func put_kart(viewport: SubViewport, kart: Dictionary, frames := DRIVE_FRAMES) -> Dictionary:
	var style := KartStyle.new()
	for field: String in kart["style"]:
		style.set(field, kart["style"][field])
	var seat: int = kart["seat"]
	var holder := Node3D.new()
	var model := KartVisuals.display_model(seat, style)
	# A model stands for display with its wheels the model's lift off the ground; here they are on
	# it.
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
	var layers: Array[TireMarks] = []
	for layer: int in MARK_LAYERS:
		var marks := TireMarks.laid(style.marks, style.finish(5))
		viewport.add_child(marks)
		# A top-level node, set where it stands once it is in the world.
		marks.position.y = MARK_LIFT
		layers.append(marks)
	runner["marks"] = layers
	var angle_speed: float = SPEED / float(kart["radius"]) * float(kart["way"])
	var round_time := (
		float(kart.get("marks_round", MARKS_ROUND)) * TAU * float(kart["radius"]) / SPEED
	)
	var behind := clampf(round_time - frames / 60.0, 0.0, MARKS_BEHIND)
	runner["angle"] = float(kart["at"]) - angle_speed * (frames / 60.0 + behind)
	runner["angle_speed"] = angle_speed
	# The marks of the way it came, laid at once rather than driven.
	for i: int in roundi(behind * 60.0):
		_drive(runner, 1.0 / 60.0)
	_runners.append(runner)
	return runner


## The karts of [constant KARTS] in [param world], driving, and the chips, the die and the box laid
## round them.
func put_table(world: Dictionary) -> void:
	for kart: Dictionary in KARTS:
		put_kart(world["viewport"], kart)
	lay(world["arena"], GOLD_CHIPS, CHIPS, DIE, BOX, BOX_ITEM)


## Lets go of the karts: gone with their viewport, nothing left to drive.
func park() -> void:
	_runners.clear()


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
	var dark: float = runner.get("marks_dark", DRIFT_MARKS if drifting else STRAIGHT_MARKS)
	_mark(runner, node.global_basis.x, dark)


## Lays [param runner]'s tire marks under its back wheels where they stand now, [param side] its
## axle's way across and [param dark] how dark, see [method TireMarks.add_sample].
func _mark(runner: Dictionary, side: Vector3, dark: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	for marks: TireMarks in runner.get("marks", []):
		var wheel := 0
		for each: Array in runner["wheels"]:
			if not each[2]:
				marks.add_sample(wheel, (each[0] as Node3D).global_position, side, dark, now)
				wheel += 1


## Chips, gold ones among them, a multiplier die and a power-up's box on the felt of [param arena].
func lay(
	arena: Arena,
	gold: Array[Vector3],
	chips: Array[Vector3],
	die: Vector3,
	box: Vector3,
	item: String,
) -> void:
	for spot: Vector3 in gold + chips:
		var chip := Chip.new()
		chip.gold = gold.has(spot)
		chip.position = spot
		arena.pickups.add_child(chip)
	var multiplier := MultDie.new()
	multiplier.position = die
	arena.pickups.add_child(multiplier)
	var crate := ItemBox.new()
	crate.fixed_item = load(item)
	crate.position = box
	arena.pickups.add_child(crate)


## The seal with the name, as the title sets them: beside it in two lines, or under it in two when
## [param stacked]; [param mark] pixels across, the name [param name_size] tall a line. Laid out at
## its own size, its corner at nothing.
static func lockup(mark: float, name_size: int, gap: float, stacked := false) -> Container:
	var box: BoxContainer = VBoxContainer.new() if stacked else HBoxContainer.new()
	box.add_theme_constant_override("separation", roundi(gap))
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var seal := LogoArt.new()
	seal.plate = false
	seal.custom_minimum_size = Vector2.ONE * mark
	seal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(seal)
	box.add_child(name_lines(name_size, stacked))
	return box


## The name in two lines of the mark's own cut, a little wider set, as the title sets it.
static func name_lines(size: int, centered := false) -> VBoxContainer:
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", -roundi(size * LINES_CLOSER))
	var font := Type.mark_font().duplicate() as FontVariation
	font.spacing_glyph = roundi(3.0 * size / Type.HERO)
	for word: String in ["Jackpot", "Junction"]:
		var label := MenuTheme.title(word, size)
		Type.set_font(label, font, size)
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
		)
		words.add_child(label)
	return words


## A band of the house's stock [param ink] at one end, fading to nothing at the other, [param hold]
## of the way along still at [param held]: from the top down, or from [param from] to [param to]
## in shares of the band.
static func band(
	ink: float, hold: float, held: float, from := Vector2(0.5, 0.0), to := Vector2(0.5, 1.0)
) -> TextureRect:
	var shade := TextureRect.new()
	var fade := GradientTexture2D.new()
	fade.gradient = Gradient.new()
	fade.gradient.set_color(0, Color(HouseTheme.STOCK, ink))
	fade.gradient.set_color(1, Color(HouseTheme.STOCK, 0.0))
	fade.gradient.add_point(hold, Color(HouseTheme.STOCK, held))
	fade.fill_from = from
	fade.fill_to = to
	fade.width = 256
	fade.height = 256
	shade.texture = fade
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	return shade


## What is behind the title screen at [param size], its sunburst centered on [param focus], a share
## of it, round a mark [param mark] pixels across, which sets where its rays start.
func backdrop(size: Vector2i, focus: Vector2, mark: float) -> Image:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := Control.new()
	screen.size = Vector2(size)
	viewport.add_child(screen)
	MenuTheme.background(screen)
	var back := TitleBackground.add_to(screen)
	var middle := Control.new()
	middle.size = Vector2.ONE * mark
	middle.position = Vector2(size) * focus - middle.size / 2.0
	screen.add_child(middle)
	back.anchor = middle
	return await taken(viewport, 20)


## A world of its own at [param size] lit as a studio is, see [constant STUDIO_LIGHTS], on nothing,
## for a thing to be shown in on its own and laid over a picture after, see [method over].
func studio(size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.size = size
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var air := Environment.new()
	air.background_mode = Environment.BG_CLEAR_COLOR
	air.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	air.ambient_light_color = STUDIO_AIR
	air.ambient_light_energy = STUDIO_AIR_ENERGY
	air.tonemap_mode = Environment.TONE_MAPPER_ACES
	var world := WorldEnvironment.new()
	world.environment = air
	viewport.add_child(world)
	for each: Array in STUDIO_LIGHTS:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = each[0]
		light.light_color = each[1]
		light.light_energy = each[2]
		# The key alone casts shadows.
		light.shadow_enabled = viewport.get_child_count() == 1
		viewport.add_child(light)
	return viewport


## [param front], drawn on nothing, laid over [param back], the two the same size.
static func over(back: Image, front: Image) -> Image:
	var out := back.duplicate() as Image
	out.convert(Image.FORMAT_RGBA8)
	var top := front.duplicate() as Image
	top.convert(Image.FORMAT_RGBA8)
	straighten(top)
	out.blend_rect(top, Rect2i(Vector2i.ZERO, top.get_size()), Vector2i.ZERO)
	out.convert(Image.FORMAT_RGB8)
	return out


## A carnival sunburst in [param ink]: its beams round the middle, lit there and dark at the
## corners.
class Sunburst:
	extends Control

	const BEAMS := 24
	var ink := HouseTheme.FOIL
	# Kept while it is drawn: a texture made in [method _draw] alone is freed when that returns,
	# and what is drawn of it is lost with it.
	var _glow: GradientTexture2D
	var _shade: GradientTexture2D

	func _draw() -> void:
		var middle := size * 0.5
		var reach := size.length()
		draw_rect(Rect2(Vector2.ZERO, size), ink.darkened(0.7))
		for i: int in BEAMS:
			var from := TAU * i / BEAMS
			var to := from + TAU / BEAMS * 0.5
			var beam := PackedVector2Array(
				[
					middle,
					middle + Vector2.from_angle(from) * reach,
					middle + Vector2.from_angle(to) * reach
				]
			)
			draw_colored_polygon(beam, ink.darkened(0.52))
		var dark := HouseTheme.STOCK_DOWN
		if _glow == null:
			_glow = _radial(
				Color(ink.lightened(0.25), 0.55), Color(ink, 0.12), Color(ink, 0.0), 1.0
			)
			_shade = _radial(Color(dark, 0.0), Color(dark, 0.0), Color(dark, 0.75), 1.15)
		draw_texture_rect(_glow, Rect2(Vector2.ZERO, size), false)
		draw_texture_rect(_shade, Rect2(Vector2.ZERO, size), false)

	## A round fade from [param inner] at the middle through [param mid] to [param outer], out to
	## [param reach] of the half side.
	static func _radial(inner: Color, mid: Color, outer: Color, reach: float) -> GradientTexture2D:
		var fade := GradientTexture2D.new()
		fade.fill = GradientTexture2D.FILL_RADIAL
		fade.fill_from = Vector2(0.5, 0.5)
		fade.fill_to = Vector2(0.5 + reach * 0.5, 0.5)
		fade.gradient = Gradient.new()
		fade.gradient.set_color(0, inner)
		fade.gradient.set_color(1, outer)
		fade.gradient.add_point(0.55, mid)
		return fade


## What [param viewport] shows after [param frames] frames, its pieces gone after.
func taken(viewport: SubViewport, frames: int) -> Image:
	for i: int in frames:
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if not viewport.transparent_bg:
		image.convert(Image.FORMAT_RGB8)
	viewport.queue_free()
	return image


## [param control] drawn on its own into a picture [param size] big, on nothing if
## [param clear], else on the house's stock.
func drawn(control: Control, size: Vector2i, clear := true) -> Image:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = clear
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if not clear:
		var stock := ColorRect.new()
		stock.color = HouseTheme.STOCK
		stock.size = Vector2(size)
		viewport.add_child(stock)
	viewport.add_child(control)
	add_child(viewport)
	var image := await taken(viewport, 3)
	if clear:
		straighten(image)
	return image


## A viewport cleared to nothing keeps what is drawn on it premultiplied, its colors darkened by how
## much of a pixel they cover; a picture file keeps them whole. Without this every soft edge would
## have a dark rim on a light page.
static func straighten(image: Image) -> void:
	var data := image.get_data()
	for i: int in range(0, data.size(), 4):
		var cover := data[i + 3]
		if cover == 0 or cover == 255:
			continue
		for channel: int in 3:
			data[i + channel] = mini(roundi(data[i + channel] * 255.0 / cover), 255)
	image.set_data(image.get_width(), image.get_height(), false, image.get_format(), data)


## [param image] at [param size] in [param path], a PNG or, by its name, a JPEG at
## [param quality].
static func save(image: Image, path: String, size: Vector2i, quality := 0.9) -> void:
	var scaled := image.duplicate() as Image
	if scaled.get_size() != size:
		scaled.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var jpeg := path.ends_with(".jpg")
	if jpeg and scaled.detect_alpha() != Image.ALPHA_NONE:
		scaled.convert(Image.FORMAT_RGB8)
	var saved := scaled.save_jpg(path, quality) if jpeg else scaled.save_png(path)
	if saved != OK:
		push_error("could not write %s" % path)
		return
	print("%s: %dx%d" % [path.trim_prefix("res://"), size.x, size.y])
