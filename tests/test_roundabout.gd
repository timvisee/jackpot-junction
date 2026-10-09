extends GdUnitTestSuite
## The roundabout and its editions, GAME.md 8.9: the ring dealt as both keystones are won, each bet
## counted from the moment it is dealt; a lap won with all seven, paying an edition and dealing the
## ring again half as much again; nothing ever reset; an edition moving a piece up a finish, worn
## on the wire as numbers after the style's; the roundabout on the map and in the pane.

const PATH := "user://test_roundabout.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	var loyalty := Game.settings.profile.loyalty
	loyalty.welcomed = true
	loyalty.member = "1234 5678"
	loyalty.win(&"slip_road")
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	LoyaltyDialog.stood_at = &""
	LoyaltyDialog.listed = false
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open_the_ring() -> void:
	Game.settings.profile.loyalty.win(&"card_shark")
	Game.settings.profile.loyalty.win(&"showroom")


## Shut until both keystones are won; then dealt seven bets, each counted from where its statistic
## was as it was dealt.
func test_the_ring_is_dealt_as_it_opens() -> void:
	var profile := Game.settings.profile
	profile.stats[&"banks"] = 50.0
	assert_bool(Loyalty.ring_open(profile)).is_false()
	Loyalty.settle(profile)
	assert_array(profile.loyalty.ring).is_empty()
	_open_the_ring()
	assert_bool(Loyalty.ring_open(profile)).is_true()
	Loyalty.settle(profile)
	var ring := profile.loyalty.ring
	assert_int(ring.size()).is_equal(Loyalty.RING_BETS)
	for bet: Dictionary in ring:
		assert_float(float(bet["from"])).is_equal(LifetimeStats.value_of(profile, bet["stat"]))
		assert_object(Loyalty.ring_progress(profile, bet)).is_equal(Vector2(0.0, bet["count"]))
		assert_str(Loyalty.ring_bet_of(bet)).is_not_empty()


## All seven met is a lap: printed on the card, an edition owed, and the ring dealt again, each bet
## half as much again as the last lap's of its kind; nothing won before is taken back.
func test_a_lap_deals_half_as_much_again() -> void:
	var profile := Game.settings.profile
	_open_the_ring()
	Loyalty.settle(profile)
	var first: Dictionary = {}
	for bet: Dictionary in profile.loyalty.ring:
		first[bet["stat"]] = float(bet["count"])
		profile.stats[StringName(bet["stat"])] = float(bet["from"]) + float(bet["count"])
	var won_before := profile.loyalty.won.duplicate()
	Loyalty.settle(profile)
	assert_int(profile.loyalty.laps).is_equal(1)
	assert_int(profile.loyalty.owed).is_equal(1)
	assert_int(profile.loyalty.ring.size()).is_equal(Loyalty.RING_BETS)
	for id: String in won_before:
		assert_bool(profile.loyalty.has_won(StringName(id))).is_true()
	for bet: Dictionary in profile.loyalty.ring:
		var base := 0.0
		for kind: Array in Loyalty.RING_POOL:
			if String(kind[0]) == String(bet["stat"]):
				base = float(kind[1])
		assert_float(float(bet["count"])).is_equal_approx(base * Loyalty.RING_GROWTH, base * 0.1)
	assert_float(Loyalty.ring_progress(profile, profile.loyalty.ring[0]).x).is_equal(0.0)
	var card: LoyaltyCard = auto_free(LoyaltyCard.of(profile))
	assert_int(card.laps).is_equal(1)


## An edition moves a piece won up a finish, Foil, Holographic, Polychrome, and no further; never a
## piece not won; and the ring, the laps and the editions are kept.
func test_an_edition_moves_a_piece_up_a_finish() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"fedora")
	profile.loyalty.owed = 4
	assert_bool(Loyalty.spend_edition(profile, "hat:Crown")).is_false()
	for finish: int in range(1, 4):
		assert_bool(Loyalty.spend_edition(profile, "hat:Fedora")).is_true()
		assert_int(Loyalty.finish_of(profile, "hat:Fedora")).is_equal(finish)
	assert_bool(Loyalty.spend_edition(profile, "hat:Fedora")).is_false()
	assert_int(profile.loyalty.owed).is_equal(1)
	assert_array(Array(LoyaltyEditions.pieces_of(profile))).contains(["hat:Fedora"])
	profile.loyalty.laps = 2
	profile.loyalty.ring = [{"stat": "banks", "count": 30.0, "from": 4.0}]
	var file := ConfigFile.new()
	profile.loyalty.write(file)
	var read := LoyaltyState.new()
	read.read(file)
	assert_int(read.laps).is_equal(2)
	assert_int(read.owed).is_equal(1)
	assert_int(int(read.editions["hat:Fedora"])).is_equal(3)
	assert_float(float(read.ring[0]["from"])).is_equal(4.0)


## A seat's style carries the finishes its profile has moved its pieces up to, after its six
## numbers, and only where there is one; read back, the kart wears them, and the plain is plain.
func test_the_finishes_ride_with_the_style() -> void:
	var profile := Game.settings.profile
	profile.loyalty.win(&"fedora")
	var fedora := KartStyle.HATS.find("Fedora")
	profile.loyalty.editions["hat:Fedora"] = 2
	var plain := PackedInt32Array([0, 0, 0, 0, 0, 0])
	assert_array(Array(Loyalty.with_finishes(profile, plain))).is_equal([0, 0, 0, 0, 0, 0])
	var worn := Loyalty.with_finishes(profile, PackedInt32Array([0, fedora, 0, 0, 0, 0]))
	assert_int(worn.size()).is_equal(12)
	var style := KartStyle.from_array(worn)
	assert_int(style.finish(1)).is_equal(2)
	assert_int(style.finish(0)).is_equal(0)
	Game.settings.set_seat_style(0, worn)
	assert_int((Game.settings.kart_styles[0] as PackedInt32Array).size()).is_equal(6)
	assert_int(KartStyle.from_array(Game.settings.seat_style(0)).finish(1)).is_equal(2)
	var told := Loyalty.clean_unlocks(Loyalty.unlocks_of(profile))
	assert_array(Array(told["editions"])).contains(["hat:Fedora=2"])


## Each finish is a sheen over a piece, a second pass on a copy of its own material.
func test_a_finish_is_a_sheen_over_the_piece() -> void:
	assert_object(KartDress.finish_material(0)).is_null()
	for level: int in range(1, 4):
		assert_object(KartDress.finish_material(level)).is_not_null()
	var hat: Node3D = auto_free(KartDress.hat(KartStyle.HATS.find("Fedora"), Color.RED))
	KartDress.wear_finish(hat, 1)
	for node: Node in hat.find_children("*", "MeshInstance3D", true, false):
		var material := (node as MeshInstance3D).material_override as BaseMaterial3D
		if material != null:
			assert_object(material.next_pass).is_same(KartDress.finish_material(1))
	var style := KartStyle.from_array([0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0])
	assert_int(style.finish(0)).is_equal(0)
	style = KartStyle.from_array([4, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0])
	assert_object(KartDress.paint(Color.RED, style).next_pass).is_same(KartDress.finish_material(3))


## On the map the cursor drives from a keystone to the roundabout, and its pane says how it opens,
## or its laps won as the card does, its bets and the edition owed.
func test_the_roundabout_on_the_map() -> void:
	var profile := Game.settings.profile
	for id: StringName in [&"dealers_visor", &"more_rare_cards", &"high_stakes", &"wages"]:
		profile.loyalty.win(id)
	LoyaltyDialog.stood_at = &"wages"
	var dialog := LoyaltyDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.map_view.drive_to(&"card_shark")
	dialog.cursor.finish()
	assert_bool(dialog.map_view.drive_toward(Vector2i.RIGHT)).is_true()
	dialog.cursor.finish()
	assert_str(String(dialog.cursor.at)).is_equal(String(Loyalty.ROUNDABOUT))
	assert_str(dialog.pane.shown).is_equal(String(Loyalty.ROUNDABOUT))
	var opens := dialog.pane.find_child("Opens", true, false) as Label
	assert_bool(opens.visible).is_true()
	var standing := dialog.pane.find_child("Standing", true, false) as Label
	assert_str(standing.text).is_equal(LoyaltyPane.CLOSED.to_upper())
	_open_the_ring()
	Loyalty.settle(profile)
	dialog.pane.show_roundabout(profile)
	assert_str(standing.text).is_equal(LoyaltyPane.OPEN.to_upper())
	profile.loyalty.laps = 2
	profile.loyalty.owed = 1
	dialog.pane.show_roundabout(profile)
	assert_str(standing.text).is_equal(LoyaltyCard.LAP % 2)
	var ring := dialog.pane.find_child("Ring", true, false) as VBoxContainer
	var shown := 0
	for line: Node in ring.get_children():
		shown += 0 if line.is_queued_for_deletion() else 1
	assert_int(shown).is_equal(Loyalty.RING_BETS)
	assert_bool((dialog.pane.find_child("Edition", true, false) as Button).visible).is_true()
	dialog.choose_edition()
	await get_tree().process_frame
	assert_object(dialog.find_child("Editions", true, false)).is_not_null()
	dialog._editions_done()
	# Open, the roundabout heads the list for good, its lap and its ring there, even with every
	# bet on the map won.
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		profile.loyalty.win(each.id)
	dialog.set_listed(true)
	var first := dialog.list.rows()[0]
	assert_str(String(first.id)).is_equal(String(Loyalty.ROUNDABOUT))
	assert_object(first.landmark).is_null()
	assert_str(first.title).contains(LoyaltyCard.LAP % 2)
	assert_int(int(first.come.y)).is_equal(Loyalty.RING_BETS)
	assert_int(dialog.list.rows().size()).is_equal(1)
	first.chosen.emit(first)
	assert_str(dialog.pane.shown).is_equal(String(Loyalty.ROUNDABOUT))


## A debug build's `++ --loyalty-lap=<n>` numbers the card, wins every landmark and puts the profile
## on lap n, an edition owed for each lap and the ring dealt for it; other arguments move nothing.
func test_the_lap_argument() -> void:
	var profile := Game.settings.profile
	profile.loyalty.member = ""
	Loyalty.read_arguments(PackedStringArray(["--other"]), Game.settings)
	assert_int(profile.loyalty.laps).is_equal(0)
	Loyalty.read_arguments(PackedStringArray(["--loyalty-lap=2"]), Game.settings)
	assert_str(profile.loyalty.member).is_not_empty()
	assert_bool(Loyalty.ring_open(profile)).is_true()
	assert_int(profile.loyalty.laps).is_equal(2)
	assert_int(profile.loyalty.owed).is_equal(2)
	assert_int(profile.loyalty.ring.size()).is_equal(Loyalty.RING_BETS)
	var base := 0.0
	for kind: Array in Loyalty.RING_POOL:
		if String(kind[0]) == String(profile.loyalty.ring[0]["stat"]):
			base = float(kind[1])
	var grown := base * Loyalty.RING_GROWTH * Loyalty.RING_GROWTH
	assert_float(float(profile.loyalty.ring[0]["count"])).is_equal_approx(grown, grown * 0.1)


## `++ --loyalty-near` puts every open bet of a statistic a step short, and
## `++ --loyalty-lost` makes every open thing of Lost Property certain in its room's next map.
func test_the_near_and_lost_arguments() -> void:
	var profile := Game.settings.profile
	Loyalty.read_arguments(
		PackedStringArray(["--loyalty-won=slip_road", "--loyalty-near", "--loyalty-lost"]),
		Game.settings
	)
	var near := 0
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if Loyalty.standing(profile, each) != Loyalty.Standing.OPEN:
			continue
		if each.kind == LoyaltyLandmark.Kind.STAT:
			var have := LifetimeStats.value_of(profile, each.stat)
			assert_float(have).is_less(each.count)
			assert_float(have).is_greater_equal(each.count - 30.0)
			near += 1
		if each.kind == LoyaltyLandmark.Kind.FIND:
			var rng := RandomNumberGenerator.new()
			assert_bool(LostProperty.turns_up(profile, each, rng, 0.0)).is_true()
	assert_int(near).is_greater(0)


## The plate, the trail and the tire marks take an edition as the rest of the dress does: a sheen
## over the gold plate, the trail's colors run through a ramp, and the marks a faint tint.
func test_the_plate_trail_and_marks_take_a_finish() -> void:
	var profile := Game.settings.profile
	for id: StringName in [&"clean_record", &"chip_trail", &"chalk_marks"]:
		profile.loyalty.win(id)
	var pieces := Array(LoyaltyEditions.pieces_of(profile))
	assert_array(pieces).contains(["frame:Gold", "trail:Poker chips", "marks:Chalk"])
	var smoke: ExhaustSmoke = auto_free(ExhaustSmoke.new())
	smoke.dress(Color.RED, KartStyle.TRAILS.find("Poker chips"), 3)
	add_child(smoke)
	var process := smoke.process_material as ParticleProcessMaterial
	assert_object(process.color_initial_ramp).is_not_null()
	smoke.dress(Color.RED, KartStyle.TRAILS.find("Poker chips"), 2)
	process = smoke.process_material as ParticleProcessMaterial
	assert_object(process.color_ramp).is_not_null()
	smoke.dress(Color.RED, KartStyle.TRAILS.find("Poker chips"), 0)
	process = smoke.process_material as ParticleProcessMaterial
	assert_object(process.color_ramp).is_null()
	assert_object(process.color_initial_ramp).is_null()
	var chalk := KartStyle.MARKS.find("Chalk")
	assert_int(int(TireMarks.look_for(chalk, 2).get_shader_parameter(&"finish"))).is_equal(2)
	assert_object(TireMarks.look_for(chalk, 2)).is_not_same(TireMarks.look_for(chalk, 0))
	var body: Node3D = auto_free(Node3D.new())
	body.set_meta(&"frame", 1)
	body.set_meta(&"frame_finish", 2)
	var plate := KartVisuals.plate_like(body, "JJ 123")
	var sheened := 0
	for node: Node in plate.find_children("*", "MeshInstance3D", true, false):
		var material := (node as MeshInstance3D).material_override as BaseMaterial3D
		if material != null and material.next_pass == KartDress.finish_material(2):
			sheened += 1
	assert_int(sheened).is_greater(0)
