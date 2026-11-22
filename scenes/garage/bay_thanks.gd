class_name BayThanks
extends Button
## The supporter pack's thank-you card taped up in the Garage's bay, GAME.md 10.8, as something to
## press: a flat button over where the card is filmed on the back wall, following it as the camera
## moves round the kart, which holds the card up again over the kart dialog, see
## [SupporterThanks]. The dialog's cursor reaches it too, across from the hat's hook, which it is
## level with, see [method link], outlined in the house's gold while it is there. Only where the
## card is taped up at all, see [BaySet].

const NAME := "Thank-you card"
## How far round the card its outline is drawn, under the cursor or the mouse.
const AROUND := 6.0

var dialog: KartDialog
var stage: KartStage
## The card held up again, while it is.
var held: SupporterThanks
## The hook the cursor reaches it from, and goes back to while it is hidden, see [method link].
var _from: Control


## The button over [param on]'s bay, on [param stage_node], the dialog's stage, in whose space the
## bay is filmed.
static func add_to(on: KartDialog, stage_node: Control) -> BayThanks:
	var made := BayThanks.new()
	made.name = "BayThanks"
	made.dialog = on
	made.stage = on.stage
	stage_node.add_child(made)
	made.link()
	return made


## The cursor's ways to it and from it: across from the hat's hook on the left board, which it is
## level with, on to where that way led before, up to the flag's hook and down to the trail's.
## While it is hidden the cursor passes over it, as the engine does a hidden neighbor.
func link() -> void:
	var hooks := dialog.hooks
	_from = hooks[KartDialog.LEFT_HOOKS[1]]
	var onward := _from.get_node(_from.get_focus_neighbor(SIDE_RIGHT)) as Control
	_from.set_focus_neighbor(SIDE_RIGHT, _from.get_path_to(self))
	set_focus_neighbor(SIDE_LEFT, get_path_to(_from))
	set_focus_neighbor(SIDE_RIGHT, get_path_to(onward))
	set_focus_neighbor(SIDE_TOP, get_path_to(hooks[KartDialog.LEFT_HOOKS[0]]))
	set_focus_neighbor(SIDE_BOTTOM, get_path_to(hooks[KartDialog.LEFT_HOOKS[2]]))


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	hide()
	for look: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		add_theme_stylebox_override(look, StyleBoxEmpty.new())
	ScreenReader.name(self, NAME, "")
	pressed.connect(_hold_up)
	for told: Signal in [focus_entered, focus_exited, mouse_entered, mouse_exited]:
		told.connect(queue_redraw)


## The card held up again over the dialog; put away, the cursor is back on it where it was.
func _hold_up() -> void:
	var had := has_focus()
	held = SupporterThanks.again_over(dialog)
	held.put_away.connect(
		func() -> void:
			held = null
			if had and is_visible_in_tree():
				grab_focus()
	)


## Its outline: the house's gold under the cursor, a soft white under the mouse, nothing else.
func _draw() -> void:
	if not has_focus() and not is_hovered():
		return
	var outline := StyleBoxFlat.new()
	outline.draw_center = has_focus()
	outline.bg_color = Color(HouseTheme.FOIL, 0.12)
	outline.set_border_width_all(3 if has_focus() else 2)
	outline.border_color = HouseTheme.FOIL if has_focus() else BayArt.POINTED_EDGE
	outline.set_corner_radius_all(6)
	outline.anti_aliasing = true
	draw_style_box(outline, Rect2(Vector2.ZERO, size).grow(AROUND))


## Every drawn frame, over the card wherever the camera has it, or hidden while it has none.
func _process(_delta: float) -> void:
	var card := stage.thanks_card() if stage != null else null
	if card == null or not card.is_inside_tree():
		_hide()
		return
	var half := (card.mesh as QuadMesh).size * 0.5
	var corners := PackedVector2Array()
	for at: Vector2 in [
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)
	]:
		var filmed: Variant = stage.on_film(
			card.global_transform * Vector3(at.x * half.x, at.y * half.y, 0.0)
		)
		if filmed == null:
			_hide()
			return
		corners.append(filmed)
	var box := Rect2(corners[0], Vector2.ZERO)
	for corner: Vector2 in corners:
		box = box.expand(corner)
	position = box.position
	size = box.size
	show()


## Hidden, the cursor on it moved to the hook it is reached from rather than lost.
func _hide() -> void:
	if has_focus() and _from != null:
		_from.grab_focus()
	hide()
