extends GdUnitTestSuite
## The dress the loyalty program of GAME.md 8.9 pays: the choices everybody has and the ones won,
## a stall stepping a seat only through what its owner may wear, bots in what everybody has, every
## piece built, the plate's frame, the tire marks, the card backs and the respawn pick dealt face
## down, see [KartStyle], [KartDress] and [CardBack].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")
const JOKERS: JokerCatalog = preload("res://data/jokers/catalog.tres")
const PATH := "user://test_loyalty_dress.cfg"

var _runner: GdUnitSceneRunner
var _settings_were: Settings
var _session_was: NetSession


func before_test() -> void:
	_settings_were = Game.settings
	_session_was = Net.session
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()


func after_test() -> void:
	Net.session = _session_was
	Settings.remove_files(PATH)
	Game.settings = _settings_were


## Everybody has most of the choices the game always had, and the plain one of each new kind; the
## rest are worn once won, by the names the program's landmarks pay them under, four of the old
## ones among them.
func test_what_everybody_has_and_what_is_won() -> void:
	var none := PackedStringArray()
	for part: int in KartStyle.CHOICES.size():
		var choices: Array = KartStyle.CHOICES[part]
		for index: int in choices.size():
			var everybody: bool = index in KartStyle.EVERYBODY[part]
			assert_bool(KartStyle.allowed(part, index, none)).is_equal(everybody)
	for old: String in ["paint:Checks", "hat:Top hat", "flag:Checkered", "trail:Confetti"]:
		var part := KartStyle.PARTS.find(StringName(old.get_slice(":", 0)))
		var index: int = KartStyle.CHOICES[part].find(old.get_slice(":", 1))
		assert_bool(KartStyle.allowed(part, index, none)).override_failure_message(old).is_false()
		assert_bool(KartStyle.allowed(part, index, PackedStringArray([old]))).is_true()
	var won := PackedStringArray(["hat:Fedora", "marks:Dashed"])
	var fedora := KartStyle.HATS.find("Fedora")
	assert_bool(KartStyle.allowed(1, fedora, won)).is_true()
	assert_bool(KartStyle.allowed(5, KartStyle.MARKS.find("Dashed"), won)).is_true()
	assert_bool(KartStyle.allowed(5, KartStyle.MARKS.find("Chalk"), won)).is_false()
	# Every piece the map pays is a choice of its part, by its name.
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if each.dress_part == &"" or each.dress_part == &"card_back":
			continue
		var part := KartStyle.PARTS.find(each.dress_part)
		assert_int(part).override_failure_message(each.dress).is_greater_equal(0)
		var index: int = KartStyle.CHOICES[part].find(each.dress)
		assert_int(index).override_failure_message(each.dress).is_greater_equal(0)
		assert_bool(index in KartStyle.EVERYBODY[part]).is_false()
		assert_str(KartStyle.won_name(part, index)).is_equal(
			"%s:%s" % [each.dress_part, each.dress]
		)
	# And what a landmark pays besides, each a choice nobody has until it is won.
	var also := 0
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		for paid: String in each.also:
			var part := KartStyle.PARTS.find(StringName(paid.get_slice(":", 0)))
			var index: int = KartStyle.CHOICES[part].find(paid.get_slice(":", 1))
			assert_bool(index >= 0 and index not in KartStyle.EVERYBODY[part]).is_true()
			also += 1
	assert_int(also).is_equal(4)


## The next choice steps past what is not won, and round to the first again past the last.
func test_the_next_choice_skips_what_is_not_won() -> void:
	var none := PackedStringArray()
	assert_int(KartStyle.next(1, 4, none)).is_equal(5)
	# The top hat is won now, so a cap goes on to the crown.
	assert_int(KartStyle.next(1, 1, none)).is_equal(KartStyle.HATS.find("Crown"))
	assert_int(KartStyle.next(1, 5, none)).is_equal(0)
	var fedora := KartStyle.HATS.find("Fedora")
	var won := PackedStringArray(["hat:Fedora"])
	assert_int(KartStyle.next(1, 5, won)).is_equal(fedora)
	assert_int(KartStyle.next(1, fedora, won)).is_equal(0)
	# The frame has nothing to step to but itself until one is won.
	assert_int(KartStyle.next(4, 0, none)).is_equal(0)


## A bot wears only what everybody has, and never the crown.
func test_a_bot_wears_what_everybody_has() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in 300:
		var style := KartStyle.random(rng)
		var values := style.to_array()
		for part: int in KartStyle.CHOICES.size():
			assert_bool(KartStyle.allowed(part, values[part], PackedStringArray())).is_true()
		assert_int(style.hat).is_not_equal(KartStyle.HATS.find("Crown"))


## What a seat may wear is its owner's: a seat here its profile's, a guest's the profile playing's,
## a client's seat at a host what that client said, and a bot's nothing but what everybody has.
func test_whose_dress_a_seat_wears() -> void:
	Game.settings.profile.loyalty.win(&"fedora")
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1), BotInput.new()
	]
	match_node.start(inputs, 3)
	await _runner.simulate_frames(2, 17)
	assert_array(Array(Loyalty.dress_of(match_node.slots[0]))).contains(["hat:Fedora"])
	assert_array(Array(Loyalty.dress_of(match_node.slots[1]))).contains(["hat:Fedora"])
	assert_array(Array(Loyalty.dress_of(match_node.slots[2]))).is_empty()
	var session: NetSession = auto_free(NetSession.new())
	session.is_host = true
	Net.session = session
	var slot := match_node.slots[2]
	session._peer_slots.put(7, 0, slot.index)
	session.door.names[7] = "Bob"
	var hats := PackedStringArray(["hat:Horns"])
	session.host_controls.keep_unlocks(7, PackedStringArray(), PackedStringArray(), hats)
	assert_array(Array(Loyalty.dress_of(slot))).contains_exactly(["hat:Horns"])


## A stall steps a seat here through what its profile has won, and past what it has not.
func test_a_stall_steps_through_what_is_won() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(DeviceInput.KEYBOARD, 0)] as Array[KartInput], 3)
	await _runner.simulate_frames(2, 17)
	var stalls := StyleStalls.add_to(match_node, Vector2i(8, 1))
	var slot := match_node.slots[0]
	StyleStalls.dress(slot, PackedInt32Array([0, 5, 0, 0, 0, 0]))
	stalls._step(slot, 1)
	assert_int(slot.style.hat).is_equal(0)
	Game.settings.profile.loyalty.win(&"horns")
	StyleStalls.dress(slot, PackedInt32Array([0, 5, 0, 0, 0, 0]))
	stalls._step(slot, 1)
	assert_int(slot.style.hat).is_equal(KartStyle.HATS.find("Horns"))


## Every choice of every part is built, every hat has its height, every paint its scale, and a
## pattern never darkens the color past the shade, so the color stays the color under it.
func test_every_piece_is_built() -> void:
	assert_int(KartDress.HAT_LIFT.size()).is_equal(KartStyle.HATS.size())
	assert_int(KartDress.PAINT_SCALES.size()).is_equal(KartStyle.PAINTS.size())
	for index: int in range(1, KartStyle.HATS.size()):
		var hat: Node3D = auto_free(KartDress.hat(index, Color.RED))
		assert_object(hat).override_failure_message(KartStyle.HATS[index]).is_not_null()
	for index: int in range(1, KartStyle.FLAGS.size()):
		var flag: Node3D = auto_free(KartDress.flag(index, Color.BLUE))
		assert_object(flag).override_failure_message(KartStyle.FLAGS[index]).is_not_null()
	for index: int in range(1, KartStyle.PAINTS.size()):
		var image := KartDress.pattern_texture(index).get_image()
		var darkest := 1.0
		var lightest := 0.0
		for y: int in range(0, image.get_height(), 3):
			for x: int in range(0, image.get_width(), 3):
				darkest = minf(darkest, image.get_pixel(x, y).r)
				lightest = maxf(lightest, image.get_pixel(x, y).r)
		var floor_tone := KartDress.SUIT_INK if index == 4 else KartDress.SHADE
		assert_float(darkest).is_greater_equal(floor_tone - 0.01)
		assert_float(lightest).override_failure_message(KartStyle.PAINTS[index]).is_greater(darkest)
	for trail: int in KartStyle.TRAILS.size():
		var smoke: ExhaustSmoke = auto_free(ExhaustSmoke.new())
		smoke.dress(Color.GREEN, trail)
		add_child(smoke)
		assert_object(smoke.draw_pass_1).is_not_null()


## The gold plate is the plate itself in gold, and back to the plain one; the learner's L stays.
func test_the_gold_plate() -> void:
	var kart: Node3D = auto_free(
		KartVisuals.display_model(0, KartStyle.from_array([0, 0, 0, 0, 1]))
	)
	add_child(kart)
	KartVisuals.plate_like(kart, "JJ-123")
	assert_bool(_plate_on(kart).gold).is_true()
	KartVisuals.frame_plate(kart, 0)
	assert_bool(_plate_on(kart).gold).is_false()
	assert_str(KartVisuals._worn_on(kart)).is_equal("JJ-123")
	KartVisuals.plate_like(kart, "L")
	KartVisuals.frame_plate(kart, 1)
	assert_object(_plate_on(kart)).is_null()


## The license plate drawn on [param body]'s plate, or null for none or the learner's L.
func _plate_on(body: Node3D) -> LicensePlate:
	var plate := body.get_node_or_null("Plate")
	if plate == null:
		return null
	var drawn := plate.find_children("*", "LicensePlate", true, false)
	return drawn[0] as LicensePlate if not drawn.is_empty() else null


## Each kind of tire mark has its look: the plain ink, chalk paler, and dashes for the dashed.
func test_each_kind_of_tire_mark_has_its_look() -> void:
	var plain := TireMarks.look_for(0)
	assert_object(TireMarks.look()).is_same(plain)
	var chalk := TireMarks.look_for(1)
	var dashed := TireMarks.look_for(2)
	assert_object(chalk).is_not_same(plain)
	var ink: Color = chalk.get_shader_parameter(&"ink")
	assert_float(ink.r).is_greater(0.5)
	assert_float(float(plain.get_shader_parameter(&"dash"))).is_equal(0.0)
	assert_float(float(dashed.get_shader_parameter(&"dash"))).is_equal(TireMarks.DASH)


## A card back is worn only once won; the profile keeps the one chosen.
func test_a_card_back_is_worn_once_won() -> void:
	var profile := Game.settings.profile
	profile.loyalty.card_back = 1
	assert_int(CardBack.worn()).is_equal(0)
	profile.loyalty.win(&"gilt_back")
	assert_int(CardBack.worn()).is_equal(1)
	var file := ConfigFile.new()
	profile.loyalty.write(file)
	var read := LoyaltyState.new()
	read.read(file)
	assert_int(read.card_back).is_equal(1)


## The card back's pad turns this machine's cards to the next back the profile playing has won,
## and round to the house's.
func test_the_card_back_pad_turns_this_machines_back() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(DeviceInput.KEYBOARD, 0)] as Array[KartInput], 3)
	await _runner.simulate_frames(2, 17)
	var stalls := StyleStalls.add_to(match_node, Vector2i(4, 1))
	assert_int(stalls._areas.size()).is_equal(StyleStalls.WORDS.size())
	var slot := match_node.slots[0]
	var player := slot.input as PlayerInput
	var loyalty := Game.settings.profile.loyalty
	stalls._turn_back(slot, player)
	assert_int(loyalty.card_back).is_equal(0)
	loyalty.win(&"back_roads")
	stalls._turn_back(slot, player)
	assert_int(loyalty.card_back).is_equal(CardBack.STYLES.find("Hand-drawn"))
	stalls._turn_back(slot, player)
	assert_int(loyalty.card_back).is_equal(0)


## A flag streams out as its kart goes and hangs when it stops; dice thrown by a jolt swing and
## settle again.
func test_what_flies_moves_with_the_kart() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var flag := KartDress.flag(KartStyle.FLAGS.find("Banner"), Color.RED)
	holder.add_child(flag)
	var cloth := flag.get_node("Cloth") as Node3D
	for i: int in 4:
		await get_tree().process_frame
	assert_float(-cloth.rotation.z).is_greater(DressSway.CLOTH_DROOP * 0.5)
	# Driving off the way the kart faces, the flag's -X, as fast as counts as flying straight out.
	for i: int in 40:
		holder.global_position += flag.global_basis.x * -0.4
		await get_tree().process_frame
	assert_float(-cloth.rotation.z).is_less(DressSway.CLOTH_DROOP * 0.5)
	var dice := KartDress.flag(KartStyle.FLAGS.find("Fuzzy dice"), Color.BLUE)
	holder.add_child(dice)
	var die := dice.get_node("Die0") as Node3D
	await get_tree().process_frame
	holder.global_position += Vector3(3.0, 0.0, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(Vector2(die.rotation.x, die.rotation.z).length()).is_greater(0.01)


## A fresh pick's cards come in face down and are all turned over inside the half second nothing
## can be taken; a pick of which joker to keep is not dealt.
func test_a_fresh_pick_is_dealt_face_down() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(DeviceInput.KEYBOARD, 0)] as Array[KartInput], 3)
	await _runner.simulate_frames(2, 17)
	var kart := match_node.slots[0].kart
	var picker: JokerPicker = auto_free(JokerPicker.new())
	picker.size = Vector2(1600, 900)
	add_child(picker)
	var cards: Array[Joker] = [JOKERS.by_id(&"payday"), JOKERS.by_id(&"vulture")]
	var offer := JokerOffer.new(kart, cards)
	picker.show_offer(offer, kart)
	# Face down at first, the backs showing, until each is turned in its turn.
	assert_int(picker._backs.size()).is_equal(2)
	assert_bool(picker._backs[0].visible).is_true()
	assert_bool(picker._backs[1].visible).is_true()
	await await_millis(int(JokerOffer.SETTLE * 1000.0))
	picker.show_offer(offer, kart)
	for i: int in 2:
		assert_bool(picker._backs[i].visible).is_false()
		assert_float(picker._cards[i].scale.x).is_equal_approx(picker._cards[i].scale.y, 0.05)
	# Shown again, the same pick is not dealt a second time.
	picker.show_offer(offer, kart)
	assert_bool(picker._backs[0].visible).is_false()
	var kept: Array[Joker] = [JOKERS.by_id(&"odometer")]
	var keeping := JokerOffer.new(kart, kept)
	keeping.keeping = true
	picker.show_offer(keeping, kart)
	assert_array(picker._backs).is_empty()
