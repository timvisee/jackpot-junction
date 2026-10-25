class_name CannonJamCue
extends Control
## Flashes JAMMED while the local player's cannon is locked by a scrambler, GAME.md 5.3, so a player
## whose fire is cut off knows why. It watches the human playing on this machine and shows the word,
## pulsing, only while [member Kart.cannon_locked_left] is above zero -- which only the scrambler
## sets, so it never fires for the plain limit on bullets in the air. Its own overlay rather than a
## line in [MatchHud], which is full.

## The warning orange the word is drawn in, and how fast it pulses in and out.
const INK := Color(1.0, 0.55, 0.2)
const PULSE := 11.0

var match_node: Match

var _label: Label
var _age := 0.0


## Hangs the cue over [param parent], watching [param watching].
static func add_to(parent: Node, watching: Match) -> CannonJamCue:
	var cue := CannonJamCue.new()
	cue.name = "CannonJamCue"
	cue.match_node = watching
	parent.add_child(cue)
	return cue


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.text = "JAMMED"
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_label.position = Vector2(0.0, 96.0)
	_label.add_theme_font_size_override("font_size", 40)
	_label.add_theme_color_override("font_color", INK)
	HudText.shadowed(_label, 2)
	add_child(_label)
	_label.visible = false


func _process(delta: float) -> void:
	_age += delta
	var kart := _local_kart()
	var locked := kart != null and kart.cannon_locked_left > 0.0
	_label.visible = locked
	if locked:
		_label.modulate.a = 0.55 + 0.45 * sin(_age * PULSE)


## The human playing on this machine, whose jam the cue shows; null with none.
func _local_kart() -> Kart:
	if match_node == null:
		return null
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null and is_instance_valid(slot.kart):
			return slot.kart
	return null
