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
	# The bodies of 8.1b besides the hats, flags and marks.
	assert_int(also).is_equal(9)


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
## pattern never darkens the color past the shade, so the color stays the color under it. The suits
## are no pattern but stickers, below.
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
		if index == KartStickers.PAINT:
			assert_object(KartDress.pattern_texture(index)).is_null()
			continue
		var image := KartDress.pattern_texture(index).get_image()
		var darkest := 1.0
		var lightest := 0.0
		for y: int in range(0, image.get_height(), 3):
			for x: int in range(0, image.get_width(), 3):
				darkest = minf(darkest, image.get_pixel(x, y).r)
				lightest = maxf(lightest, image.get_pixel(x, y).r)
		assert_float(darkest).is_greater_equal(KartDress.SHADE - 0.01)
		assert_float(lightest).override_failure_message(KartStyle.PAINTS[index]).is_greater(darkest)
	for trail: int in KartStyle.TRAILS.size():
		var smoke: ExhaustSmoke = auto_free(ExhaustSmoke.new())
		smoke.dress(Color.GREEN, trail)
		add_child(smoke)
		assert_object(smoke.draw_pass_1).is_not_null()


## The suits are three stickers on a plain kart, a spade on the nose and a heart and a diamond on
## its sides, each laid on the body's faces; a kart painted over takes them off and back on.
func test_the_suits_are_three_stickers() -> void:
	var suits := KartStyle.from_array([KartStickers.PAINT, 0, 0, 0, 0, 0])
	var kart: Node3D = auto_free(KartVisuals.display_model(0, suits))
	add_child(kart)
	var hull := KartStickers._hull(kart.get_node("Model"))
	var stickers := hull.get_node("Stickers")
	assert_int(stickers.get_child_count()).is_equal(3)
	for sticker: MeshInstance3D in stickers.get_children():
		assert_int(sticker.mesh.get_faces().size()).is_greater(0)
	assert_object((hull.material_override as StandardMaterial3D).albedo_texture).is_null()
	KartStickers.dress(kart.get_node("Model"), 1)
	assert_object(hull.get_node_or_null("Stickers")).is_null()
	KartStickers.dress(kart.get_node("Model"), KartStickers.PAINT)
	assert_int(hull.get_node("Stickers").get_child_count()).is_equal(3)


## A sticker's picture: its suit in the middle in the card's red or black, cream round it, an ink
## rim, and nothing past the disc.
func test_a_sticker_is_a_suit_on_a_cream_disc() -> void:
	for suit: int in [SuitArt.Suit.SPADE, SuitArt.Suit.HEART]:
		var image := KartStickers.printed(suit).get_image()
		var side := image.get_width()
		var ink := KartStickers.BLACK if suit == SuitArt.Suit.SPADE else KartStickers.RED
		assert_bool(_near(image.get_pixel(side / 2, side / 2), ink)).is_true()
		var cream := image.get_pixel(side / 2, int(side * 0.1))
		assert_bool(_near(cream, KartStickers.CREAM)).is_true()
		var rim := image.get_pixel(side / 2, int(side * (0.5 - KartStickers.DISC + 0.02)))
		assert_bool(_near(rim, KartStickers.BLACK)).is_true()
		assert_float(image.get_pixel(1, 1).a).is_equal(0.0)


## Whether [param a] is [param b] as near as eight bits a channel keep it.
func _near(a: Color, b: Color) -> bool:
	return Vector4(a.r - b.r, a.g - b.g, a.b - b.b, a.a - b.a).length() < 0.02


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


## Each kind of tire mark has its look: the plain ink, chalk paler, dashes for the dashed, and the
## pencil drawn rather than laid, unbroken by dashes.
func test_each_kind_of_tire_mark_has_its_look() -> void:
	var plain := TireMarks.look_for(0)
	assert_object(TireMarks.look()).is_same(plain)
	var chalk := TireMarks.look_for(1)
	var dashed := TireMarks.look_for(2)
	var pencil := TireMarks.look_for(3)
	assert_object(chalk).is_not_same(plain)
	var ink: Color = chalk.get_shader_parameter(&"ink")
	assert_float(ink.r).is_greater(0.5)
	assert_float(float(plain.get_shader_parameter(&"dash"))).is_equal(0.0)
	assert_float(float(dashed.get_shader_parameter(&"dash"))).is_equal(TireMarks.DASH)
	assert_float(float(pencil.get_shader_parameter(&"dash"))).is_equal(0.0)
	for look: ShaderMaterial in [plain, chalk, dashed]:
		assert_bool(look.get_shader_parameter(&"pencil")).is_false()
	assert_bool(pencil.get_shader_parameter(&"pencil")).is_true()


## A card back is worn only once won, the rooms' cards face down with it, the house's deck's own
## red lattice until then; the profile keeps the one chosen.
func test_a_card_back_is_worn_once_won() -> void:
	var profile := Game.settings.profile
	profile.loyalty.card_back = 1
	assert_int(CardBack.worn()).is_equal(0)
	assert_object(Surfaces.card_back()).is_same(Surfaces.CARD_BACKS[0])
	assert_str(Surfaces.CARD_BACKS[0].resource_path).ends_with("card_back.png")
	profile.loyalty.win(&"gilt_back")
	assert_int(CardBack.worn()).is_equal(1)
	assert_object(Surfaces.card_back()).is_same(Surfaces.CARD_BACKS[1])
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
	var loyalty := Game.settings.profile.loyalty
	stalls._turn_back()
	assert_int(loyalty.card_back).is_equal(0)
	loyalty.win(&"back_roads")
	stalls._turn_back()
	assert_int(loyalty.card_back).is_equal(CardBack.STYLES.find("Hand-drawn"))
	stalls._turn_back()
	assert_int(loyalty.card_back).is_equal(0)


## A flag streams out as its kart goes, beating round its pole and never rolling over, and hangs
## when it stops; a windsock fills and a tape runs out as it picks up speed, and droop and wind in
## again as it stops, rising and falling rather than at once; dice hang back as it drives off,
## swing forward as it brakes and out as it turns. Worked out on the steps the karts move on.
func test_what_flies_moves_with_the_kart() -> void:
	var holder: Node3D = auto_free(Node3D.new())
	add_child(holder)
	var flag := KartDress.flag(KartStyle.FLAGS.find("Banner"), Color.RED)
	holder.add_child(flag)
	var cloth := flag.get_node("Cloth") as Node3D
	for i: int in 4:
		await get_tree().physics_frame
	assert_float(-cloth.rotation.z).is_greater(DressSway.CLOTH_DROOP * 0.5)
	# Driving off the way the kart faces, the flag's -X, as fast as counts as flying straight out.
	for i: int in 40:
		holder.global_position += flag.global_basis.x * -0.2
		await get_tree().physics_frame
	assert_float(-cloth.rotation.z).is_less(DressSway.CLOTH_DROOP * 0.5)
	# It turns round its pole and never rolls over on its edge.
	assert_float(cloth.rotation.x).is_equal(0.0)
	# In the flag's own frame, a step at a time: forward is -X.
	var step := 1.0 / 60.0
	var sock := _sway("Windsock", Color.BLUE)
	var tape := _sway("Tape measure", Color.BLUE)
	for sway: DressSway in [sock, tape]:
		var at := Vector3.ZERO
		for i: int in 3:
			sway.step(at, Basis.IDENTITY, step)
		assert_float(sway.blown()).is_less(0.05)
		at = _drive(sway, at, Vector3(-DressSway.FULL_SPEED * step, 0.0, 0.0), 6, step)
		# Filling, not full at once.
		assert_float(sway.blown()).is_between(0.05, 0.6)
		at = _drive(sway, at, Vector3(-DressSway.FULL_SPEED * step, 0.0, 0.0), 120, step)
		assert_float(sway.blown()).is_greater(0.9)
		_drive(sway, at, Vector3.ZERO, 120, step)
		assert_float(sway.blown()).is_less(0.1)
	var wound := tape.pivots[0].scale.x
	assert_float(wound).is_equal_approx(DressSway.TAPE_SHORT, 0.05)
	var dice := _sway("Fuzzy dice", Color.BLUE)
	var at := Vector3.ZERO
	dice.step(at, Basis.IDENTITY, step)
	# Picking up speed forward, -X, for a third of a second: they hang back, +X.
	var going := Vector3.ZERO
	for i: int in 20:
		going.x -= 0.15
		at += going * step
		dice.step(at, Basis.IDENTITY, step)
	assert_float(dice.hang_of(0).x).is_greater(0.2)
	# Braking hard: they swing forward.
	for i: int in 20:
		going.x = minf(going.x + 0.15, 0.0)
		at += going * step
		dice.step(at, Basis.IDENTITY, step)
	assert_float(dice.hang_of(0).x).is_less(-0.2)
	# Pulled round toward +Z, as in a turn: they swing out the other way.
	var settle := _drive(dice, at, Vector3.ZERO, 300, step)
	going = Vector3.ZERO
	for i: int in 20:
		going.z += 0.15
		settle += going * step
		dice.step(settle, Basis.IDENTITY, step)
	assert_float(dice.hang_of(0).z).is_less(-0.2)


## A flag swung round its pole, as turning a kart in place in the kart dialog swings it, comes
## back to streaming straight back, hanging, once it is settled, see [method DressSway.settle].
func test_a_settled_flag_hangs_straight_back() -> void:
	var sway := _sway("Banner", Color.RED)
	var cloth := sway.pivots[0]
	var step := 1.0 / 60.0
	var at := Vector3.ZERO
	sway.step(at, Basis.IDENTITY, step)
	# Pulled round sideways, +Z, the cloth turns round its pole away from it.
	_drive(sway, at, Vector3(0.0, 0.0, 0.1), 30, step)
	assert_float(absf(cloth.rotation.y)).is_greater(0.5)
	for i: int in 180:
		sway.settle(step)
	assert_float(absf(cloth.rotation.y)).is_less(0.15)
	assert_float(-cloth.rotation.z).is_greater(DressSway.CLOTH_DROOP * 0.8)


## Confetti is cut from a few sheets of the player's color, a shade or a hue apart, each scrap from
## one at random; a finish colors it its own way instead.
func test_confetti_comes_in_a_few_shades() -> void:
	var smoke: ExhaustSmoke = auto_free(ExhaustSmoke.new())
	smoke.dress(Color.BLUE, KartStyle.TRAILS.find("Confetti"))
	add_child(smoke)
	var process := smoke.process_material as ParticleProcessMaterial
	var sheets := (process.color_initial_ramp as GradientTexture1D).gradient
	var shades := {}
	for color: Color in sheets.colors:
		shades[color.to_html()] = true
	assert_int(shades.size()).is_greater_equal(4)
	smoke.dress(Color.BLUE, KartStyle.TRAILS.find("Confetti"), 3)
	process = smoke.process_material as ParticleProcessMaterial
	assert_object(process.color_initial_ramp).is_not_null()
	assert_object(process.color_initial_ramp).is_not_same(sheets)


## The sway of a flag of [param named] in [param color], to be stepped by hand.
func _sway(named: String, color: Color) -> DressSway:
	var flag := KartDress.flag(KartStyle.FLAGS.find(named), color)
	var sway := flag.get_node("Sway") as DressSway
	sway.set_physics_process(false)
	auto_free(flag)
	return sway


## [param sway] stepped [param steps] times from [param at], [param by] further each step.
func _drive(sway: DressSway, at: Vector3, by: Vector3, steps: int, step: float) -> Vector3:
	var here := at
	for i: int in steps:
		here += by
		sway.step(here, Basis.IDENTITY, step)
	return here


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


## Kit's pencil leaves its scribbles each turned its own way, not all lying the one way.
func test_the_pencil_scribbles_lie_every_way() -> void:
	var smoke: ExhaustSmoke = auto_free(ExhaustSmoke.new())
	smoke.dress(Color.BLUE, KartStyle.TRAILS.find("Pencil"))
	add_child(smoke)
	var process := smoke.process_material as ParticleProcessMaterial
	assert_bool(process.particle_flag_rotate_y).is_true()
	assert_float(process.angle_max - process.angle_min).is_greater(180.0)
