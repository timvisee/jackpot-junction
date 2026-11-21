class_name BayThanks
extends Button
## The supporter pack's thank-you card taped up in the Garage's bay, GAME.md 10.8, as something to
## press: a flat button over where the card is filmed on the back wall, following it as the camera
## moves round the kart, which holds the card up again over the kart dialog, see
## [SupporterThanks]. For the mouse and a finger: the card is the bay's, on its wall, and the
## dialog's cursor keeps to the dialog's own things. Only where the card is taped up at all, see
## [BaySet].

const NAME := "Thank-you card"

var dialog: KartDialog
var stage: KartStage


## The button over [param on]'s bay, on [param stage_node], the dialog's stage, in whose space the
## bay is filmed.
static func add_to(on: KartDialog, stage_node: Control) -> BayThanks:
	var made := BayThanks.new()
	made.name = "BayThanks"
	made.dialog = on
	made.stage = on.stage
	stage_node.add_child(made)
	return made


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	hide()
	for look: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		add_theme_stylebox_override(look, StyleBoxEmpty.new())
	ScreenReader.name(self, NAME, "")
	pressed.connect(func() -> void: SupporterThanks.again_over(dialog))


## Every drawn frame, over the card wherever the camera has it, or hidden while it has none.
func _process(_delta: float) -> void:
	var card := stage.thanks_card() if stage != null else null
	if card == null or not card.is_inside_tree():
		hide()
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
			hide()
			return
		corners.append(filmed)
	var box := Rect2(corners[0], Vector2.ZERO)
	for corner: Vector2 in corners:
		box = box.expand(corner)
	position = box.position
	size = box.size
	show()
