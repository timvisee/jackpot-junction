extends GdUnitTestSuite
## A text box under a phone's keyboard, GAME.md 8.3: while it is typed into and the keyboard covers
## it, a bar over the keyboard shows what it is for and what is in it, caret and all; one the
## keyboard leaves clear, or no keyboard at all, shows nothing.

var _bar: KeyboardBar


func before_test() -> void:
	_bar = auto_free(KeyboardBar.add_to(self))


func after_test() -> void:
	KeyboardBar.keyboard_for_tests = -1.0


## A box in a row, named by the words beside it, at [param y] down the screen.
func _box(y: float) -> LineEdit:
	var row := MenuTheme.row("License plate", MenuTheme.field("JJ-123", "JJ", 8))
	var holder: Control = auto_free(Control.new())
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	holder.add_child(row)
	row.position = Vector2(40.0, y)
	return row.get_child(1)


func test_a_box_under_the_keyboard_is_shown_over_it() -> void:
	var screen := get_viewport().get_visible_rect().size
	var low := _box(screen.y - 80.0)
	await await_idle_frame()
	low.grab_focus()
	low.caret_column = 3
	# No keyboard, nothing covered.
	KeyboardBar.keyboard_for_tests = 0.0
	_bar._process(0.016)
	assert_bool(_bar._panel.visible).is_false()
	KeyboardBar.keyboard_for_tests = get_window().size.y * 0.4
	_bar._process(0.016)
	assert_bool(_bar._panel.visible).is_true()
	assert_str(_bar._named.text).is_equal("License plate")
	assert_str(_bar._words.text.replace("|", "").replace(" ", "")).is_equal("JJ-123")
	assert_str(KeyboardBar.shown(low, true)).is_equal("JJ-|123")
	var bottom := _bar._panel.position.y + _bar._panel.get_combined_minimum_size().y
	assert_float(bottom).is_less_equal(screen.y * 0.6)
	# A box the keyboard leaves clear is left alone, and so is one let go of.
	var high := _box(40.0)
	await await_idle_frame()
	high.grab_focus()
	_bar._process(0.016)
	assert_bool(_bar._panel.visible).is_false()
	high.release_focus()
	_bar._process(0.016)
	assert_bool(_bar._panel.visible).is_false()


func test_a_secret_is_dots() -> void:
	var secret := LineEdit.new()
	secret.secret = true
	secret.text = "hunter2"
	secret.caret_column = 7
	assert_str(KeyboardBar.shown(secret, false)).is_equal(secret.secret_character.repeat(7) + " ")
	secret.free()
