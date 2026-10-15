class_name RailMachines
extends Node3D
## The casino round the table, GAME.md 3.15: a row of slot machines standing on the far rail, each
## its own three reels in its face, as a casino's line of them stands along a wall. They light up
## and ring when anybody cashes out big: a halo round each lamp, a beam swinging round over each,
## their lights chasing along the row. When one kart empties a Jackpot pile it let grow full they
## do it for longer, to a cascade of chips and bells, and the chips fly off the pile.
##
## On the rail at the back of the table, the one the camera looks across: seen from where the
## camera stands they rise over the crowd behind it, never over the floor karts drive on. On every
## map with slot machines on its floor, see [SlotPad], and on no other.

## How many stand on the rail, and how far along it from the middle each does, as a share of half
## its length.
const ALONG: Array[float] = [-0.62, -0.22, 0.22, 0.62]
## A cabinet: its body, its reels' face, and how far that leans back toward the camera.
const BODY := Vector3(1.1, 1.4, 0.65)
const FACE := Vector2(0.96, 0.44)
const LEAN := 0.42
## A cash-out at least this big lights them up, for this long, in seconds; a Jackpot emptied whole
## for longer.
const BIG_BANK := 400
const LIT := 2.4
const JACKPOT_LIT := 4.5
## The halo round a lit lamp, how big across, and the beam that swings round over it: how long,
## how wide at its end, how far it leans out and how many turns a second.
const HALO := 1.5
const BEAM := 2.2
const BEAM_WIDE := 0.55
const BEAM_LEAN := 0.95
const BEAM_TURNS := 0.6
## How fast the lights chase while they are lit, a second.
const CHASE := 9.0

var _arena: Arena
var _faces: Array[ShaderMaterial] = []
var _lamps: Array[StandardMaterial3D] = []
## Each lamp's halo and the arm its beam turns on, shown only while the row is lit.
var _halos: Array[Sprite3D] = []
var _beams: Array[Node3D] = []
var _beam_look: StandardMaterial3D
var _lit := 0.0
## Who has been collecting the Jackpot's pile, and how much of it, since anybody else last did.
var _jar_slot := -1
var _jar_chips := 0


## Puts the row on [param arena]'s far rail, should its map have slot machines.
static func add_to(arena: Arena) -> void:
	if arena.grid == null or arena.grid.slot_pads.is_empty():
		return
	var machines := RailMachines.new()
	machines.name = "RailMachines"
	machines._arena = arena
	arena.add_child(machines)


func _ready() -> void:
	var half := _arena.world_size() * 0.5
	var rail := Vector3(0.0, _arena.layout.wall_height, -half.y + _arena.grid.cell_size * 0.5)
	_beam_look = StandardMaterial3D.new()
	_beam_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_look.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_look.albedo_color = Color(Palette.CHIP_GOLD, 0.0)
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(0.36, 0.06, 0.08)
	body.roughness = 0.45
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color(0.82, 0.82, 0.86)
	chrome.metallic = 0.8
	chrome.roughness = 0.25
	for i: int in ALONG.size():
		_cabinet(rail + Vector3(ALONG[i] * half.x, 0.0, 0.0), i, body, chrome)
	add_to_group(SlotPad.GROUP)
	_apply_strip()
	Events.bank_completed.connect(_on_bank_completed)
	Events.jackpot_collected.connect(_on_jackpot_collected)
	Events.jackpot_emptied.connect(_on_jackpot_emptied)


func _exit_tree() -> void:
	for pair: Array in [
		[Events.bank_completed, _on_bank_completed],
		[Events.jackpot_collected, _on_jackpot_collected],
		[Events.jackpot_emptied, _on_jackpot_emptied],
	]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])


func _cabinet(at: Vector3, index: int, body: Material, chrome: Material) -> void:
	var cabinet := Node3D.new()
	cabinet.name = "Machine%d" % index
	cabinet.position = at
	add_child(cabinet)
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = BODY
	box.mesh = box_mesh
	box.material_override = body
	box.position.y = BODY.y * 0.5
	cabinet.add_child(box)
	# Its reels, as a slot pad's are, leant back toward the camera, each machine showing its own.
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = FACE
	face.mesh = quad
	var look := ShaderMaterial.new()
	look.shader = SlotPad.LOOK
	look.set_shader_parameter(&"reel_at", Vector3(index % 6, (index * 2 + 1) % 6, (index + 4) % 6))
	face.material_override = look
	face.position = Vector3(0.0, BODY.y * 0.62, BODY.z * 0.5 + 0.02)
	face.rotation.x = -LEAN
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cabinet.add_child(face)
	_faces.append(look)
	# The lamp on top that turns when somebody wins, and the lever down its side.
	var lamp := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.12
	dome.height = 0.2
	lamp.mesh = dome
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Palette.CHIP_GOLD
	lit.emission_enabled = true
	lit.emission = Palette.CHIP_GOLD
	lit.emission_energy_multiplier = 0.2
	lamp.material_override = lit
	lamp.position = Vector3(0.0, BODY.y + 0.06, 0.0)
	cabinet.add_child(lamp)
	_lamps.append(lit)
	cabinet.add_child(_halo(lamp.position))
	cabinet.add_child(_beam(lamp.position))
	var lever := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.03
	rod.bottom_radius = 0.03
	rod.height = 0.5
	lever.mesh = rod
	lever.material_override = chrome
	lever.position = Vector3(BODY.x * 0.5 + 0.05, BODY.y * 0.75, 0.0)
	cabinet.add_child(lever)


## A glow round a lamp, turned to the camera, there only while the row is lit.
func _halo(at: Vector3) -> Sprite3D:
	var halo := Sprite3D.new()
	var glow := GradientTexture2D.new()
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.86, 0.45, 0.9))
	ramp.set_color(1, Color(1.0, 0.7, 0.2, 0.0))
	glow.gradient = ramp
	glow.width = 64
	glow.height = 64
	halo.texture = glow
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.shaded = false
	halo.transparent = true
	halo.no_depth_test = false
	halo.pixel_size = HALO / 64.0
	halo.modulate = Color(1.0, 1.0, 1.0, 0.0)
	halo.visible = false
	halo.position = at
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halos.append(halo)
	return halo


## A beam of light off a lamp, leaning out, on an arm that turns while the row is lit, as a
## cabinet's beacon swings round.
func _beam(at: Vector3) -> Node3D:
	var arm := Node3D.new()
	arm.position = at
	arm.visible = false
	var cone := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = BEAM_WIDE
	shape.bottom_radius = 0.02
	shape.height = BEAM
	shape.cap_top = false
	shape.cap_bottom = false
	cone.mesh = shape
	cone.material_override = _beam_look
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Its narrow end at the lamp, opening up and out from it.
	cone.rotation.x = BEAM_LEAN
	cone.position = Vector3(0.0, cos(BEAM_LEAN), sin(BEAM_LEAN)) * BEAM * 0.5
	arm.add_child(cone)
	_beams.append(arm)
	return arm


## The reels' strip once it has been drawn, see [method SlotPad._on_strip_ready].
func _on_strip_ready() -> void:
	_apply_strip()


func _apply_strip() -> void:
	var strip := KeptPictures.of(
		self,
		"slot_strip",
		SlotPad.STRIP_PIXELS,
		func() -> Control: return SlotPad.Strip.new(),
		SlotPad.GROUP,
		&"_on_strip_ready"
	)
	if strip != null:
		for face: ShaderMaterial in _faces:
			face.set_shader_parameter(&"strip", strip)


func _process(delta: float) -> void:
	if _lit <= 0.0:
		return
	_lit = maxf(_lit - delta, 0.0)
	var now := Time.get_ticks_msec() * 0.001
	var fading := minf(_lit, 1.0)
	for i: int in _faces.size():
		# The lights chase along the row, one machine after the next.
		var on := 0.5 + 0.5 * sin(now * CHASE - i * 1.3)
		_faces[i].set_shader_parameter(&"lit", on * fading)
		_lamps[i].emission_energy_multiplier = 0.2 + 3.0 * on * fading
		_halos[i].visible = _lit > 0.0
		_halos[i].modulate.a = (0.45 + 0.55 * on) * fading
		_halos[i].scale = Vector3.ONE * (0.8 + 0.4 * on)
		_beams[i].visible = _lit > 0.0
		# Each beam swings round, the next machine's half a turn behind.
		_beams[i].rotation.y = TAU * (now * BEAM_TURNS + i * 0.5)
	_beam_look.albedo_color = Color(Palette.CHIP_GOLD, 0.32 * fading)


func _light(seconds: float) -> void:
	_lit = maxf(_lit, seconds)


## Lights the row for [param seconds], for something worth it on the floor: three sevens.
func cheer(seconds: float) -> void:
	_light(seconds)


func _on_bank_completed(_slot: int, _coins: int, _mult: float, total: int) -> void:
	if total >= BIG_BANK:
		_light(LIT)
		Audio.play_sfx(&"slot_bell", -10.0, 0.05)


func _on_jackpot_collected(slot: int, chips: int) -> void:
	if slot != _jar_slot:
		_jar_slot = slot
		_jar_chips = 0
	_jar_chips += chips


## A pile gone: emptied whole by one kart, a pile let grow to the rules' cap, the row lights up for
## longer than a cash-out's, to chips and bells, and the chips fly off it. A siren was too much for
## something that happens a few times a map.
func _on_jackpot_emptied(zone_index: int) -> void:
	var full := _jar_slot >= 0 and zone_index < _arena.jackpot_zones.size()
	if full:
		var zone := _arena.jackpot_zones[zone_index]
		full = zone.rules != null and _jar_chips >= zone.rules.jackpot_cap
		if full:
			var at := zone.global_position
			Burst.spawn(_arena, at + Vector3(0.0, 0.4, 0.0), Palette.CHIP_GOLD, 2.2, 48)
			FloatingText.spawn(_arena, at, "JACKPOT!", Palette.CHIP_GOLD, 80, 2.2)
	_jar_slot = -1
	_jar_chips = 0
	if full:
		_light(JACKPOT_LIT)
		Audio.play_sfx(&"chips_scatter", -2.0)
		Audio.play_sfx(&"slot_bell", -4.0, 0.0)
