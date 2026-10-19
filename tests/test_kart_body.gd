extends GdUnitTestSuite
## A kart's body, GAME.md 4.4 and 8.1b: the racer everybody drives and three more the loyalty
## program pays, picked in the kart dialog, kept with the rest of the dress, the same on every
## screen, and sprung apart whichever it is; the same kart to play in every one of them.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const PATH := "user://test_kart_body.cfg"
## Where each body is won, by the landmark that pays it.
const WON_AT := {"Woodie": &"dashed_marks", "Streamliner": &"showroom", "Microcar": &"horns"}

var _settings_were: Settings
var _holder: Control
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	PlayerInput.typing = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## A match of a kart for each of [param styles], started.
func _start(styles: Array) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for each: Variant in styles:
		inputs.append(KartInput.new())
	match_node.start(inputs, 7, [], [], styles)
	return match_node


## The model [param kart], a kart or a display model of one, is built in, by its file's name.
static func _worn(kart: Node) -> String:
	var model := kart.find_child("Model", true, false)
	return model.scene_file_path.get_file().get_basename() if model != null else ""


## A style built in body [param body] and dressed in nothing.
static func _in(body: int) -> PackedInt32Array:
	return PackedInt32Array([0, 0, 0, 0, 0, 0, body])


func test_the_bodies_are_the_racer_and_three_more() -> void:
	assert_array(KartStyle.BODIES).is_equal(["Racer", "Woodie", "Streamliner", "Microcar"])
	for index: int in KartStyle.BODIES.size():
		var shape := KartVisuals.body_at(index)
		assert_bool(shape in KartVisuals.BODIES).is_true()
		assert_str(String(shape)).is_equal(KartStyle.BODIES[index].to_lower())
	assert_str(String(KartVisuals.body_of(KartStyle.new()))).is_equal("racer")
	assert_str(String(KartVisuals.body_of(null))).is_equal("racer")
	assert_str(String(KartVisuals.body_at(9))).is_equal("racer")
	# The tin is built still, its key on its tail, and offered to nobody.
	assert_bool(&"tin" in KartVisuals.BODIES).is_true()
	assert_bool("Tin" in KartStyle.BODIES).is_false()
	var tin: Node3D = auto_free(KartVisuals.model_of(&"tin"))
	assert_object(KartVisuals.key_of(tin)).is_not_null()
	var racer: Node3D = auto_free(KartVisuals.model_of(KartVisuals.BODY))
	assert_object(KartVisuals.key_of(racer)).is_null()
	assert_str(KartVisuals.print_of(&"woodie").resource_path).contains("print_woodie")
	# A bot drives the racer, everybody's.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i: int in 40:
		assert_int(KartStyle.random(rng).body).is_equal(0)


## The body is kept with the rest of the style, and a style kept before the bodies, or with one this
## build has never heard of, is the racer.
func test_a_body_is_kept_and_an_old_style_is_the_racer() -> void:
	assert_int(KartStyle.from_array(PackedInt32Array([1, 2, 1, 2, 1, 2])).body).is_equal(0)
	assert_int(KartStyle.from_array(PackedInt32Array([1, 2, 1, 2])).body).is_equal(0)
	assert_int(KartStyle.from_array(_in(9)).body).is_equal(0)
	var style := KartStyle.from_array(_in(2))
	assert_int(style.body).is_equal(2)
	assert_int(style.duplicate_style().body).is_equal(2)
	assert_int(style.to_array()[KartStyle.BODY]).is_equal(2)
	Game.settings.set_seat_style(0, PackedInt32Array([1, 3, 0, 0, 0, 0, 3]))
	Game.settings.set_seat_style(1, PackedInt32Array([1, 3, 0, 0, 0, 0]))
	Game.settings.save_to_disk()
	var read := Settings.new()
	read.path = PATH
	read.load_from_disk()
	assert_int(KartStyle.from_array(read.seat_style(0)).body).is_equal(3)
	assert_int(KartStyle.from_array(read.seat_style(0)).hat).is_equal(3)
	assert_int(KartStyle.from_array(read.seat_style(1)).body).is_equal(0)


## Every body is the same kart to play: the same collider, the same wheels where they were, its
## tire marks laid under the same rear wheels; only the tin had a key.
func test_every_body_is_the_same_kart_to_play() -> void:
	var styles: Array = []
	for index: int in KartStyle.BODIES.size():
		styles.append(_in(index))
	var match_node := _start(styles)
	await _runner.simulate_frames(6, 17)
	var first := match_node.kart_of(0)
	var collider := first.get_node("CollisionShape3D") as CollisionShape3D
	for index: int in KartStyle.BODIES.size():
		var kart := match_node.kart_of(index)
		assert_str(_worn(kart)).is_equal(KartStyle.BODIES[index].to_lower())
		var shape := kart.get_node("CollisionShape3D") as CollisionShape3D
		assert_object(shape.shape).is_same(collider.shape)
		assert_vector(shape.position).is_equal(collider.position)
		assert_int(kart._wheels.size()).is_equal(4)
		assert_object(kart._key).is_null()
		assert_float(kart.rear_axle).is_equal_approx(first.rear_axle, 0.03)
		assert_float(kart.rear_half_track).is_equal_approx(first.rear_half_track, 0.05)
		assert_float(kart.stats.top_speed).is_equal(first.stats.top_speed)


## A kart dressed in another body in a room is built over in it at once, its paint, its print and
## its hat with it, and the same on a client's screen.
func test_a_body_rides_the_wire_and_is_built_over() -> void:
	var host := _start([PackedInt32Array([0, 3, 0, 0, 0, 0, 1]), _in(3)])
	await _runner.simulate_frames(6, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	await _runner.simulate_frames(2, 17)
	var puppet: Kart = client.slots[0].kart
	assert_int(puppet.style.body).is_equal(1)
	assert_str(_worn(puppet)).is_equal("woodie")
	assert_str(_worn(client.slots[1].kart)).is_equal("microcar")
	# Put in the streamliner on the host, as the kart dialog does in the lobby.
	var kart := host.kart_of(0)
	StyleStalls.dress(host.slots[0], PackedInt32Array([0, 3, 0, 0, 0, 0, 2]))
	client.apply_snapshot(host.build_snapshot())
	await _runner.simulate_frames(2, 17)
	for each: Kart in [kart, puppet]:
		var body := each.get_node("Body")
		# The model it wore gone with the frame, and the new one in its place.
		assert_int(body.find_children("Model*", "", false, false).size()).is_equal(1)
		assert_str(_worn(body)).is_equal("streamliner")
		assert_int(each._wheels.size()).is_equal(4)
		for wheel: MeshInstance3D in each._wheels:
			assert_bool(body.get_node("Model").is_ancestor_of(wheel)).is_true()
		assert_object(each._tint.detail_albedo).is_same(KartVisuals.print_of(&"streamliner"))
		assert_object(body.get_node_or_null("Hat")).is_not_null()
	# A client says a style with its finishes after it, a choice and a finish for each part.
	var said := Loyalty.with_finishes(Game.settings.profile, _in(2))
	assert_int(said.size()).is_less_equal(KartStyle.CHOICES.size() * 2)


## The racer is everybody's; the woodie, the streamliner and the microcar are won in the loyalty
## program, each at a landmark of the Department of Karts.
func test_the_bodies_are_won_in_the_loyalty_program() -> void:
	var none := PackedStringArray()
	assert_bool(KartStyle.allowed(KartStyle.BODY, 0, none)).is_true()
	var owner := KartOwner.for_seat(0)
	for index: int in range(1, KartStyle.BODIES.size()):
		var named: String = KartStyle.BODIES[index]
		assert_bool(KartStyle.allowed(KartStyle.BODY, index, none)).is_false()
		assert_bool(owner.owns(KartStyle.BODY, index)).is_false()
		var landmark := Loyalty.map().landmark(WON_AT[named])
		assert_object(landmark).is_not_null()
		assert_array(landmark.also).contains(["body:%s" % named])
		assert_str(KartOwner.won_at(KartStyle.BODY, index)).is_equal(landmark.title)
		assert_int(landmark.district).is_equal(LoyaltyLandmark.District.DEPARTMENT)
		Game.settings.profile.loyalty.win(landmark.id)
		assert_bool(owner.owns(KartStyle.BODY, index)).is_true()
		assert_array(Array(Loyalty.unlocks_of(Game.settings.profile)["dress"])).contains(
			["body:%s" % named]
		)
	# No finish shows on a body: an edition is spent on the dress.
	for piece: String in LoyaltyEditions.pieces_of(Game.settings.profile):
		assert_bool(piece.begins_with("body:")).is_false()


## The kart dialog's body hook, top right, says the body worn and opens its rack: the racer first,
## then those still to win, each saying where; one won is worn and kept, the kart on the lift
## built over in it, and one not won is neither.
func test_the_dialog_picks_a_body() -> void:
	Game.settings.set_seat_style(0, PackedInt32Array([0, 3, 0, 0, 0, 0]))
	var dialog := KartDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	var hook := dialog.hooks[KartStyle.BODY]
	assert_str(hook.worn).is_equal("Racer")
	assert_str(hook.accessibility_name).is_equal("Body")
	assert_int(hook.mouse_default_cursor_shape).is_equal(dialog.hooks[1].mouse_default_cursor_shape)
	assert_bool(BoardArt.on_left(KartStyle.BODY)).is_false()
	assert_int(BoardArt.HOOKS[KartStyle.BODY].y).is_equal(0)
	assert_str(_worn(dialog.stage._kart)).is_equal("racer")
	# The cursor's ways: across from the flag, under Back, over the hat.
	assert_object(dialog.hooks[2].get_node(dialog.hooks[2].focus_neighbor_right)).is_same(hook)
	assert_object(hook.get_node(hook.focus_neighbor_top)).is_same(dialog.back)
	assert_object(hook.get_node(hook.focus_neighbor_bottom)).is_same(dialog.hooks[1])
	dialog.open_tray(KartStyle.BODY)
	assert_int(dialog.tray.cells.size()).is_equal(KartStyle.BODIES.size())
	assert_int(dialog.tray.cells[0].index).is_equal(0)
	assert_bool(dialog.tray.cells[0].owned).is_true()
	for index: int in range(1, KartStyle.BODIES.size()):
		var cell := dialog.tray.cell_at(index)
		assert_bool(cell.owned).is_false()
		assert_str(cell.where).is_equal(KartOwner.won_at(KartStyle.BODY, index))
	dialog.close_tray()
	var woodie := KartStyle.BODIES.find("Woodie")
	assert_bool(dialog.wear(KartStyle.BODY, woodie)).is_false()
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).body).is_equal(0)
	Game.settings.profile.loyalty.win(WON_AT["Woodie"])
	dialog.close_tray()
	assert_bool(dialog.wear(KartStyle.BODY, woodie)).is_true()
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).body).is_equal(woodie)
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).hat).is_equal(3)
	assert_str(hook.worn).is_equal("Woodie")
	# Its rack put away, the cursor that landed on the racer as it came out no longer trying it on.
	await get_tree().process_frame
	dialog.close_tray()
	assert_str(_worn(dialog.stage._kart)).is_equal("woodie")
	# Tried on from its rack: one not won leaves the kart as it is, one won is shown.
	var streamliner := KartStyle.BODIES.find("Streamliner")
	dialog.open_tray(KartStyle.BODY)
	await get_tree().process_frame
	dialog._try(streamliner)
	assert_int(dialog.stage.shown.body).is_equal(woodie)
	Game.settings.profile.loyalty.win(WON_AT["Streamliner"])
	dialog._try(streamliner)
	assert_int(dialog.stage.shown.body).is_equal(streamliner)
	await get_tree().process_frame
	assert_str(_worn(dialog.stage._kart)).is_equal("streamliner")
	dialog._untry(streamliner)
	assert_int(dialog.stage.shown.body).is_equal(woodie)
	# Looked at, the kart turns to show its body and the hook ropes to it.
	dialog.close_tray()
	dialog.open_tray(KartStyle.BODY)
	await get_tree().process_frame
	assert_int(dialog.stage.part_shown).is_equal(KartStyle.BODY)
	assert_array(dialog.roped_parts()).contains([KartStyle.BODY])


## A wreck springs every body apart, a piece for each of its meshes: its shell and its long trim
## hopping, four wheels rolling off, the driver and the cap popping out; the key only off the tin.
func test_every_body_springs_apart() -> void:
	for shape: StringName in KartVisuals.BODIES:
		var body: Node3D = auto_free(Node3D.new())
		body.name = "Body"
		var model := KartVisuals.painted(shape, Color.RED, KartStyle.new())
		body.add_child(model)
		add_child(body)
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		var wreck := KartWreck.spawn(self, body)
		assert_object(wreck).is_not_null()
		assert_int(wreck._pieces.size()).is_equal(meshes.size())
		var names: Array[String] = []
		var keys := 0
		for piece: Dictionary in wreck._pieces:
			names.append(String((piece["node"] as Node).name))
			keys += 1 if piece["key"] else 0
		var wheels := names.filter(func(called: String) -> bool: return called.begins_with("wheel"))
		assert_int(wheels.size()).is_equal(4)
		assert_array(names).contains(["body", "character", "cap"])
		assert_int(keys).is_equal(1 if shape == &"tin" else 0)
		# A frame or a base the length of the kart is heavy; its lamps are not.
		for piece: Dictionary in wreck._pieces:
			var node: Node3D = piece["node"]
			var called := String(node.name)
			if called in ["trim-wood", "trim-plastic"]:
				assert_bool(KartWreck._long(node)).override_failure_message(called).is_true()
			if called == "trim-lamps":
				assert_bool(KartWreck._long(node)).is_false()
		remove_child(body)
		wreck.free()
	# And a kart in a match springs apart in its own body.
	var match_node := _start([_in(3), _in(0)])
	await _runner.simulate_frames(6, 17)
	var kart := match_node.kart_of(0)
	kart.die(&"shot", 1)
	var wrecks := match_node.find_children("KartWreck*", "", false, false)
	assert_int(wrecks.size()).is_equal(1)
	var pieces: Array[String] = []
	for piece: Dictionary in (wrecks[0] as KartWreck)._pieces:
		pieces.append(String((piece["node"] as Node).name))
	assert_array(pieces).contains(["trim-plastic"])
