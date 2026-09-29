class_name ArenaEnvironment
extends Node3D
## The light and the air in a room, GAME.md 8.1. Every arena scene puts one of these in and the
## match hands it the [RoomLook] its map names, so what a room is lit by is data rather than a
## number typed into four scenes.
##
## Two lights: a key that casts the shadows and a fill from the other side so a shadow is a dark
## side rather than a hole. Everything else is the camera: how the picture is tonemapped, how far
## out it goes soft, how much the neon blooms.

## How far the shadows are drawn out from the camera over a floor of [constant FLOOR_WIDTH]. The
## table is small and the room around it is not: past this there is nothing worth a shadow map,
## and the nearer it is drawn the more of the map lands on the table. A wider floor, an XL map's,
## is seen from further back, and draws them as much further out.
const SHADOW_REACH := 80.0
const FLOOR_WIDTH := 40.0
## How far inside the edge of the lamp's cone the corners of the floor are kept, in degrees, and
## the floor a room's lamp was set for, whose corners a bigger floor's are kept as far into the
## cone as.
const LAMP_SPARE := 4.0
const USUAL_FLOOR := Vector2(40.0, 22.5)
## The light a room needs from its sun before that sun is worth a shadow map of its own.
const SUN_SHADOWS := 0.8

## The floor lit, in meters, which a lamp over a bigger one than its room was set for widens to
## take in, see [method dress].
var floor_size := Vector2(40.0, 22.5)
## The room this is lit for, kept so a setting can ask for the same room again.
var lit_by: RoomLook
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
static func dress_all(tree: SceneTree, room: RoomLook, area := Vector2.ZERO) -> void:
	for lighting: ArenaEnvironment in tree.get_nodes_in_group(&"arena_environment"):
		if area != Vector2.ZERO:
			lighting.floor_size = area
		lighting.dress(room)


## Lights every room again the way it already was, for a setting that changes what a room costs
## rather than what it is, GAME.md 8.5.
static func relight(tree: SceneTree) -> void:
	for lighting: ArenaEnvironment in tree.get_nodes_in_group(&"arena_environment"):
		lighting.dress(lighting.lit_by)


func _ready() -> void:
	add_to_group(&"arena_environment")


## Lights the room the way [param room] says. Called again when the map changes, so everything
## here is set rather than added to.
func dress(room: RoomLook) -> void:
	if room == null:
		return
	lit_by = room
	_build()
	key.light_color = room.key_color
	key.light_energy = room.key_energy
	key.rotation_degrees = room.key_angle
	# A sun that is only a hint casts no shadows: the lamp over the table is doing that work, and
	# two shadow maps over one room is the second one paid for and not seen.
	# And none at all for a player who has turned them off, GAME.md 8.5.
	var shadowed := Game.settings == null or Game.settings.shadows != Settings.SHADOWS_OFF
	key.shadow_enabled = room.key_energy >= SUN_SHADOWS and shadowed
	key.directional_shadow_max_distance = SHADOW_REACH * maxf(1.0, floor_size.x / FLOOR_WIDTH)
	key.shadow_opacity = room.shadow_depth
	key.shadow_blur = room.shadow_softness
	fill.light_color = room.fill_color
	fill.light_energy = room.fill_energy
	fill.rotation_degrees = room.fill_angle
	lamp.visible = room.lamp_energy > 0.0
	lamp.light_color = room.lamp_color
	lamp.light_energy = room.lamp_energy
	lamp.position = Vector3(0.0, room.lamp_height, 0.0)
	lamp.spot_range = room.lamp_reach
	# Never narrower than the room asks for, and wide enough to reach the corners of whatever
	# floor it is over, as far inside the cone as the usual floor's are: an XL map's corners were
	# out in the fringe past the brightest of it, where a dark room's pits could not be seen.
	var height := maxf(room.lamp_height, 1.0)
	var corner := rad_to_deg(atan((floor_size * 0.5).length() / height))
	var usual := rad_to_deg(atan((USUAL_FLOOR * 0.5).length() / height))
	var wide := maxf(room.lamp_angle * corner / usual, corner + LAMP_SPARE)
	lamp.spot_angle = minf(maxf(room.lamp_angle, wide), 89.0)
	lamp.spot_angle_attenuation = room.lamp_fade
	lamp.shadow_enabled = room.lamp_shadow and shadowed
	lamp.shadow_opacity = room.shadow_depth
	lamp.shadow_blur = room.shadow_softness
	var air := world.environment
	air.background_color = room.background
	air.ambient_light_color = room.ambient_color
	air.ambient_light_energy = room.ambient_energy
	# A room that asks for none of something does not pay for it: the passes come on with the
	# numbers rather than standing enabled at zero.
	air.ssao_enabled = room.occlusion > 0.0
	air.ssao_intensity = room.occlusion
	# The bloom is a pass over the whole screen and about a tenth of the frame in the room that
	# wants it most, so it is one of the two things 8.5 lets a player hand back.
	air.glow_enabled = room.glow > 0.0 and (Game.settings == null or Game.settings.bloom)
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
	key.directional_shadow_max_distance = SHADOW_REACH
	add_child(key)
	fill = DirectionalLight3D.new()
	fill.name = "Fill"
	fill.shadow_enabled = false
	add_child(fill)
	lamp = SpotLight3D.new()
	lamp.name = "Lamp"
	# Straight down over the middle of the table, which is where every map is centered.
	lamp.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	lamp.shadow_blur = 1.5
	add_child(lamp)
	var air := Environment.new()
	air.background_mode = Environment.BG_COLOR
	air.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	air.ssao_radius = 1.2
	air.ssao_detail = 0.6
	air.glow_bloom = 0.15
	air.glow_hdr_threshold = 1.0
	air.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# Two blur steps rather than the five the defaults ask for: the neon wants a halo round it,
	# not a fog over the room, and every step is another pass over the screen.
	# The levels are numbered from one in the inspector and from zero here, so these two are the
	# second and third blur steps.
	for level: int in range(0, 7):
		air.set_glow_level(level, 1.0 if level in [1, 2] else 0.0)
	air.fog_sky_affect = 0.0
	air.tonemap_mode = Environment.TONE_MAPPER_ACES
	air.adjustment_enabled = true
	world = WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = air
	add_child(world)
