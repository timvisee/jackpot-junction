extends GdUnitTestSuite
## A card of the catalog held up large, GAME.md 8.8, see [CardZoom]: A held on a card face up, or
## the mouse held down on it, shows it large over the dialog until let go.

const PATH := "user://test_card_zoom.cfg"

var _settings_were: Settings
var _holder: Control


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = PATH
	Game.settings.load_from_disk()
	Game.settings.profile.catalog.take_joker(&"payday")
	Game.settings.profile.catalog.take_joker(&"vulture")
	_holder = Control.new()
	add_child(_holder)


func after_test() -> void:
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()
	Settings.remove_files(PATH)
	Game.settings = _settings_were


func _open() -> CatalogDialog:
	var dialog := CatalogDialog.open(_holder)
	await get_tree().process_frame
	await get_tree().process_frame
	return dialog


func _accept(down: bool) -> InputEventAction:
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = down
	return press


func _click(at: Vector2, down: bool) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = down
	click.position = at
	click.global_position = at
	return click


func _held() -> void:
	await get_tree().create_timer(CardZoom.HOLD + 0.15).timeout


## A held on a card face up brings it up large over the dialog once held a moment, and letting go
## puts it away; a press let go sooner brings nothing up.
func test_holding_a_on_a_card_holds_it_up_large() -> void:
	var dialog := await _open()
	var zoom := dialog.get_node("Zoom") as CardZoom
	dialog.cell_of(&"payday").grab_focus()
	zoom._input(_accept(true))
	await get_tree().process_frame
	zoom._input(_accept(false))
	await _held()
	assert_object(zoom.shown).is_null()
	zoom._input(_accept(true))
	await _held()
	assert_object(zoom.shown).is_not_null()
	assert_float(zoom.shown.size.y).is_greater(JokerCard.SIZE.y * 2.0)
	assert_bool(zoom.card is JokerCard).is_true()
	zoom._input(_accept(false))
	assert_object(zoom.shown).is_null()


## The cursor moved on while A is held shows the card it comes to.
func test_moving_the_cursor_while_held_shows_the_next_card() -> void:
	var dialog := await _open()
	var zoom := dialog.get_node("Zoom") as CardZoom
	var first := dialog.cell_of(&"payday")
	var second := dialog.cell_of(&"vulture")
	first.grab_focus()
	zoom._input(_accept(true))
	await _held()
	var was := zoom.shown
	second.grab_focus()
	# Emitted before the frame's processing: the next one is after it.
	await get_tree().process_frame
	await get_tree().process_frame
	assert_object(zoom._cell).is_same(second)
	assert_object(zoom.shown).is_not_same(was)
	zoom._input(_accept(false))


## A card face down has nothing to show.
func test_a_card_face_down_shows_nothing() -> void:
	var dialog := await _open()
	var zoom := dialog.get_node("Zoom") as CardZoom
	var down: CatalogCell = null
	for cell: Control in dialog.joker_grid.cells():
		if not (cell as CatalogCell).found:
			down = cell as CatalogCell
			break
	down.grab_focus()
	zoom._input(_accept(true))
	await _held()
	assert_object(zoom.shown).is_null()
	zoom._input(_accept(false))


## The mouse held down on a card brings it up, and let go puts it away; a drag that moves before it
## comes up is scrolling the cards and brings nothing up.
func test_the_mouse_held_on_a_card_holds_it_up() -> void:
	var dialog := await _open()
	var zoom := dialog.get_node("Zoom") as CardZoom
	var at := dialog.cell_of(&"payday").get_global_rect().get_center()
	zoom._input(_click(at, true))
	var drag := InputEventMouseMotion.new()
	drag.position = at + Vector2(0.0, CardZoom.DRIFT * 2.0)
	zoom._input(drag)
	await _held()
	assert_object(zoom.shown).is_null()
	zoom._input(_click(drag.position, false))
	zoom._input(_click(at, true))
	await _held()
	assert_object(zoom.shown).is_not_null()
	zoom._input(_click(at, false))
	assert_object(zoom.shown).is_null()
