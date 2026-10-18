extends GdUnitTestSuite
## The Fez and the Magnet, GAME.md 4.4 and 8.9: two pieces of dress at the end of their lists, so
## every number worn before means what it did, round the wire and in a saved style alike; won with
## the Ten Times Bar and Chip Alley; and the Magnet growing while its kart pulls chips in, by a Chip
## Magnet or Magnet Hubcaps, on every screen, then easing back, see [MagnetFlag].

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const CHIP_MAGNET: PowerUp = preload("res://data/powerups/coin_magnet.tres")

var _runner: GdUnitSceneRunner


func _start(styles: Array) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 7, [], [], styles)
	return match_node


## The style that wears both, as the numbers that go over the wire.
func _both() -> PackedInt32Array:
	return PackedInt32Array(
		[0, KartStyle.HATS.find("Fez"), KartStyle.FLAGS.find("Magnet"), 0, 0, 0]
	)


## What moves the magnet on [param kart].
func _pull_of(kart: Kart) -> MagnetFlag:
	var found := kart.find_children("*", "MagnetFlag", true, false)
	return found[0] as MagnetFlag if not found.is_empty() else null


## Each is the last of its part, so the pieces before them keep their numbers, and both survive
## the numbers a style is kept and sent as.
func test_the_pieces_come_last_and_survive_the_numbers() -> void:
	var fez := KartStyle.HATS.find("Fez")
	var magnet := KartStyle.FLAGS.find("Magnet")
	assert_int(fez).is_equal(KartStyle.HATS.size() - 1)
	assert_int(magnet).is_equal(KartStyle.FLAGS.size() - 1)
	assert_str(KartStyle.HATS[fez - 1]).is_equal("Paper hat")
	assert_str(KartStyle.FLAGS[magnet - 1]).is_equal("Kit's rag")
	var style := KartStyle.from_array(_both())
	assert_int(style.hat).is_equal(fez)
	assert_int(style.flag).is_equal(magnet)
	assert_array(Array(style.to_array())).contains_exactly(Array(_both()))
	# One past them is a choice this build has never heard of, and plain.
	var beyond := KartStyle.from_array(PackedInt32Array([0, fez + 1, magnet + 1, 0, 0, 0]))
	assert_array(Array(beyond.to_array())).contains_exactly([0, 0, 0, 0, 0, 0])


## The fez is a hat the roof marker clears, its felt and its tassel; the magnet hangs off a pivot
## the pole's sway moves, its bar and two steel poles, with what moves it.
func test_both_are_built() -> void:
	var fez: Node3D = auto_free(KartDress.hat(KartStyle.HATS.find("Fez"), Color.RED))
	assert_object(fez).is_not_null()
	assert_int(fez.find_children("*", "MeshInstance3D", true, false).size()).is_equal(5)
	assert_float(KartDress.HAT_LIFT[KartStyle.HATS.find("Fez")]).is_greater(
		KartDress.FEZ_LIFT + KartDress.FEZ_TALL
	)
	var flag: Node3D = auto_free(KartDress.flag(KartStyle.FLAGS.find("Magnet"), Color.BLUE))
	assert_object(flag).is_not_null()
	var cloth := flag.get_node("Cloth") as Node3D
	var sway := flag.get_node("Sway") as DressSway
	assert_array(sway.pivots).contains_exactly([cloth])
	var magnet := cloth.get_node("Magnet") as Node3D
	assert_int(magnet.find_children("*", "MeshInstance3D", false, false).size()).is_equal(2)
	assert_object((cloth.get_node("Pull") as MagnetFlag).magnet).is_same(magnet)
	# A finish lays its sheen over the magnet as over any flag.
	KartDress.wear_finish(flag, 2)
	var bar := magnet.get_node("Bar") as MeshInstance3D
	assert_object((bar.material_override as BaseMaterial3D).next_pass).is_not_null()


## Both are worn on every screen: a client's puppet is dressed in them as the host's kart is.
func test_a_client_sees_both() -> void:
	var host := _start([_both()])
	await _runner.simulate_frames(12, 17)
	assert_object(host.kart_of(0).find_child("Hat", true, false)).is_not_null()
	assert_object(_pull_of(host.kart_of(0))).is_not_null()
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	await _runner.simulate_frames(2, 17)
	var puppet: Kart = client.slots[0].kart
	assert_array(Array(puppet.style.to_array())).contains_exactly(Array(_both()))
	assert_object(_pull_of(puppet)).is_not_null()


## A Chip Magnet grows the magnet to half as big again, beating and rocking with its field out,
## and as it runs out the magnet eases back to its own size.
func test_the_magnet_grows_while_a_chip_magnet_pulls() -> void:
	var match_node := _start([_both(), PackedInt32Array()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pull := _pull_of(kart)
	assert_bool(pull.is_processing()).is_true()
	assert_float(pull.charge()).is_equal(0.0)
	assert_vector(pull.magnet.scale).is_equal(Vector3.ONE)
	assert_object(pull.magnet.get_node_or_null("Field")).is_null()
	CHIP_MAGNET.activate(kart)
	assert_bool(MagnetFlag.pulling(kart)).is_true()
	await _runner.simulate_frames(40, 17)
	assert_float(pull.charge()).is_greater(0.95)
	assert_float(pull.magnet.scale.x).is_greater(MagnetFlag.GROWN - MagnetFlag.BEAT - 0.05)
	var field := pull.magnet.get_node("Field") as MeshInstance3D
	assert_bool(field.visible).is_true()
	# The kart without the flag pulls nothing in.
	assert_bool(MagnetFlag.pulling(match_node.kart_of(1))).is_false()
	kart.end_effect(&"magnet")
	assert_bool(MagnetFlag.pulling(kart)).is_false()
	await _runner.simulate_frames(60, 17)
	assert_float(pull.charge()).is_equal(0.0)
	assert_vector(pull.magnet.scale).is_equal(Vector3.ONE)
	assert_float(pull.magnet.rotation.x).is_equal_approx(MagnetFlag.ROLL, 0.0001)
	assert_bool(field.visible).is_false()


## Magnet Hubcaps grow it for as long as they are in the hand, and a Copy Cat of them too.
func test_magnet_hubcaps_grow_it_while_held() -> void:
	var match_node := _start([_both()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var pull := _pull_of(kart)
	var hubcaps := kart.jokers.add(match_node.joker_catalog.by_id(&"magnet_hubcaps"))
	assert_bool(MagnetFlag.pulling(kart)).is_true()
	await _runner.simulate_frames(40, 17)
	assert_float(pull.charge()).is_greater(0.95)
	kart.jokers.remove(hubcaps)
	assert_bool(MagnetFlag.pulling(kart)).is_false()
	await _runner.simulate_frames(60, 17)
	assert_float(pull.charge()).is_equal(0.0)
	assert_vector(pull.magnet.scale).is_equal(Vector3.ONE)


## A client grows the magnet on the host's kart from what the snapshot brings it, a Chip Magnet's
## reach and a hand with Magnet Hubcaps in it, and lets it go when they are gone.
func test_a_client_sees_the_magnet_grow() -> void:
	var host := _start([_both(), _both()])
	await _runner.simulate_frames(12, 17)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(host.build_snapshot())
	await _runner.simulate_frames(2, 17)
	var pulled := client.slots[0].kart
	var held := client.slots[1].kart
	assert_bool(MagnetFlag.pulling(pulled)).is_false()
	CHIP_MAGNET.activate(host.kart_of(0))
	host.kart_of(1).jokers.add(host.joker_catalog.by_id(&"magnet_hubcaps"))
	client.apply_snapshot(host.build_snapshot())
	assert_bool(MagnetFlag.pulling(pulled)).is_true()
	assert_bool(MagnetFlag.pulling(held)).is_true()
	await _runner.simulate_frames(40, 17)
	assert_float(_pull_of(pulled).charge()).is_greater(0.95)
	assert_float(_pull_of(held).charge()).is_greater(0.95)
	host.kart_of(0).end_effect(&"magnet")
	client.apply_snapshot(host.build_snapshot())
	assert_bool(MagnetFlag.pulling(pulled)).is_false()


## A decoy's magnet grows as its owner's does, since it is worth anything only for as long as it
## is taken for them.
func test_a_decoy_pulls_as_its_owner_does() -> void:
	var match_node := _start([_both()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var item: DecoyKartPowerUp = load("res://data/powerups/decoy_kart.tres")
	item.activate(kart)
	await _runner.simulate_frames(4, 17)
	var decoy: Kart = null
	for child: Node in match_node.get_children():
		var other := child as Kart
		if other != null and other.is_decoy():
			decoy = other
	assert_object(decoy).is_not_null()
	assert_object(_pull_of(decoy)).is_not_null()
	assert_bool(MagnetFlag.pulling(decoy)).is_false()
	CHIP_MAGNET.activate(kart)
	assert_bool(MagnetFlag.pulling(decoy)).is_true()


## A kart only to look at, in the kart dialog or on the podium, has no kart to pull for it: its
## magnet stands still at its own size.
func test_a_model_to_look_at_stays_as_it_is() -> void:
	var model: Node3D = auto_free(KartVisuals.display_model(0, KartStyle.from_array(_both())))
	add_child(model)
	await get_tree().process_frame
	var found := model.find_children("*", "MagnetFlag", true, false)
	assert_int(found.size()).is_equal(1)
	assert_bool((found[0] as MagnetFlag).is_processing()).is_false()
	assert_bool(MagnetFlag.pulling(null)).is_false()


## Neither is anybody's from the start, nor a bot's: the Fez is won with the Ten Times Bar and the
## Magnet with Chip Alley, alongside what each paid before, and the rack says where.
func test_both_are_won_in_the_program() -> void:
	var fez := KartStyle.HATS.find("Fez")
	var magnet := KartStyle.FLAGS.find("Magnet")
	var none := PackedStringArray()
	assert_bool(KartStyle.allowed(1, fez, none)).is_false()
	assert_bool(KartStyle.allowed(2, magnet, none)).is_false()
	assert_str(KartOwner.won_at(1, fez)).is_equal("The Ten Times Bar")
	assert_str(KartOwner.won_at(2, magnet)).is_equal("Chip Alley")
	var profile := Profile.new()
	assert_array(Array(Loyalty.unlocks_of(profile)["dress"])).not_contains(["hat:Fez"])
	profile.loyalty.win(&"cursed_cards")
	profile.loyalty.win(&"chip_trail")
	var dress: PackedStringArray = Loyalty.unlocks_of(profile)["dress"]
	assert_array(Array(dress)).contains(["hat:Fez", "flag:Magnet", "trail:Poker chips"])
	assert_bool(KartStyle.allowed(1, fez, dress)).is_true()
	assert_bool(KartStyle.allowed(2, magnet, dress)).is_true()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i: int in 300:
		var style := KartStyle.random(rng)
		assert_int(style.hat).is_not_equal(fez)
		assert_int(style.flag).is_not_equal(magnet)
