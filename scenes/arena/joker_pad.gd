class_name JokerPad
extends SpawningPad
## A pad that keeps a joker lying on it, GAME.md 6.2. Drive over it to take the card; another one
## turns up a few seconds later. Meant for the Garage, where nobody dies and so nobody is ever
## offered a joker the usual way, but it is an ordinary arena element any map may use.

const RESPAWN := 6.0

var catalog: JokerCatalog


## Starts handing out cards. Without a catalog the pad just sits there.
func start(
	match_rules: MatchRules, random: RandomNumberGenerator, parent: Node, jokers: JokerCatalog
) -> void:
	rules = match_rules
	rng = random
	pickup_parent = parent
	catalog = jokers
	_spawn()


func _ready() -> void:
	_build_visuals()


func _spawn() -> void:
	if catalog == null or catalog.jokers.is_empty():
		return
	var offered := catalog.offer(rng, 1, [])
	if offered.is_empty():
		return
	var card := FloorJoker.new()
	card.joker = offered[0]
	_place(card)


## The pad hands out cards rather than pickups from the rules, so it needs a catalog rather than
## the rules to have anything to put out.
func _can_spawn() -> bool:
	return catalog != null


func _respawn_delay() -> float:
	return RESPAWN


func _build_visuals() -> void:
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.1, 0.05, 1.1)
	plate.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.ASPHALT
	plate.material_override = material
	plate.position = Vector3(0.0, 0.025, 0.0)
	add_child(plate)
	var pip := MeshInstance3D.new()
	var pip_mesh := BoxMesh.new()
	pip_mesh.size = Vector3(0.5, 0.05, 0.7)
	pip.mesh = pip_mesh
	var card_material := StandardMaterial3D.new()
	card_material.albedo_color = Palette.CHIP_WHITE
	card_material.emission_enabled = true
	card_material.emission = Palette.NEON_MAGENTA
	card_material.emission_energy_multiplier = 0.35
	pip.material_override = card_material
	pip.position = Vector3(0.0, 0.06, 0.0)
	pip.rotation_degrees = Vector3(0.0, 18.0, 0.0)
	add_child(pip)
