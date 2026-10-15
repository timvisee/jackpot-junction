extends GdUnitTestSuite
## The slot machine of GAME.md 3.15: what its reels pay, how often they come up, and a kart betting
## a quarter of its pot as it drives onto one, once in ten seconds, and being paid as they stop.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const VAULT: ArenaLayout = preload("res://data/maps/vault.tres")
const CROSSFIRE: ArenaLayout = preload("res://data/maps/crossfire.tres")

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


func _start_match(layout: ArenaLayout = VAULT) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = layout
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
	# A quarter of a pot's first hundred chips is bet, and half of the rest.
	assert_int(SlotPad.bet_of(4)).is_equal(1)
	assert_int(SlotPad.bet_of(40)).is_equal(10)
	assert_int(SlotPad.bet_of(100)).is_equal(25)
	assert_int(SlotPad.bet_of(400)).is_equal(175)
	# The reels that made it are the ones lit.
	var pair := PackedByteArray([face.BELL, face.CHIP, face.BELL])
	assert_that(SlotPad.winning(pair)).is_equal(Vector3(1.0, 0.0, 1.0))
	var three := PackedByteArray([face.BELL, face.BELL, face.BELL])
	assert_that(SlotPad.winning(three)).is_equal(Vector3.ONE)
	var none := PackedByteArray([face.SEVEN, face.BAR, face.LEMON])
	assert_that(SlotPad.winning(none)).is_equal(Vector3.ZERO)


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
	# Crossfire's machine has no coin pad beside it for a kart parked on it to pick up.
	var match_node := _start_match(CROSSFIRE)
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


## The row of machines on the far rail: on a map with slot machines, lit by a big cash-out and not a
## small one, and longer for a Jackpot pile let grow full and emptied by one kart.
func test_the_machines_on_the_rail() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var machines := match_node.arena.get_node("RailMachines") as RailMachines
	assert_object(machines).is_not_null()
	assert_int(machines.get_child_count()).is_equal(RailMachines.ALONG.size())
	Events.bank_completed.emit(0, 10, 1.0, RailMachines.BIG_BANK - 1)
	assert_float(machines._lit).is_equal(0.0)
	Events.bank_completed.emit(0, 100, 5.0, RailMachines.BIG_BANK)
	assert_float(machines._lit).is_equal(RailMachines.LIT)
	machines._lit = 0.0
	var cap := match_node.rules.jackpot_cap
	Events.jackpot_collected.emit(0, cap - 1)
	Events.jackpot_collected.emit(1, 1)
	Events.jackpot_emptied.emit(0)
	assert_float(machines._lit).is_equal(0.0)
	Events.jackpot_collected.emit(1, cap)
	Events.jackpot_emptied.emit(0)
	assert_float(machines._lit).is_equal(RailMachines.JACKPOT_LIT)


## A pull lights the pad's edge in the bettor's color, and three sevens throw a party: the room's
## lights turn on the machine and the row on the rail lights up.
func test_three_sevens_throw_a_party() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var pad: SlotPad = match_node.arena.get_tree().get_nodes_in_group(SlotPad.GROUP)[0]
	var kart := match_node.kart_of(0)
	var sevens := PackedByteArray([SlotPad.Face.SEVEN, SlotPad.Face.SEVEN, SlotPad.Face.SEVEN])
	Events.slot_spun.emit(0, pad.index, 10, sevens)
	assert_that(pad._rim.emission).is_equal(Palette.player_color(kart.color_index))
	assert_float(pad._rim.emission_energy_multiplier).is_greater(0.0)
	await _runner.simulate_frames(110, 17)
	assert_int(_paid.size()).is_equal(1)
	assert_int(int(_paid[0][2])).is_equal(SlotPad.SEVENS_PAY * 10)
	assert_bool(match_node.arena.disco.is_focused(pad)).is_true()
	var machines := match_node.arena.get_node("RailMachines") as RailMachines
	assert_float(machines._lit).is_greater(0.0)
	await _runner.simulate_frames(240, 17)
	assert_bool(match_node.arena.disco.is_focused(pad)).is_false()
	assert_float(pad._rim.emission_energy_multiplier).is_equal(0.0)


## Lucky Charm in the bettor's hand pays a pair as three of a kind.
func test_lucky_charm_pays_a_pair_as_three() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var pad: SlotPad = match_node.arena.get_tree().get_nodes_in_group(SlotPad.GROUP)[0]
	var kart := match_node.kart_of(0)
	kart.jokers.add(load("res://data/jokers/lucky_charm.tres"))
	var pair := PackedByteArray([SlotPad.Face.BELL, SlotPad.Face.BELL, SlotPad.Face.LEMON])
	Events.slot_spun.emit(0, pad.index, 10, pair)
	await _runner.simulate_frames(110, 17)
	assert_int(_paid.size()).is_equal(1)
	assert_int(int(_paid[0][2])).is_equal(SlotPad.THREE_PAY * 10)


## On Lucky Crossing the machines lie along the walls beside the Junction, flush against them and in
## the middle of the map from top to bottom; on Crossfire they lie across, as a `$` does with no
## wall beside it.
func test_a_machine_beside_a_wall_lies_along_it() -> void:
	var match_node := _start_match(load("res://data/maps/lucky_crossing.tres"))
	await _runner.simulate_frames(4, 17)
	var grid := match_node.arena.grid
	for node: Node in match_node.arena.get_tree().get_nodes_in_group(SlotPad.GROUP):
		var pad := node as SlotPad
		if pad == null:
			continue
		var cell := grid.slot_pads[pad.index]
		var side := SlotPad.beside_wall(grid, cell)
		assert_int(side).is_not_equal(0)
		assert_float(absf(pad.rotation.y)).is_equal_approx(PI * 0.5, 0.001)
		assert_float(pad.position.z).is_equal_approx(0.0, 0.001)
		var wall := grid.cell_center(cell + Vector2i(side, 0))
		var wall_face := wall.x - side * grid.cell_size * 0.5
		var pad_face := pad.position.x + side * SlotPad.PLATE.y * 0.5
		assert_float(absf(wall_face - pad_face)).is_less(0.01)
	var crossfire := _start_match(CROSSFIRE)
	await _runner.simulate_frames(4, 17)
	for node: Node in crossfire.arena.get_tree().get_nodes_in_group(SlotPad.GROUP):
		if node is SlotPad and node.get_parent() == crossfire.arena:
			assert_float((node as SlotPad).rotation.y).is_equal(0.0)


## A kart that drives on with too few chips is turned away: the edge goes gray, no clock. One that
## drives off after its pull and on again while resting is shown its wait; one left on it as its
## reels stop is not.
func test_a_kart_turned_away_is_shown_why() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var pad: SlotPad = match_node.arena.get_tree().get_nodes_in_group(SlotPad.GROUP)[0]
	var kart := match_node.kart_of(0)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(4, 17)
	assert_int(_spun.size()).is_equal(0)
	assert_float(pad._away).is_greater(0.0)
	assert_that(pad._rim.albedo_color).is_not_equal(Palette.CHIP_GOLD)
	assert_bool(pad._dial.visible).is_false()
	kart.global_position = Vector3.ZERO
	await _runner.simulate_frames(60, 17)
	assert_that(pad._rim.albedo_color).is_equal(Palette.CHIP_GOLD)
	kart.pot.add_coins(40)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(110, 17)
	assert_int(_paid.size()).is_equal(1)
	assert_bool(pad._dial.visible).is_false()
	kart.global_position = Vector3.ZERO
	await _runner.simulate_frames(4, 17)
	kart.global_position = pad.global_position
	await _runner.simulate_frames(4, 17)
	assert_int(_spun.size()).is_equal(1)
	assert_int(pad._waiting).is_equal(0)
	assert_bool(pad._dial.visible).is_true()
