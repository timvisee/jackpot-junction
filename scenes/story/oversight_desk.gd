class_name OversightDesk
extends Node3D
## The oversight desk, STORY.md 8.5: the 3D scene the story's last lines play over, in place of the
## flat HUMAN OVERSIGHT board. A dark office, an almost bare desk under a green banker's lamp: the
## five-tube nixie counter of GAME.md, a printer feeding out the House's APPROVED sheet, the
## player's kart as a little statue with its plate on a plaque, and the approval station the human's
## job needs, a rubber stamp on its pad, a pen and a big red button. [LastLines] gives it a world of
## its own, see [method add_to], and plays it as a short slow film: the counter glows alone in the
## dark, the lamp clicks on, the counter strikes from 0 to 1 while the big button is pressed, and a
## hand pulls the lamp off so everything goes out to a black hush. It says [signal settled] at that
## hush, for [LastLines] to take the last line on from there.

## Said once the counter has struck and the lamp is pulled off into the dark: the cue for the lines.
signal settled

## The height of the desk's top, where everything stands.
const DESK := 0.78
## The five tubes' reading, a counter dressed for thousands over a tally that never passes one.
const COUNT := "00001"
const NEON := Color(1.0, 0.55, 0.2)
## The gold of the House's foil, for the statue's little plaque.
const FOIL := Color(0.95, 0.76, 0.33)
## How small the player's kart stands as a statue, against its size on the road.
const STATUE := 0.12
## The yaw the statue is turned to so it shows its nose, and the world yaw the nose then points at,
## which the plaque is squared to, see [method _plaque]: the nose is the turn swung half round.
const STATUE_TURN := 200.0
const STATUE_FACE := 20.0
## How thick the desk blotter is, so what stands on it stands that much above the bare wood.
const MAT := 0.012
## The lamp's spot, the counter's lights and the cool back rim at full, once they are turned on. The
## rim comes and goes with the lamp, so with the lamp off there is nothing to light the room but the
## counter's own glow, and once that too is out, nothing at all.
const LAMP_LIT := 2.5
const BULB_LIT := 1.4
const SHADE_LIT := 1.1
const TUBE_LIT := 0.5
const RIM_LIT := 0.16
## How far the chain stretches from its fixed top on a tug, over its rest length: the knob drops
## about 0.022 while the top stays joined to the lamp, see [method _tug_cord].
const CORD_STRETCH := 1.44
## The stamp's heights over its resting spot, see [method _stamp_it]: how far it is lifted to be
## carried, how low it is set to ink on the pad, and how low to strike the slip.
const STAMP_LIFT := 0.08
const STAMP_PAD := 0.019
const STAMP_SLIP := 0.006

## The parts the little film turns on and moves, kept dark or still until their cue, see [method
var _spot: SpotLight3D
var _bulb_mat: StandardMaterial3D
var _shade_mat: StandardMaterial3D
var _zeros: Array[Label3D] = []
var _one: Label3D
var _tube_lights: Array[OmniLight3D] = []
var _cap: Label3D
var _paper: Node3D
## The chain's fixed anchor at the lamp, stretched down for a tug, and the knob on its end, kept
## round as the chain stretches, see [method _tug_cord].
var _cord: Node3D
var _knob: Node3D
var _button_dome: MeshInstance3D
## The rubber stamp, moved to ink and strike the slip before the button, see [method _stamp_it]: the
## body that lifts and swings, its resting spot, the ink pad and the slip it is carried between, the
## die that takes the red ink, and the APPROVED mark it leaves, hidden until it is struck down.
var _stamp_body: Node3D
var _stamp_rest: Vector3
var _pad_at: Vector3
var _slip_at: Vector3
var _die_mat: StandardMaterial3D
var _mark: Label3D
## The printed and engraved labels that the lamp lights: unlit of themselves, they are hidden until
## the lamp is on and hidden again when it is pulled off, so nothing is read in the dark.
var _lit_labels: Array[Label3D] = []
var _cam: Camera3D
## The desk's own dark environment, set on the camera so the arena's daylight never reaches it, and
## the cool back rim that comes and goes with the lamp.
var _env: Environment
var _rim: DirectionalLight3D


## Builds the desk under [param host] and hands it back; the caller starts it with [method play].
## [LastLines] gives it a world of its own, a [SubViewport], so the match it stands over is never
## touched, the way the flat board was only ever drawn over it.
static func add_to(host: Node) -> OversightDesk:
	var desk := OversightDesk.new()
	desk.name = "OversightDesk"
	host.add_child(desk)
	return desk


func _ready() -> void:
	# The ending plays over a paused match, STORY.md 8.5, so the film must run on regardless.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lighting()
	_room()
	_desk()
	_blotter()
	_lamp()
	_counter()
	_printer()
	_statue()
	_approval()
	_camera()


## A material: a soft matte surface by default, wood or paint or stock that barely catches a
## highlight, or a lit metal where [param metal] is set, or one glowing of its own light. A
## dielectric keeps next to no specular, so nothing but the metals and the glowing glass shines.
func _skin(
	color: Color, rough := 0.9, metal := 0.0, glow := Color.BLACK, energy := 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.metallic = metal
	material.metallic_specular = 0.5 if metal > 0.01 else 0.08
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = energy
	return material


## The dark room: next to no ambient, a warm filmic look, a touch of fog for depth, and the bloom
## that makes the lamp and the tubes glow. Kept on the camera, see [method _camera], not a
## WorldEnvironment, so the arena's own daylight behind it is never the desk's.
func _lighting() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.01, 0.01, 0.014)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.12, 0.13, 0.2)
	# Barely any ambient, so with the lamp off the desk is as good as black: nothing shows until the
	# lamp is on, STORY.md 8.5, bar the counter's own glow, and nothing is left once it is pulled off.
	_env.ambient_light_energy = 0.012
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_white = 2.0
	_env.glow_enabled = true
	_env.glow_intensity = 0.9
	_env.glow_bloom = 0.25
	_env.glow_hdr_threshold = 0.75
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.03, 0.025, 0.03)
	_env.fog_density = 0.03
	# A faint cool rim from up behind, so once the lamp is lit the dark shapes keep an edge against
	# the black rather than melting into it; off until the lamp is, so it adds nothing in the dark.
	_rim = DirectionalLight3D.new()
	_rim.light_color = Color(0.5, 0.58, 0.85)
	_rim.light_energy = 0.0
	_rim.rotation_degrees = Vector3(-28.0, 158.0, 0.0)
	add_child(_rim)


## The floor and two walls, all dark, so the desk stands in a pool of its own light with the room
## falling away into the black around it.
func _room() -> void:
	var wall := _skin(Color(0.05, 0.05, 0.055), 0.95)
	var floor := _skin(Color(0.07, 0.06, 0.055), 0.9)
	ToyParts.box(self, Vector3(9.0, 0.2, 7.0), floor, Vector3(0.0, -0.1, 0.0))
	ToyParts.box(self, Vector3(9.0, 5.0, 0.2), wall, Vector3(0.0, 2.5, -1.9))
	ToyParts.box(self, Vector3(0.2, 5.0, 7.0), wall, Vector3(-3.4, 2.5, 0.0))


## The desk: a dark wooden top on four square legs, the wood soft and matte, barely a sheen on it.
func _desk() -> void:
	var top := _skin(Color(0.19, 0.12, 0.07), 0.94)
	var leg := _skin(Color(0.12, 0.08, 0.05), 0.95)
	ToyParts.box(self, Vector3(2.3, 0.07, 1.15), top, Vector3(0.0, DESK - 0.035, 0.0))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var tall := DESK - 0.07
			ToyParts.box(
				self, Vector3(0.08, tall, 0.08), leg, Vector3(sx * 1.05, tall * 0.5, sz * 0.5)
			)


## A leather desk blotter under the counter and the approval things, a dark green felt inset in it,
## tying to the lamp's green, so the pieces stand on a pad rather than on the bare wood.
func _blotter() -> void:
	var leather := _skin(Color(0.13, 0.08, 0.05), 0.7, 0.1)
	var felt := _skin(Color(0.05, 0.13, 0.08), 0.96)
	var mid := Vector3(0.02, DESK, 0.16)
	ToyParts.box(self, Vector3(1.26, 0.012, 0.58), leather, mid + Vector3(0.0, 0.004, 0.0))
	ToyParts.box(self, Vector3(1.1, 0.008, 0.46), felt, mid + Vector3(0.0, 0.008, 0.0))


## The approving things along the near edge, the one job the human has: a rubber stamp by its red
## pad to stamp the House's decisions through, a fountain pen to sign the name, and a big red button
## that approves all at a press. The dark joke of GAME.md's last line, stood on the desk.
func _approval() -> void:
	_stamp(Vector3(0.21, DESK + MAT, 0.33))
	_slip(Vector3(0.04, DESK + MAT, 0.44))
	_pen(Vector3(-0.12, DESK + MAT, 0.34))
	_button(Vector3(0.49, DESK + MAT, 0.29))


## A rubber stamp by its red ink pad: a turned wooden handle on a wooden base, the rubber die under
## it that takes the ink, the inked pad in its case beside it. The pad stands still; the stamp hangs
## off its own body so it can be lifted and carried to ink the die and strike the slip, see [method
## _stamp_it], and the die has its own material so it can come up red without reddening the case.
func _stamp(at: Vector3) -> void:
	_stamp_rest = at
	_pad_at = at + Vector3(0.14, 0.0, -0.015)
	var wood := _skin(Color(0.28, 0.15, 0.07), 0.6)
	var dark := _skin(Color(0.08, 0.07, 0.07), 0.6)
	ToyParts.rounded(
		self, Vector3(0.1, 0.016, 0.076), 0.01, dark, _pad_at + Vector3(0.0, 0.008, 0.0), 6
	)
	var ink := _skin(Color(0.52, 0.07, 0.06), 0.85)
	ToyParts.box(self, Vector3(0.082, 0.004, 0.058), ink, _pad_at + Vector3(0.0, 0.017, 0.0))
	_stamp_body = Node3D.new()
	_stamp_body.position = at
	add_child(_stamp_body)
	ToyParts.rounded(
		_stamp_body, Vector3(0.09, 0.022, 0.06), 0.012, wood, Vector3(0.0, 0.015, 0.0), 6
	)
	_die_mat = _skin(Color(0.08, 0.07, 0.07), 0.6)
	ToyParts.box(_stamp_body, Vector3(0.082, 0.012, 0.052), _die_mat, Vector3(0.0, 0.004, 0.0))
	ToyParts.cylinder(_stamp_body, 0.009, 0.045, wood, Vector3(0.0, 0.048, 0.0), 10)
	ToyParts.dome(_stamp_body, 0.028, 0.03, wood, Vector3(0.0, 0.07, 0.0), 12)


## The slip the stamp strikes: a small printed form lying on the desk before the station, turned a
## touch, a few ruled lines across it. It wears the red APPROVED mark the stamp leaves, lying flat,
## struck a little askew, kept dark until the die comes down on it, see [method _stamp_down].
func _slip(at: Vector3) -> void:
	_slip_at = at
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = deg_to_rad(-9.0)
	add_child(holder)
	var paper := _skin(Color(0.92, 0.9, 0.84), 0.9)
	ToyParts.box(holder, Vector3(0.14, 0.004, 0.18), paper, Vector3(0.0, 0.002, 0.0))
	var ruled := _skin(Color(0.72, 0.69, 0.64), 0.95)
	for i: int in 5:
		var row := Vector3(0.0, 0.0042, -0.055 + float(i) * 0.026)
		ToyParts.box(holder, Vector3(0.1, 0.001, 0.003), ruled, row)
	_mark = Label3D.new()
	_mark.text = "APPROVED"
	_mark.font = Type.STRONG
	_mark.font_size = 40
	_mark.pixel_size = 0.0007
	_mark.modulate = Color(0.68, 0.09, 0.07)
	_mark.shaded = false
	# Hidden outright, not just made clear: lying flat a hair over the slip it would still cast a
	# shadow of itself and read as a dark mark; it is shown only when the stamp strikes, see
	# [method _stamp_down].
	_mark.visible = false
	_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark.rotation_degrees = Vector3(-90.0, 0.0, 14.0)
	_mark.position = Vector3(0.0, 0.0055, 0.0)
	holder.add_child(_mark)


## A capped fountain pen lying across the blotter, a gold nib at its tip and a gold band at its cap,
## turned a little so it reads as left down rather than set out.
func _pen(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = deg_to_rad(-26.0)
	add_child(holder)
	var resin := _skin(Color(0.05, 0.05, 0.09), 0.3, 0.2)
	var gold := _skin(Color(0.72, 0.56, 0.22), 0.3, 0.9)
	var barrel := ToyParts.cylinder(holder, 0.008, 0.1, resin, Vector3(0.01, 0.008, 0.0), 12)
	barrel.rotation.z = deg_to_rad(90.0)
	var cap := ToyParts.cylinder(holder, 0.009, 0.042, resin, Vector3(-0.058, 0.008, 0.0), 12)
	cap.rotation.z = deg_to_rad(90.0)
	var band := ToyParts.cylinder(holder, 0.0094, 0.006, gold, Vector3(-0.038, 0.008, 0.0), 12)
	band.rotation.z = deg_to_rad(90.0)
	var nib := ToyParts.taper(holder, 0.0, 0.007, 0.022, gold, Vector3(0.072, 0.008, 0.0), 10)
	nib.rotation.z = deg_to_rad(90.0)


## A big red button, the one the human presses to approve all the decisions at once: a red dome in a
## dark housing with a ring round it, APPROVE on the front.
func _button(at: Vector3) -> void:
	var housing := _skin(Color(0.11, 0.11, 0.12), 0.6, 0.2)
	var ring := _skin(Color(0.04, 0.04, 0.05), 0.6)
	var red := _skin(Color(0.62, 0.08, 0.06), 0.4)
	ToyParts.cylinder(self, 0.072, 0.03, housing, at + Vector3(0.0, 0.015, 0.0), 24)
	ToyParts.cylinder(self, 0.064, 0.01, ring, at + Vector3(0.0, 0.032, 0.0), 24)
	_button_dome = ToyParts.dome(self, 0.056, 0.036, red, at + Vector3(0.0, 0.03, 0.0), 22)
	var label := Label3D.new()
	label.text = "APPROVE"
	label.font = Type.STRONG
	label.font_size = 26
	label.pixel_size = 0.00034
	label.modulate = Color(0.86, 0.83, 0.8, 0.0)
	label.shaded = false
	label.position = at + Vector3(0.0, 0.016, 0.073)
	add_child(label)
	_lit_labels.append(label)


## The classic green banker's lamp, turned a touch off square: a weighted two-tier oval brass base,
## a brass column up its middle, and the wide emerald glass shade over it, a shallow trough that
## glows green of its own while a warm bulb under it throws the room's one pool across the desk.
## Its parts hang off a holder so the whole lamp turns as one, and its pull chain can be tugged, see
## [method _pull_cord]. The spot is the room's, aimed at the desk whichever way the lamp faces.
func _lamp() -> void:
	var brass := _skin(Color(0.58, 0.42, 0.19), 0.3, 0.95)
	var foot := Vector3(-0.5, DESK, -0.16)
	var lamp := Node3D.new()
	lamp.position = foot
	lamp.rotation.y = deg_to_rad(21.0)
	add_child(lamp)
	ToyParts.rounded(lamp, Vector3(0.34, 0.018, 0.2), 0.09, brass, Vector3(0.0, 0.009, 0.0), 14)
	ToyParts.rounded(lamp, Vector3(0.22, 0.016, 0.13), 0.055, brass, Vector3(0.0, 0.024, 0.0), 10)
	ToyParts.cylinder(lamp, 0.014, 0.16, brass, Vector3(0.0, 0.1, 0.0), 12)
	# The shade: a wide, shallow half-cylinder trough, flattened and trimmed in brass along its edges.
	var glass := _skin(Color(0.05, 0.22, 0.11), 0.25, 0.1, Color(0.06, 0.42, 0.18), SHADE_LIT)
	_shade_mat = glass
	_shade_mat.emission_energy_multiplier = 0.0
	var shade := ToyParts.cylinder(lamp, 0.092, 0.46, glass, Vector3(0.0, 0.19, 0.0), 32)
	shade.rotation.z = deg_to_rad(90.0)
	shade.scale = Vector3(0.56, 1.0, 1.0)
	for edge: float in [-0.088, 0.088]:
		var rim := ToyParts.cylinder(lamp, 0.005, 0.46, brass, Vector3(0.0, 0.162, edge), 8)
		rim.rotation.z = deg_to_rad(90.0)
	# The pull chain at the front. Its anchor is fixed at the lamp so the chain's top stays joined to
	# the housing; a tug stretches the anchor down, lengthening the chain, see [method _tug_cord].
	_cord = Node3D.new()
	_cord.position = Vector3(0.12, 0.158, 0.09)
	lamp.add_child(_cord)
	# The chain link: its top sits at the anchor, so stretching the anchor grows it straight downward.
	ToyParts.cylinder(_cord, 0.0028, 0.05, brass, Vector3(0.0, -0.025, 0.0), 6)
	# The knob on the end, its own node so the stretch can be undone on it and it stays round.
	_knob = Node3D.new()
	_knob.position = Vector3(0.0, -0.052, 0.0)
	_cord.add_child(_knob)
	ToyParts.ball(_knob, 0.008, brass, Vector3.ZERO)
	var bulb := _skin(Color(1.0, 0.92, 0.76), 0.5, 0.0, Color(1.0, 0.88, 0.62), BULB_LIT)
	_bulb_mat = bulb
	_bulb_mat.emission_energy_multiplier = 0.0
	ToyParts.ball(lamp, 0.022, bulb, Vector3(0.0, 0.17, 0.0))
	_spot = SpotLight3D.new()
	_spot.light_color = Color(1.0, 0.89, 0.66)
	_spot.light_energy = 0.0
	_spot.spot_range = 3.8
	_spot.spot_angle = 75.0
	_spot.spot_angle_attenuation = 0.65
	_spot.position = foot + Vector3(0.0, 0.17, 0.0)
	add_child(_spot)
	_spot.look_at(global_position + foot + Vector3(0.7, DESK - 1.0, 0.7), Vector3.UP)


## The HUMAN OVERSIGHT counter: a dark housing with five little glass tubes along it, each with a
## glowing orange numeral and a point of light of its own. It is lit of itself from the start, the
## one thing alight in the dark before the lamp, and reads the zeros until it is struck to one.
func _counter() -> void:
	var housing := _skin(Color(0.1, 0.1, 0.12), 0.6, 0.15)
	var middle := Vector3(0.0, DESK + MAT, 0.0)
	ToyParts.box(self, Vector3(0.44, 0.06, 0.11), housing, middle + Vector3(0.0, 0.03, 0.0))
	_cap = _caption(middle + Vector3(0.0, 0.036, 0.057))
	var glass := _skin(Color(0.05, 0.04, 0.05), 0.12, 0.1)
	for i: int in COUNT.length():
		var at := middle + Vector3(-0.17 + float(i) * 0.085, 0.105, 0.015)
		ToyParts.cylinder(self, 0.03, 0.09, glass, at)
		_zeros.append(_digit(at, "0"))
		var glow := OmniLight3D.new()
		glow.light_color = NEON
		glow.light_energy = TUBE_LIT
		glow.omni_range = 0.45
		glow.position = at + Vector3(0.0, 0.0, 0.04)
		add_child(glow)
		_tube_lights.append(glow)
	# The units tube's 1, dark until it is struck over the 0.
	var units := middle + Vector3(-0.17 + float(COUNT.length() - 1) * 0.085, 0.105, 0.015)
	_one = _digit(units, "1")
	_one.modulate.a = 0.0


## One glowing numeral [param ch] standing in its tube, lit from the start as the counter's glow.
func _digit(at: Vector3, ch: String) -> Label3D:
	var lit := Label3D.new()
	lit.text = ch
	lit.font = Type.STRONG
	lit.font_size = 64
	lit.pixel_size = 0.0013
	lit.modulate = NEON
	lit.shaded = false
	lit.position = at + Vector3(0.0, 0.0, 0.031)
	add_child(lit)
	return lit


## HUMAN OVERSIGHT across the housing's face, small, lit from the start with the counter's own glow.
func _caption(at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = StoryLines.OVERSIGHT_BOARD
	label.font = Type.STRONG
	label.font_size = 28
	label.pixel_size = 0.0007
	label.modulate = Color(0.85, 0.6, 0.35)
	label.shaded = false
	label.position = at
	add_child(label)
	return label


## A dot-matrix printer on the other side, a sheet rising from its feed and leaning toward the
## camera, the House's approval record printed on its face: APPROVED and a few ruled lines.
func _printer() -> void:
	var body := _skin(Color(0.16, 0.16, 0.17), 0.75)
	var base := Vector3(0.56, DESK, -0.12)
	ToyParts.box(self, Vector3(0.38, 0.14, 0.3), body, base + Vector3(0.0, 0.07, 0.0))
	var feed := _skin(Color(0.03, 0.03, 0.03), 0.5)
	ToyParts.box(self, Vector3(0.3, 0.02, 0.04), feed, base + Vector3(0.0, 0.14, -0.08))
	var sheet := _skin(Color(0.93, 0.91, 0.86), 0.9)
	_paper = Node3D.new()
	_paper.position = base + Vector3(0.0, 0.15, -0.06)
	_paper.rotation.x = deg_to_rad(16.0)
	add_child(_paper)
	ToyParts.box(_paper, Vector3(0.26, 0.34, 0.004), sheet, Vector3(0.0, 0.17, 0.0))
	_sheet_text(_paper)


## The print on the sheet's face, toward the camera: the heading in a worn ink, then ruled lines of
## what was approved, each a thin dark bar as a glance at a page of them reads.
func _sheet_text(paper: Node3D) -> void:
	var heading := Label3D.new()
	heading.text = "APPROVED"
	heading.font = Type.STRONG
	heading.font_size = 48
	heading.pixel_size = 0.00092
	heading.modulate = Color(0.22, 0.19, 0.16, 0.0)
	heading.shaded = false
	heading.position = Vector3(0.0, 0.29, 0.004)
	paper.add_child(heading)
	_lit_labels.append(heading)
	var ink := _skin(Color(0.26, 0.23, 0.2), 0.95)
	for row: int in 6:
		var line := ToyParts.box(paper, Vector3(0.2, 0.01, 0.002), ink, Vector3.ZERO)
		line.position = Vector3(0.0, 0.22 - float(row) * 0.042, 0.003)


## The player's own kart, small, a statue on a little plinth at the near edge of the desk: dressed
## the way they dress it, its paint and hat and trail and the plate on its back, and under it a
## plaque in the House's foil, the license plate's words engraved as a museum labels its piece.
func _statue() -> void:
	var seat := _player()
	var base := Vector3(-0.52, DESK + MAT, 0.2)
	ToyParts.cylinder(self, 0.1, 0.024, _skin(Color(0.13, 0.1, 0.08), 0.7, 0.15), base, 24)
	var cap := _skin(Color(0.17, 0.13, 0.09), 0.55, 0.3)
	ToyParts.cylinder(self, 0.084, 0.016, cap, base + Vector3(0.0, 0.02, 0.0), 24)
	var holder := Node3D.new()
	holder.position = base + Vector3(0.0, 0.028, 0.0)
	holder.scale = Vector3.ONE * STATUE
	# Turned to show its nose to the camera rather than its back, GAME.md 3.8.
	holder.rotation.y = deg_to_rad(STATUE_TURN)
	add_child(holder)
	var kart := KartVisuals.display_model(seat["color"], seat["style"])
	kart.position.y = -KartVisuals.MODEL_LIFT
	KartVisuals.plate_like(kart, seat["plate"])
	_unglow(kart)
	holder.add_child(kart)
	_plaque(base, seat["plate"])


## Kills any glow on the statue's kart, so it stands as a plain painted model lit only by the lamp,
## not a light of its own: each material it wears is duplicated matte, with its emission off. A part
## painted with a single override wears it over every surface, and is dulled there; one that wears
## its own per-surface materials from the model is dulled a surface at a time. Dulling the override
## in place matters: a surface override set under a standing one never shows, and setting one there
## drives a null-material error through the renderer, seen as the desk ending plays over the match.
func _unglow(kart: Node3D) -> void:
	for node: Node in kart.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var painted := mesh.material_override as StandardMaterial3D
		if painted != null:
			mesh.material_override = _matte(painted)
			continue
		if mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var worn := mesh.get_active_material(surface) as StandardMaterial3D
			if worn != null:
				mesh.set_surface_override_material(surface, _matte(worn))


## A matte copy of [param lit]: the same surface, its glow switched off.
func _matte(lit: StandardMaterial3D) -> StandardMaterial3D:
	var dull := lit.duplicate() as StandardMaterial3D
	dull.emission_enabled = false
	return dull


## The player whose ending this is, for the statue: their own seat's color and dress, and the plate
## they earned, GAME.md 4.4, the learner's L standing in for one not yet won.
func _player() -> Dictionary:
	var settings := Game.settings
	var plate := KartVisuals.plate_here()
	return {
		"color": settings.seat_color(0),
		"style": KartStyle.from_array(settings.seat_style(0)),
		"plate": plate if plate != "L" else settings.seat_name(0),
	}


## The plaque on the plinth, a dark little plate leaning back with the license words in the House's
## foil; turned to the kart's nose so it squares with the front the statue shows rather than the
## camera. The statue stands at [constant STATUE_FACE] of yaw, so the plate sits and faces there.
func _plaque(base: Vector3, text: String) -> void:
	var yaw := deg_to_rad(STATUE_FACE)
	var out := Vector3(sin(yaw), 0.0, cos(yaw))
	var at := base + Vector3(0.0, 0.03, 0.0) + out * 0.088
	var plate := ToyParts.box(
		self, Vector3(0.12, 0.024, 0.006), _skin(Color(0.09, 0.08, 0.07), 0.35, 0.8), at
	)
	plate.rotation = Vector3(deg_to_rad(-14.0), yaw, 0.0)
	var label := Label3D.new()
	label.text = text.to_upper()
	label.font = Type.STRONG
	label.font_size = 40
	label.pixel_size = 0.00034
	label.modulate = Color(FOIL.r, FOIL.g, FOIL.b, 0.0)
	label.shaded = false
	label.rotation_degrees = Vector3(-14.0, STATUE_FACE, 0.0)
	label.position = at + out * 0.005 + Vector3(0.0, 0.005, 0.0)
	add_child(label)
	_lit_labels.append(label)


## The shot: low and close from the front, the counter at its heart, the lamp and the printer to
## either side, the room dark beyond.
func _camera() -> void:
	_cam = Camera3D.new()
	_cam.fov = 46.0
	_cam.environment = _env
	# Square to the desk: the eye is straight in front of where it looks, so the desk's front edge
	# reads level across the frame rather than skewing off at an angle.
	_cam.position = Vector3(0.03, DESK + 0.52, 1.68)
	add_child(_cam)
	# The target is in the desk's own space, which may be set far off the arena, see [constant AWAY].
	_cam.look_at(global_position + Vector3(0.03, DESK + 0.13, 0.12), Vector3.UP)
	_cam.make_current()


## Plays the film, slow and in a few plain beats. The counter glows the whole time it is lit: it is
## alight of itself in the dark before the lamp, see [method _counter]. The caller lifts the stock
## to show it, see [LastLines], then the lamp clicks on and the desk stands lit; the human inks the
## stamp and strikes the slip APPROVED, see [method _stamp_it], then presses the big button and
## the counter strikes from 0 to 1; a hand pulls the lamp off and everything goes out at once to a
## black hush. The stamp beat carries the film on through the button to the pull; at the hush, after
## the light is pulled, [method _go_dark] says [signal settled].
func play() -> void:
	var film := create_tween()
	film.tween_interval(2.6)
	film.tween_callback(_lamp_on)
	film.tween_interval(1.4)
	film.tween_callback(_stamp_it)


## The lamp clicks on all at once, no fading in: the spot and both glows snap to full with the
## switch, and the printed and engraved labels the lamp lights come up with it.
func _lamp_on() -> void:
	Audio.play_sfx(&"item_use", -11.0, 0.0)
	_tug_cord()
	_spot.light_energy = LAMP_LIT
	_bulb_mat.emission_energy_multiplier = BULB_LIT
	_shade_mat.emission_energy_multiplier = SHADE_LIT
	_rim.light_energy = RIM_LIT
	for label: Label3D in _lit_labels:
		label.modulate.a = 1.0


## Before the button: the human inks the stamp and strikes the slip. The stamp lifts off the desk,
## is carried over the pad and pressed into the ink, carried over the slip and struck down to leave
## the red APPROVED mark, then set back by its pad. Only then is the button pressed and the counter
## struck, see [method _click], and after a beat the lamp is pulled, see [method _pull_cord]; one
## chain of tweens carries the film through all of it so each beat waits on the last.
func _stamp_it() -> void:
	var hi := _stamp_rest.y + STAMP_LIFT
	var seq := create_tween()
	seq.set_trans(Tween.TRANS_SINE)
	seq.tween_property(_stamp_body, "position:y", hi, 0.3).set_ease(Tween.EASE_OUT)
	seq.tween_property(_stamp_body, "position", Vector3(_pad_at.x, hi, _pad_at.z), 0.45)
	var pad_y := _stamp_rest.y + STAMP_PAD
	seq.tween_property(_stamp_body, "position:y", pad_y, 0.16).set_ease(Tween.EASE_IN)
	seq.tween_callback(_ink)
	seq.tween_property(_stamp_body, "position:y", hi, 0.22).set_ease(Tween.EASE_OUT)
	seq.tween_property(_stamp_body, "position", Vector3(_slip_at.x, hi, _slip_at.z), 0.5)
	var slip_y := _stamp_rest.y + STAMP_SLIP
	seq.tween_property(_stamp_body, "position:y", slip_y, 0.13).set_ease(Tween.EASE_IN)
	seq.tween_callback(_stamp_down)
	seq.tween_property(_stamp_body, "position:y", hi, 0.22).set_ease(Tween.EASE_OUT)
	seq.tween_property(_stamp_body, "position", _stamp_rest, 0.4).set_ease(Tween.EASE_IN_OUT)
	seq.tween_interval(1.1)
	seq.tween_callback(_click)
	seq.tween_interval(2.2)
	seq.tween_callback(_pull_cord)


## The stamp pressed into the pad: a soft dab, and the rubber die comes up red with ink.
func _ink() -> void:
	Audio.play_sfx(&"ui_click", -14.0, 0.0)
	_die_mat.albedo_color = Color(0.6, 0.09, 0.08)


## The stamp struck down on the slip: the thud, and the red APPROVED mark is left behind at once.
func _stamp_down() -> void:
	Audio.play_sfx(&"stamp", -4.0, 0.0)
	_mark.visible = true


## The pull chain jerked down and back, as a hand tugs it to click the lamp on or off. The anchor's
## top stays fixed at the lamp; the chain stretches down from it and springs back, the knob riding
## the end, its own stretch undone so it stays round rather than drawing into an egg.
func _tug_cord() -> void:
	var pull := create_tween()
	pull.tween_property(_cord, "scale:y", CORD_STRETCH, 0.07).set_ease(Tween.EASE_OUT)
	pull.tween_property(_cord, "scale:y", 1.0, 0.16).set_ease(Tween.EASE_IN)
	var keep := create_tween()
	keep.tween_property(_knob, "scale:y", 1.0 / CORD_STRETCH, 0.07).set_ease(Tween.EASE_OUT)
	keep.tween_property(_knob, "scale:y", 1.0, 0.16).set_ease(Tween.EASE_IN)


## The units tube strikes from 0 to 1, the stamp's thud and a sharper electric crackle under it, so
## the eye is pulled to the counter: the 0 goes out at once, the 1 catches in fits as the gas takes,
## its tube flaring and guttering before it holds, and the whole row jumps once with the strike then
## eases back. The big red button presses in and springs back, so the thud lands on something moved.
func _click() -> void:
	Audio.play_sfx(&"stamp", -5.0, 0.0)
	Audio.play_sfx(&"zap", -12.0, 0.12, 1.5)
	var last := _zeros.size() - 1
	# The 0 cuts out; the 1 strikes in stuttering, the gas catching in fits before it holds.
	_zeros[last].modulate.a = 0.0
	var blink := create_tween()
	blink.tween_property(_one, "modulate:a", 1.0, 0.03)
	blink.tween_property(_one, "modulate:a", 0.15, 0.05)
	blink.tween_property(_one, "modulate:a", 1.0, 0.04)
	blink.tween_property(_one, "modulate:a", 0.3, 0.05)
	blink.tween_property(_one, "modulate:a", 1.0, 0.12)
	# Its tube's glow flares and gutters with the flicker, then settles to the steady burn.
	var flick := create_tween()
	flick.tween_property(_tube_lights[last], "light_energy", 1.7, 0.03)
	flick.tween_property(_tube_lights[last], "light_energy", 0.2, 0.05)
	flick.tween_property(_tube_lights[last], "light_energy", 1.4, 0.04)
	flick.tween_property(_tube_lights[last], "light_energy", 0.3, 0.05)
	flick.tween_property(_tube_lights[last], "light_energy", 1.2, 0.04)
	flick.tween_property(_tube_lights[last], "light_energy", TUBE_LIT, 0.35)
	# The rest of the row jumps once with the strike, pulling the eye to it, then eases back.
	for i: int in last:
		var pulse := create_tween()
		pulse.tween_property(_tube_lights[i], "light_energy", 0.9, 0.06)
		pulse.tween_property(_tube_lights[i], "light_energy", TUBE_LIT, 0.45)
	var brest := _button_dome.position.y
	var press := create_tween()
	press.tween_property(_button_dome, "position:y", brest - 0.016, 0.06)
	press.tween_property(_button_dome, "position:y", brest, 0.16).set_ease(Tween.EASE_OUT)


## A hand pulls the lamp's chain. The chain is seen to jerk with the lamp still lit, and at the foot
## of the pull the lamp clicks off, see [method _go_dark]: no fade, the eye sees the pull and then
## the room is black at once.
func _pull_cord() -> void:
	# The same switch the lamp was turned on with, so off sounds like on, see [method _lamp_on].
	Audio.play_sfx(&"item_use", -11.0, 0.0)
	_tug_cord()
	var click := create_tween()
	click.tween_interval(0.12)
	click.tween_callback(_go_dark)


## The lamp off, all at once and with no fade: the spot, the glows, the lamp-lit labels and the
## counter's own glow all cut together, so the room is black in a single frame. A reverb is opened
## over the sound effects so the pull of the chain rings out and decays into nothing as the room
## goes dark, see [method Audio.drown_sfx]. The film rests there; [signal settled] is then said for
## [LastLines] to cover the black and bring the line on.
func _go_dark() -> void:
	_spot.light_energy = 0.0
	_bulb_mat.emission_energy_multiplier = 0.0
	_shade_mat.emission_energy_multiplier = 0.0
	_rim.light_energy = 0.0
	for label: Label3D in _lit_labels:
		label.modulate.a = 0.0
	_cap.modulate.a = 0.0
	for zero: Label3D in _zeros:
		zero.modulate.a = 0.0
	_one.modulate.a = 0.0
	for light: OmniLight3D in _tube_lights:
		light.light_energy = 0.0
	Audio.drown_sfx()
	settled.emit()
