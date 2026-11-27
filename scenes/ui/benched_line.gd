class_name BenchedLine
extends Label
## What a player sees once their kart, left alone too long in a public Steam game, is a bot's,
## GAME.md 10.8: a line at the foot of the screen saying a bot drives it and a press takes it back,
## up for as long as that holds.

## How far over the foot of the screen the line stands.
const FROM_FOOT := 140.0
const WORDS := "A bot drives your kart. Press any button to drive again."


## The line, on [param room], following [param session]'s word on it; none without a session.
static func add_to(room: Node, session: NetSession) -> BenchedLine:
	if session == null:
		return null
	var line := BenchedLine.new()
	line.name = "BenchedLine"
	line.text = WORDS
	line.visible = false
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	line.offset_top = -FROM_FOOT
	line.offset_bottom = -FROM_FOOT + 40.0
	Type.strong(line, Type.BODY, HouseTheme.WORDS)
	HudText.shadowed(line)
	var layer := CanvasLayer.new()
	layer.name = "Benched"
	layer.add_child(line)
	room.add_child(layer)
	# A method of the line's own, so the session, which outlives the room, lets go of it with it.
	session.host_controls.benched_changed.connect(line._on_benched)
	line.visible = session.host_controls.benched
	return line


func _on_benched(on: bool) -> void:
	visible = on
