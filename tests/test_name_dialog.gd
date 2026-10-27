extends GdUnitTestSuite
## The name dialog, GAME.md 8.5: its die rolls a fresh name into the box, as the new-profile dialog
## uses it, see [ProfilesTab]; with no roller, there is no die, as when a profile is renamed.


func test_the_die_rolls_a_name_into_the_box() -> void:
	var host: Control = auto_free(Control.new())
	add_child(host)
	var names: Array[String] = ["Ace", "Bolt"]
	var next: Array[int] = [0]
	var roll := func() -> String:
		var name := names[next[0] % names.size()]
		next[0] += 1
		return name
	var dialog: NameDialog = auto_free(
		NameDialog.open(host, "New profile", "Start", "Make", "", roll)
	)
	assert_object(dialog.die).is_not_null()
	assert_str(dialog.field.text).is_equal("Start")
	dialog.die.pressed.emit()
	assert_str(dialog.field.text).is_equal("Ace")
	# A rolled name is a name, so the way ahead is on.
	assert_bool(dialog.ok_button.disabled).is_false()
	dialog.die.pressed.emit()
	assert_str(dialog.field.text).is_equal("Bolt")


func test_without_a_roller_there_is_no_die() -> void:
	var host: Control = auto_free(Control.new())
	add_child(host)
	var dialog: NameDialog = auto_free(NameDialog.open(host, "Rename profile", "Who", "Save"))
	assert_object(dialog.die).is_null()
