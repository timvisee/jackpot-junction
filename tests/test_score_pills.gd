extends GdUnitTestSuite
## The two halves of a pot on the HUD, GAME.md 8.3: chips in one color, mult in another, the
## multiply between them and what they come to after it.

const CHIPS := 0
const MULT := 2


func _pills() -> ScorePills:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	return ScorePills.add_to(holder, false)


## A pot is shown as its two halves and their product, and the halves keep their own colors.
func test_a_pot_is_shown_as_two_halves_and_what_they_come_to() -> void:
	var pills := _pills()
	pills.show_pot(1250, 3.0, 3750)
	assert_bool(pills.chips.text == "1250").is_true()
	assert_bool(pills.mult.text == "3").is_true()
	assert_bool(pills.total.text == "3750").is_true()
	var chip_ink := pills.chips.get_theme_color("font_color")
	var mult_ink := pills.mult.get_theme_color("font_color")
	assert_bool(chip_ink.is_equal_approx(mult_ink)).is_false()
	# Each pill is a panel in its own half's color rather than a number on the scrim.
	for at: int in [CHIPS, MULT]:
		var pill: PanelContainer = pills.get_child(at)
		var skin: StyleBoxFlat = pill.get_theme_stylebox("panel")
		assert_float(skin.bg_color.a).is_greater(0.0)


## The multiply and the equals are between them rather than written into the numbers.
func test_the_signs_are_drawn_between_the_pills() -> void:
	var pills := _pills()
	pills.show_pot(4, 2.0, 8)
	assert_bool((pills.get_child(1) as Label).text == "×").is_true()
	assert_bool((pills.get_child(3) as Label).text == "=").is_true()
	# And they are wide enough to be seen: a clipped label with nothing asking for room is a
	# label nought pixels wide, which is how the first pair of these went missing.
	assert_float((pills.get_child(1) as Label).get_minimum_size().x).is_greater(1.0)


## A mult is written whole when it is whole and to one decimal when it is not.
func test_a_mult_reads_the_way_it_is_written() -> void:
	assert_bool(ScorePills.mult_text(2.0) == "2").is_true()
	assert_bool(ScorePills.mult_text(2.5) == "2.5").is_true()
	assert_bool(ScorePills.mult_text(4.0) == "4").is_true()


## A dead player has no pot, so the line says what it is waiting for instead, and gets the pot
## back when they do.
func test_the_line_can_say_something_else_instead() -> void:
	var pills := _pills()
	pills.show_pot(10, 2.0, 20)
	pills.say("respawning 1.4")
	assert_bool(pills.chips.get_parent().visible).is_false()
	assert_bool(pills.total.visible).is_false()
	# And the words have room: clipped, with the pot hidden, they were nought pixels wide, and
	# nobody waiting to come back was ever shown how long for.
	assert_bool(pills._note.visible).is_true()
	assert_float(pills._note.get_minimum_size().x).is_greater(40.0)
	pills.show_pot(10, 2.0, 20)
	assert_bool(pills.chips.get_parent().visible).is_true()
	assert_bool(pills.total.visible).is_true()


## A pill grows to fit the number in it, GAME.md 8.3. Clipped at a fixed width, a mult of 24.5
## lost its last digit -- the one that says how much the pot is actually worth -- and a chip count
## in five figures lost its leading one.
func test_a_pill_grows_when_its_number_outgrows_it() -> void:
	var pills := _pills()
	pills.show_pot(4, 2.0, 8)
	await await_idle_frame()
	var small := (pills.mult.get_parent() as Control).get_combined_minimum_size().x
	pills.show_pot(4, 312.5, 1250)
	await await_idle_frame()
	var grown := (pills.mult.get_parent() as Control).get_combined_minimum_size().x
	assert_float(grown).is_greater(small)
	# Wide enough for the whole of it: the number asks for its own width rather than being cut.
	assert_float(pills.mult.get_minimum_size().x).is_greater_equal(
		(
			pills
			. mult
			. get_theme_font("font")
			. get_string_size(
				"312.5", HORIZONTAL_ALIGNMENT_LEFT, -1.0, pills.mult.get_theme_font_size("font_size")
			)
			. x
		)
	)
	# And it never goes under the width it was drawn at.
	pills.show_pot(4, 2.0, 8)
	await await_idle_frame()
	assert_float(pills.mult.get_combined_minimum_size().x).is_greater_equal(ScorePills.MULT_WIDTH)
