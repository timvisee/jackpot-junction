extends GdUnitTestSuite
## The slot machine of GAME.md 3.15: what its reels pay, how often they come up, and a kart betting
## a quarter of its pot as it drives onto one, once in ten seconds, and being paid as they stop.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const VAULT: ArenaLayout = preload("res://data/maps/vault.tres")

var _runner: GdUnitSceneRunner
var _spun: Array[Array] = []
var _paid: Array[Array] = []


func before_test() -> void:
	_spun.clear()
	_paid.clear()
	Events.slot_spun.connect(_on_spun)
	Events.slot_paid.connect(_on_paid)


func after_test() -> void:
	Events.slot_spun.disconnect(_on_spun)
	Events.slot_paid.disconnect(_on_paid)


func _on_spun(slot: int, pad: int, bet: int, faces: PackedByteArray) -> void:
	_spun.append([slot, pad, bet, faces])


func _on_paid(slot: int, pad: int, won: int) -> void:
	_paid.append([slot, pad, won])


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = VAULT
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	return match_node


## Three sevens pay ten bets, any other three of a kind three, a pair one, and the rest nothing.
func test_what_the_reels_pay() -> void:
	var face := SlotPad.Face
	assert_int(SlotPad.pays(PackedByteArray([face.SEVEN, face.SEVEN, face.SEVEN]))).is_equal(10)
	assert_int(SlotPad.pays(PackedByteArray([face.BELL, face.BELL, face.BELL]))).is_equal(3)
	assert_int(SlotPad.pays(PackedByteArray([face.BELL, face.CHIP, face.BELL]))).is_equal(1)
	assert_int(SlotPad.pays(PackedByteArray([face.SEVEN, face.BAR, face.LEMON]))).is_equal(0)


## The reels come up as often as the odds say, so a pull is worth a little more than it costs.
func test_the_odds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var counted := {0: 0, 1: 0, 3: 0, 10: 0}
	var draws := 20000
	var paid := 0
	for i: int in draws:
		var pays := SlotPad.pays(SlotPad.draw(rng))
		counted[pays] += 1
		paid += pays
	assert_float(counted[10] / float(draws)).is_between(0.03, 0.05)
	assert_float(counted[3] / float(draws)).is_between(0.105, 0.135)
	assert_float(counted[1] / float(draws)).is_between(0.32, 0.36)
	assert_float(paid / float(draws)).is_between(1.05, 1.15)


## Every map that is played has two machines, one across from the other; the showdown's, with no
## chips in it to bet, has none.
func test_the_maps_have_their_machines() -> void:
	for id: StringName in ArenaMaps.IDS:
		var grid := ArenaMaps.layout(id).parse()
		if id == &"showdown":
			assert_array(grid.slot_pads).is_empty()
			continue
		assert_int(grid.slot_pads.size()).override_failure_message(String(id)).is_equal(2)
		assert_bool(grid.is_point_symmetric()).is_true()


## A kart driving onto the machine with chips bets a quarter of them, and is paid what the reels
## show once they stop; staying on, it does not pull again for ten seconds, and a pot of a few
## chips does not pull at all.
func test_a_kart_bets_and_is_paid() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var pad: SlotPad = match_node.arena.get_tree().get_nodes_in_group(SlotPad.GROUP)[0]
	var kart := match_node.kart_of(0)
	kart.pot.add_coins(40)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(4, 17)
	assert_int(_spun.size()).is_equal(1)
	assert_int(int(_spun[0][2])).is_equal(10)
	assert_int(kart.pot.coins).is_equal(30)
	assert_bool(pad.is_spinning()).is_true()
	await _runner.simulate_frames(110, 17)
	assert_int(_paid.size()).is_equal(1)
	var won := int(_paid[0][2])
	assert_int(won).is_equal(SlotPad.pays(_spun[0][3]) * 10)
	assert_int(kart.pot.coins).is_equal(30 + won)
	# Still on it: no second pull until it has rested.
	await _runner.simulate_frames(30, 17)
	assert_int(_spun.size()).is_equal(1)
	var other := match_node.kart_of(1)
	other.pot.add_coins(SlotPad.LEAST_COINS - 1)
	kart.global_position = Vector3(0.0, 0.0, 0.0)
	other.global_position = pad.global_position
	await _runner.simulate_frames(10, 17)
	assert_int(_spun.size()).is_equal(1)
