extends GdUnitTestSuite
## The scoring maths reproduces the tables in GAME.md 3.4, 3.5 and 3.6, and the pot drains the
## way 3.4 describes.

const R0 := 40.0
const D := 0.5


func test_time_to_bank_matches_the_table_in_the_design() -> void:
	var table: Dictionary[int, float] = {
		50: 0.73, 100: 1.08, 250: 1.64, 500: 2.10, 1000: 2.58, 2500: 3.23, 5000: 3.72
	}
	for value: int in table:
		assert_float(Scoring.time_to_bank(value, R0, D)).is_equal_approx(table[value], 0.01)


func test_a_full_jackpot_collects_in_under_three_seconds() -> void:
	assert_float(Scoring.time_to_bank(60.0, 2.0, 0.5)).is_equal_approx(2.71, 0.01)


func test_banked_between_integrates_the_rate() -> void:
	var t := Scoring.time_to_bank(500.0, R0, D)
	assert_float(Scoring.banked_between(0.0, t, R0, D)).is_equal_approx(500.0, 0.01)
	var stepwise := 0.0
	var clock := 0.0
	while clock < t:
		var step := minf(1.0 / 60.0, t - clock)
		stepwise += Scoring.banked_between(clock, clock + step, R0, D)
		clock += step
	assert_float(stepwise).is_equal_approx(500.0, 0.01)
	assert_float(Scoring.bank_rate(0.0, R0, D)).is_equal_approx(R0, 0.001)
	assert_float(Scoring.bank_rate(D, R0, D)).is_equal_approx(R0 * 2.0, 0.001)


func test_death_split() -> void:
	assert_int(Scoring.pot_value(24, 3.5)).is_equal(84)
	assert_int(Scoring.death_bank(24, 3.5, 0.5)).is_equal(42)
	assert_int(Scoring.death_drop(24, 0.3, 10)).is_equal(7)
	assert_int(Scoring.death_drop(50, 0.3, 10)).is_equal(10)
	assert_int(Scoring.death_drop(2, 0.3, 10)).is_equal(0)


func test_pot_drain_keeps_mult_and_rounds_coins_up() -> void:
	var pot := Pot.new()
	pot.add_coins(20)
	pot.add_mult(2.0)
	assert_int(pot.value()).is_equal(60)
	var taken := pot.drain(25.0)
	assert_float(taken).is_equal_approx(25.0, 0.0001)
	assert_int(pot.value()).is_equal(35)
	assert_int(pot.coins).is_equal(12)
	assert_float(pot.mult).is_equal(3.0)
	taken = pot.drain(100.0)
	assert_float(taken).is_equal_approx(35.0, 0.0001)
	assert_bool(pot.is_empty()).is_true()
	assert_int(pot.value()).is_equal(0)
	pot.reset()
	assert_float(pot.mult).is_equal(1.0)


func test_pot_drain_totals_add_up_exactly_over_many_ticks() -> void:
	var pot := Pot.new()
	pot.add_coins(37)
	pot.add_mult(1.5)
	var start := pot.exact_value()
	var total := 0.0
	var t := 0.0
	while not pot.is_empty():
		total += pot.drain(Scoring.banked_between(t, t + 1.0 / 60.0, R0, D))
		t += 1.0 / 60.0
	assert_float(total).is_equal_approx(start, 0.001)
	assert_float(t).is_less(Scoring.time_to_bank(start, R0, D) + 0.02)
