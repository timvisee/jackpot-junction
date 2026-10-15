class_name PaintCan
extends Button
## A spray can of one of the player colors on the kart dialog's bench, GAME.md 4.4: pressed, the
## kart is that color from now on. The one in use stands lifted with its cap off in the house's gold
## ring; one somebody else in the room is in has a tag on it with who, and cannot be pressed, as
## no two karts in a room are ever the same color, see [SeatIdentity]. Drawn once a run each way
## it can look and kept, see [BayArt].

const GROUP := &"paint_cans"
const AROUND := 14.0

## Which of [constant Palette.PLAYER_COLORS], whether it is the one in use, and who else has it.
var color := 0
var chosen := false
var taken_by := ""


static func make(color_of: int) -> PaintCan:
	var can := PaintCan.new()
	can.color = color_of
	can.name = "Can%s" % Palette.COLOR_NAMES[color_of]
	var slot := BayArt.can_rect(color_of)
	can.position = slot.position
	can.size = slot.size
	return can


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(FocusGlide.GROUP)
	focus_mode = Control.FOCUS_ALL
	flat = true
	for look: StringName in [
		&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
	]:
		add_theme_stylebox_override(look, StyleBoxEmpty.new())
	tooltip_text = Palette.color_name(color)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


## Says whether it is the one in use and who else in the room has it, if anybody.
func say(in_use: bool, by: String) -> void:
	if in_use == chosen and by == taken_by:
		return
	chosen = in_use
	taken_by = by
	disabled = not by.is_empty()
	queue_redraw()


func focus_frame() -> Rect2:
	return Rect2(Vector2.ZERO, size).grow(4.0)


func _draw() -> void:
	var whole := Rect2(Vector2.ZERO, size.round()).grow(AROUND)
	var ink := Palette.player_color(color)
	var in_use := chosen
	var by := taken_by
	var slot := Rect2(Vector2.ONE * AROUND, size.round())
	var art := BayArt.kept(
		self,
		"can:%s:%s:%s:%s" % [ink.to_html(), in_use, by, slot.size],
		whole.size,
		func(on: CanvasItem) -> void: BayArt.draw_can(on, slot, ink, in_use, by),
		GROUP
	)
	if art != null:
		draw_texture_rect(art, whole, false)
	else:
		BayArt.draw_can(self, Rect2(Vector2.ZERO, size), ink, chosen, taken_by)
	if is_hovered() and not disabled and not has_focus():
		BayArt.ring(self, focus_frame(), 8.0, Color(1, 1, 1, 0.35), 2.0)
	if has_focus():
		draw_style_box(FocusGlide.look(), focus_frame())
