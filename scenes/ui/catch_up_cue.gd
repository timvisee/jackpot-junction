class_name CatchUpCue
extends Control
## Shows a CATCH-UP badge while the local player is earning the catch-up bonus of GAME.md 3.16, so
## the boost reads as a reward they have earned for falling behind, not a number working against
## them. It watches the human playing on this machine and shows the live multiplier off their kart's
## [member Kart.coin_bonus], which the match keeps up to date from the standings, see [CatchUp]. Its
## own overlay rather than a line in [MatchHud], which is full.

## The gold the badge is drawn in, and the least bonus it shows at, so a hair behind does not blink.
const INK := Color(1.0, 0.82, 0.3)
const FLOOR := 1.05

var match_node: Match

var _label: Label


## Hangs the cue over [param parent], watching [param watching].
static func add_to(parent: Node, watching: Match) -> CatchUpCue:
	var cue := CatchUpCue.new()
	cue.name = "CatchUpCue"
	cue.match_node = watching
	parent.add_child(cue)
	return cue


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.position = Vector2(0.0, 74.0)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", INK)
	HudText.shadowed(_label, 2)
	add_child(_label)
	_label.visible = false


func _process(_delta: float) -> void:
	var kart := _local_kart()
	var bonus := kart.coin_bonus if kart != null else 1.0
	_label.visible = bonus >= FLOOR
	if _label.visible:
		_label.text = "CATCH-UP ×%.1f" % bonus


## The human playing on this machine, whose bonus the cue shows; null with none.
func _local_kart() -> Kart:
	if match_node == null:
		return null
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human() and slot.kart != null and is_instance_valid(slot.kart):
			return slot.kart
	return null
