class_name JackpotZone
extends Area3D
## The growing bank, GAME.md 3.5. The active zone accrues chips up to a cap; a single kart inside
## collects the pile into its pot at a ramping rate, two or more karts pause it, and an emptied
## zone hands over to the other one. A traffic light and a counter show its state.

signal filled(zone: JackpotZone)
signal emptied(zone: JackpotZone)
signal collected(kart: Kart, chips: int)

var rules: MatchRules
var index := 0
var size := Vector2(2.5, 2.5)
var active := false
var chips := 0.0
## 2.0 during Last Call.
var accrual_multiplier := 1.0
## On a client the zone only shows replicated state.
var puppet := false

var _inside: Array[Kart] = []
var _t := 0.0
var _carry := 0.0
var _was_full := false
var _label: Label3D
var _lights: Array[MeshInstance3D] = []
var _light_materials: Array[StandardMaterial3D] = []
var _flash := 0.0


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 2.0, size.y)
	shape.shape = box
	shape.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_signals()
	_refresh()


func activate() -> void:
	active = true
	chips = 0.0
	_carry = 0.0
	_t = 0.0
	_was_full = false
	_refresh()


func deactivate() -> void:
	active = false
	chips = 0.0
	_carry = 0.0
	_t = 0.0
	_refresh()


func whole_chips() -> int:
	return floori(chips + 0.0001)


## Replicated state from the host.
func apply_puppet_state(is_active: bool, chip_count: float) -> void:
	active = is_active
	chips = chip_count
	_refresh()


func is_full() -> bool:
	return rules != null and whole_chips() >= rules.jackpot_cap


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	if kart != null and kart not in _inside:
		_inside.append(kart)


func _on_body_exited(body: Node3D) -> void:
	var kart := body as Kart
	if kart != null:
		_inside.erase(kart)


## Alive karts inside other than [param except].
func occupant_count(except: Kart = null) -> int:
	var count := 0
	for kart: Kart in _collectors():
		if kart != except:
			count += 1
	return count


func _collectors() -> Array[Kart]:
	var result: Array[Kart] = []
	for kart: Kart in _inside:
		if is_instance_valid(kart) and kart.is_active():
			result.append(kart)
	return result


func _physics_process(delta: float) -> void:
	if rules == null or puppet:
		return
	if active and chips < rules.jackpot_cap:
		chips = minf(
			chips + rules.jackpot_accrual * accrual_multiplier * delta, float(rules.jackpot_cap)
		)
		if is_full() and not _was_full:
			_was_full = true
			filled.emit(self)
	var collectors := _collectors()
	if collectors.is_empty():
		_t = 0.0
	elif collectors.size() == 1 and chips > 0.0:
		_collect(collectors[0], delta)
	_refresh()


func _collect(kart: Kart, delta: float) -> void:
	var amount := Scoring.banked_between(
		_t, _t + delta, rules.jackpot_rate_base, rules.jackpot_rate_doubling
	)
	_t += delta
	amount = minf(amount, chips)
	chips -= amount
	_carry += amount
	var whole := floori(_carry)
	if whole > 0:
		_carry -= whole
		kart.collect_coins(whole, null)
		collected.emit(kart, whole)
	if chips <= 0.0001:
		var leftover := roundi(_carry)
		if leftover > 0:
			kart.collect_coins(leftover, null)
			collected.emit(kart, leftover)
		chips = 0.0
		_carry = 0.0
		_t = 0.0
		if active:
			active = false
			emptied.emit(self)


func _process(delta: float) -> void:
	_flash += delta
	if rules != null and is_full():
		_set_light(2, fmod(_flash, 0.6) < 0.3)


func _refresh() -> void:
	if _label != null:
		_label.text = str(whole_chips()) if active else ""
		_label.visible = active
	if rules == null or _lights.is_empty():
		return
	var count := whole_chips()
	_set_light(0, active and count < rules.jackpot_amber)
	_set_light(1, active and count >= rules.jackpot_amber and count < rules.jackpot_cap)
	_set_light(2, active and count >= rules.jackpot_cap)


func _set_light(which: int, on: bool) -> void:
	var material := _light_materials[which]
	material.emission_enabled = on
	material.albedo_color = material.emission if on else material.emission.darkened(0.7)


func _build_signals() -> void:
	_label = Label3D.new()
	_label.name = "Counter"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 96
	_label.pixel_size = 0.01
	_label.outline_size = 12
	_label.modulate = Palette.CHIP_GOLD
	_label.position = Vector3(0.0, 1.6, 0.0)
	add_child(_label)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.05
	pole_mesh.bottom_radius = 0.05
	pole_mesh.height = 1.4
	pole.mesh = pole_mesh
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.2, 0.2, 0.22)
	pole.material_override = pole_material
	pole.position = Vector3(-size.x * 0.5 - 0.2, 0.7, -size.y * 0.5 - 0.2)
	add_child(pole)
	var colors: Array[Color] = [
		Color(0.95, 0.2, 0.2), Color(0.95, 0.65, 0.15), Color(0.2, 0.9, 0.35)
	]
	for i: int in 3:
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.13
		sphere.height = 0.26
		lamp.mesh = sphere
		var material := StandardMaterial3D.new()
		material.emission = colors[i]
		material.emission_energy_multiplier = 1.5
		material.albedo_color = colors[i].darkened(0.7)
		lamp.material_override = material
		lamp.position = pole.position + Vector3(0.0, 0.85 - 0.3 * i, 0.0)
		add_child(lamp)
		_lights.append(lamp)
		_light_materials.append(material)
