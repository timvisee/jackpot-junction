class_name ArenaEnvironment
extends RefCounted
## The light and world environment every arena scene shares.


static func add_to(parent: Node) -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	light.shadow_enabled = true
	light.light_energy = 1.2
	parent.add_child(light)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#2A1E16")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.86, 0.8)
	environment.ambient_light_energy = 0.55
	environment.ssao_enabled = true
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = environment
	parent.add_child(world)
