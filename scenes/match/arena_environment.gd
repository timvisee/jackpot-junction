class_name ArenaEnvironment
extends Node3D
## The light and the air in a room, GAME.md 8.1. Every arena scene puts one of these in and the
## match hands it the [RoomLook] its map names, so what a room is lit by is data rather than a
## number typed into four scenes.
##
## Two lights: a key that casts the shadows and a fill from the other side so a shadow is a dark
## side rather than a hole. Everything else is the camera: how the picture is tonemapped, how far
## out it goes soft, how much the neon blooms.

## How far the shadows are drawn out from the camera. The table is small and the room around it
## is not: past this there is nothing worth a shadow map.
const SHADOW_REACH := 120.0

var key: DirectionalLight3D
var fill: DirectionalLight3D
## The lamp over the table, off in a room that has none.
var lamp: SpotLight3D
var world: WorldEnvironment


## Puts a room's lighting in [param parent] and returns it, undressed. The match dresses it once
## it knows which map is being played; until then it is the default room, so a scene that never
## says is still lit.
static func add_to(parent: Node) -> ArenaEnvironment:
	var lighting := ArenaEnvironment.new()
	lighting.name = "ArenaEnvironment"
	parent.add_child(lighting)
	lighting.dress(RoomLook.fallback())
	return lighting


## Lights every room in [param tree] the way [param room] says. The scene puts the lighting in
## before it knows which map is coming; the match says so once it does.
static func dress_all(tree: SceneTree, room: RoomLook) -> void:
	for lighting: ArenaEnvironment in tree.get_nodes_in_group(&"arena_environment"):
		lighting.dress(room)


func _ready() -> void:
	add_to_group(&"arena_environment")


## Lights the room the way [param room] says. Called again when the map changes, so everything
## here is set rather than added to.
func dress(room: RoomLook) -> void:
	if room == null:
		return
	_build()
	key.light_color = room.key_color
	key.light_energy = room.key_energy
	key.rotation_degrees = room.key_angle
	fill.light_color = room.fill_color
	fill.light_energy = room.fill_energy
	fill.rotation_degrees = room.fill_angle
	lamp.visible = room.lamp_energy > 0.0
	lamp.light_color = room.lamp_color
	lamp.light_energy = room.lamp_energy
	lamp.position = Vector3(0.0, room.lamp_height, 0.0)
	lamp.spot_range = room.lamp_reach
	lamp.spot_angle = room.lamp_angle
	lamp.spot_angle_attenuation = room.lamp_fade
	lamp.shadow_enabled = room.lamp_shadow
	var air := world.environment
	air.background_color = room.background
	air.ambient_light_color = room.ambient_color
	air.ambient_light_energy = room.ambient_energy
	air.ssao_intensity = room.occlusion
	air.glow_intensity = room.glow
	air.fog_enabled = room.fog_density > 0.0
	air.fog_light_color = room.fog_color
	air.fog_density = room.fog_density
	air.tonemap_white = room.white
	air.tonemap_exposure = room.exposure
	air.adjustment_saturation = room.saturation
	air.adjustment_contrast = room.contrast


## The nodes themselves, once. What a room says goes into them afterwards.
func _build() -> void:
	if world != null:
		return
	key = DirectionalLight3D.new()
	key.name = "Key"
	key.shadow_enabled = true
	key.shadow_blur = 1.2
	key.directional_shadow_max_distance = SHADOW_REACH
	add_child(key)
	fill = DirectionalLight3D.new()
	fill.name = "Fill"
	fill.shadow_enabled = false
	add_child(fill)
	lamp = SpotLight3D.new()
	lamp.name = "Lamp"
	# Straight down over the middle of the table, which is where every map is centred.
	lamp.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	lamp.shadow_blur = 1.5
	add_child(lamp)
	var air := Environment.new()
	air.background_mode = Environment.BG_COLOR
	air.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	air.ssao_enabled = true
	air.ssao_radius = 1.2
	air.ssao_detail = 0.6
	air.glow_enabled = true
	air.glow_bloom = 0.15
	air.glow_hdr_threshold = 0.9
	air.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	air.fog_sky_affect = 0.0
	air.tonemap_mode = Environment.TONE_MAPPER_ACES
	air.adjustment_enabled = true
	world = WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = air
	add_child(world)
