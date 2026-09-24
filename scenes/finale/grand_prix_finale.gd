class_name GrandPrixFinale
extends Node3D
## The end of a Grand Prix, GAME.md 9.7: the room the last map was played in turned into a party
## for whoever won the run.
##
## A podium goes up on the Junction with the top three of the run standing on it in their own
## colors, the rest of the karts and everything on the floor are cleared away, the room goes to
## the top of the meter -- the crowd on its feet, the lights on the winner, the music at its
## loudest -- and fireworks and confetti go up in the colors of the three on the steps. The camera
## leaves the rig and comes down in front of the podium, with the DJ booth and the crowd behind
## it, holds there for a moment, and only then does the run's standings come up over it.
##
## Everybody's own: each machine stages it when its player asks for the run's results, from what
## it already knows, so nothing about it goes over the wire.

const SCENE := preload("res://scenes/finale/grand_prix_finale.tscn")
## Where each place stands and how tall its step is, in meters: the winner in the middle, second
## to the left a little lower, third to the right and lowest of all.
const PLACES: Array[Vector2] = [Vector2(0.0, 1.5), Vector2(-2.8, 1.05), Vector2(2.8, 0.7)]
const STEP_SIZE := Vector2(2.4, 2.4)
const STEP_COLOR := Color(0.12, 0.12, 0.16)
## The band of the player's own color round the top of their step, and how far it stands proud.
const BAND_HEIGHT := 0.12
const BAND_LIFT := 0.03
const KART_SCALE := 1.4
## Seconds for a kart on the podium to turn all the way round, and how high the winner bounces.
const SPIN_SECONDS := 6.0
const BOUNCE := 0.18
const BOUNCE_RATE := 5.0
## The camera's move: from wherever the rig was looking down to in front of the podium over
## [constant PAN_SECONDS], then held for [constant HOLD_SECONDS] before the standings come up.
const PAN_SECONDS := 2.6
const HOLD_SECONDS := 1.0
const SHOT_FROM := Vector3(0.0, 3.4, 14.5)
const SHOT_AT := Vector3(0.0, 2.6, 0.0)
const SHOT_FOV := 40.0
## Confetti off the steps, a burst every so often in one of the three colors, and how long the
## fireworks keep going, which is longer than anybody reads the standings for.
const CONFETTI_EVERY := 0.3
const FIREWORK_SECONDS := 90.0
## The winner's name over the podium.
const NAME_HEIGHT := 4.4
const NAME_SIZE := 140

var match_node: Match

var _camera: Camera3D
var _from: Transform3D
var _from_fov := 40.0
var _to: Transform3D
var _karts: Array[Node3D] = []
var _colors: Array[Color] = []
var _age := 0.0
var _confetti_left := 0.0
var _shown := false
var _done: Callable


## Stages the finale in [param in_match]'s arena for [param standings], best first, and calls
## [param done] once the camera has arrived and held, which is when the standings go up.
static func stage(in_match: Match, standings: Array[PlayerSlot], done: Callable) -> GrandPrixFinale:
	var finale: GrandPrixFinale = SCENE.instantiate()
	finale.name = "GrandPrixFinale"
	finale.match_node = in_match
	finale._done = done
	in_match.finale = finale
	in_match.arena.add_child(finale)
	finale.global_position = in_match.arena.junction_position
	finale._build(standings)
	finale._clear_the_floor()
	finale._raise_the_room()
	finale._take_the_shot()
	return finale


## Whether the camera has arrived and the standings are up.
func is_shown() -> bool:
	return _shown


## Skips the camera's move for a player who has seen it, straight to the standings.
func skip() -> void:
	_age = maxf(_age, PAN_SECONDS + HOLD_SECONDS)


func _unhandled_input(event: InputEvent) -> void:
	if not _shown and event.is_action_pressed(&"ui_accept"):
		skip()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_age += delta
	for i: int in _karts.size():
		var kart := _karts[i]
		kart.rotate_y(TAU * delta / SPIN_SECONDS * (1.0 if i != 1 else -1.0))
		if i == 0:
			kart.position.y = PLACES[0].y + BAND_LIFT + absf(sin(_age * BOUNCE_RATE)) * BOUNCE
	_confetti_left -= delta
	if _confetti_left <= 0.0 and not _karts.is_empty():
		_confetti_left = CONFETTI_EVERY
		var place := randi() % _karts.size()
		var over := _karts[place].global_position + Vector3(0.0, 1.2, 0.0)
		Burst.spawn(self, over, _colors[place], 1.1, 18)
	var t := smoothstep(0.0, 1.0, clampf(_age / PAN_SECONDS, 0.0, 1.0))
	if _camera != null:
		_camera.global_transform = _from.interpolate_with(_to, t)
		_camera.fov = lerpf(_from_fov, SHOT_FOV, t)
	if not _shown and _age >= PAN_SECONDS + HOLD_SECONDS:
		_shown = true
		if _done.is_valid():
			_done.call()


## The podium, the three on it, the winner's name over them and a light on the lot.
func _build(standings: Array[PlayerSlot]) -> void:
	var shown := mini(standings.size(), PLACES.size())
	for place: int in shown:
		_add_step(standings[place], place)
	if shown > 0:
		var winner := standings[0]
		var name_label := Label3D.new()
		name_label.name = "Champion"
		name_label.text = winner.display_name()
		name_label.font_size = NAME_SIZE
		name_label.pixel_size = 0.01
		name_label.modulate = winner.color()
		name_label.outline_size = 24
		name_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.position = Vector3(0.0, NAME_HEIGHT, 0.0)
		add_child(name_label)
		var title := Label3D.new()
		title.name = "Title"
		title.text = "GRAND PRIX CHAMPION"
		title.font_size = 64
		title.pixel_size = 0.01
		title.modulate = Palette.CHIP_GOLD
		title.outline_size = 16
		title.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.position = Vector3(0.0, NAME_HEIGHT + 1.0, 0.0)
		add_child(title)
	var spot := SpotLight3D.new()
	spot.name = "Spot"
	spot.light_color = Color(1.0, 0.94, 0.82)
	spot.light_energy = 6.0
	spot.spot_range = 16.0
	spot.spot_angle = 32.0
	spot.position = Vector3(0.0, 9.0, 4.0)
	add_child(spot)
	spot.look_at(global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


## One step with its kart on top, its place painted on the front and a band of its color round
## the top.
func _add_step(slot: PlayerSlot, place: int) -> void:
	var at := PLACES[place]
	var step := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(STEP_SIZE.x, at.y, STEP_SIZE.y)
	step.mesh = box
	step.material_override = _material(STEP_COLOR)
	step.position = Vector3(at.x, at.y * 0.5, 0.0)
	add_child(step)
	var band := MeshInstance3D.new()
	var band_box := BoxMesh.new()
	band_box.size = Vector3(STEP_SIZE.x + 0.08, BAND_HEIGHT, STEP_SIZE.y + 0.08)
	band.mesh = band_box
	band.material_override = _material(slot.color(), true)
	band.position = Vector3(at.x, at.y - BAND_HEIGHT * 0.5 + BAND_LIFT, 0.0)
	add_child(band)
	var number := Label3D.new()
	number.text = str(place + 1)
	number.font_size = 180
	number.pixel_size = 0.006
	number.modulate = Palette.CHIP_GOLD if place == 0 else Color(0.86, 0.86, 0.9)
	number.position = Vector3(at.x, at.y * 0.55, STEP_SIZE.y * 0.5 + 0.01)
	add_child(number)
	var kart := Node3D.new()
	kart.name = "Kart%d" % place
	kart.position = Vector3(at.x, at.y + BAND_LIFT, 0.0)
	kart.scale = Vector3.ONE * KART_SCALE
	kart.add_child(KartVisuals.display_model(slot.color_index, slot.style))
	add_child(kart)
	_karts.append(kart)
	_colors.append(slot.color())


## Nothing of the match left in the way: the karts that played it, whatever they left on the
## floor, and the HUD bar the screen the standings go up on.
func _clear_the_floor() -> void:
	for child: Node in match_node.get_children():
		var kart := child as Kart
		if kart != null:
			kart.visible = false
	match_node.arena.pickups.visible = false
	if match_node.bullets != null:
		match_node.bullets.visible = false
	if match_node.hud != null:
		match_node.hud.stand_aside()


## The room at the top of its meter for the party, GAME.md 8.4: the crowd on its feet, the
## lights on the winner, the music at its loudest and fireworks in all three colors.
func _raise_the_room() -> void:
	match_node.intensity.level = MatchIntensity.LEVELS
	match_node.intensity.value = 1.0
	var arena := match_node.arena
	arena.disco.level = MatchIntensity.LEVELS
	arena.crowd.level = MatchIntensity.LEVELS
	if not _karts.is_empty():
		arena.disco.focus(_karts[0])
	Audio.duck_music(false)
	Audio.play_sfx(&"fanfare", -4.0, 0.0)
	for i: int in _colors.size():
		Fireworks.celebrate(match_node, arena.bounds(), _colors[i], FIREWORK_SECONDS)


## The camera of its own that the move is made with, starting from exactly where the rig is.
func _take_the_shot() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	add_child(_camera)
	var rig := match_node.camera_rig
	if rig != null and rig.camera != null:
		_from = rig.camera.global_transform
		_from_fov = rig.camera.fov
	else:
		_from = Transform3D(Basis.IDENTITY, global_position + SHOT_FROM * 2.0)
	var eye := global_position + SHOT_FROM
	_to = Transform3D(Basis.IDENTITY, eye).looking_at(global_position + SHOT_AT, Vector3.UP)
	_camera.global_transform = _from
	_camera.fov = _from_fov
	_camera.make_current()


func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	return material
