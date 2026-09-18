class_name Scoreboard
extends VBoxContainer
## The running order down the right-hand side, GAME.md 8.3. Every kart gets a row: its banked
## score, and next to it what it is still carrying around unbanked. Rows are ordered by the two
## added together, so a kart on a hot lap climbs the board before it reaches the Junction and
## drops back the moment it dies. The leader's row is the biggest and the last place the
## smallest, and the players on this screen are boxed in their own colour. A carried pot big
## enough to win the match on the next cash-out blinks, GAME.md 3.4, whoever is carrying it.

const TOP_FONT := 30
const BOTTOM_FONT := 17
const RISK_FONT := 15
const DIM := Color(0.82, 0.82, 0.86)
## Blinks a second of the carried pot that would end the match.
const WIN_BLINK := 3.2

var match_node: Match

## Slot index to its row's parts.
var _rows: Dictionary[int, Dictionary] = {}
## Where the blink is in its cycle, shared by every row so they flash together rather than
## drifting apart into a fairground.
var _beat := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	grow_vertical = Control.GROW_DIRECTION_BOTH
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -16.0
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The scoreboard's own view of the order: by banked plus unbanked, then by the tie-breaks the
## match uses. Highest first.
func order() -> Array[PlayerSlot]:
	var ranked := match_node.slots.duplicate()
	ranked.sort_custom(PlayerSlot.by_score)
	return ranked


func _process(delta: float) -> void:
	if match_node == null or match_node.slots.is_empty():
		return
	_beat += delta
	var ranked := order()
	for rank: int in ranked.size():
		var slot := ranked[rank]
		var row := _row(slot)
		move_child(row["panel"], rank)
		_update_row(row, slot, rank, ranked.size())


func _update_row(row: Dictionary, slot: PlayerSlot, rank: int, count: int) -> void:
	var share := 0.0 if count < 2 else float(rank) / float(count - 1)
	var size := roundi(lerpf(TOP_FONT, BOTTOM_FONT, share))
	var local := slot.is_local_human()
	var color := slot.color()
	var place: Label = row["place"]
	var name_label: Label = row["name"]
	var score: Label = row["score"]
	var risk: Label = row["risk"]
	place.text = "%d" % (rank + 1)
	name_label.text = slot.display_name()
	score.text = str(slot.banked)
	var unbanked := slot.kart.pot.value() if slot.kart != null else 0
	risk.text = "+%d" % unbanked if unbanked > 0 else ""
	var hunted := match_node.bounty_slot == slot.index
	(row["bounty"] as Label).visible = hunted
	for label: Label in [place, name_label, score]:
		label.add_theme_font_size_override("font_size", size)
	risk.add_theme_font_size_override("font_size", maxi(size - 8, RISK_FONT))
	place.add_theme_color_override("font_color", DIM)
	name_label.add_theme_color_override("font_color", color)
	score.add_theme_color_override("font_color", Color.WHITE if local else DIM)
	# Enough in the pot to win by banking it: the number says so itself rather than waiting for
	# the results screen to. Everyone's row blinks, so a rival about to finish it is as plain as
	# your own chance to.
	if slot.would_win(match_node.rules.target_score):
		var wave := 0.5 + 0.5 * sin(_beat * WIN_BLINK * TAU)
		risk.add_theme_color_override("font_color", Palette.CHIP_GOLD.lerp(Color.WHITE, wave))
		risk.modulate = Color(1.0, 1.0, 1.0, lerpf(0.45, 1.0, wave))
	else:
		risk.add_theme_color_override("font_color", Palette.CHIP_GOLD)
		risk.modulate = Color.WHITE
	(row["panel"] as PanelContainer).add_theme_stylebox_override(
		"panel", row["own"] if local else row["plain"]
	)
	(row["panel"] as Control).custom_minimum_size = Vector2(0.0, size + 8.0)


## Builds a row the first time its slot shows up. Rows live as long as the scoreboard; only their
## order and their contents change.
func _row(slot: PlayerSlot) -> Dictionary:
	if _rows.has(slot.index):
		return _rows[slot.index]
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(0.06, 0.06, 0.08, 0.5)
	plain.set_corner_radius_all(6)
	plain.content_margin_left = 10.0
	plain.content_margin_right = 12.0
	plain.content_margin_top = 2.0
	plain.content_margin_bottom = 2.0
	var own := plain.duplicate()
	own.bg_color = Color(0.1, 0.1, 0.13, 0.82)
	own.border_width_left = 6
	own.border_color = slot.color()
	panel.add_theme_stylebox_override("panel", plain)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(line)
	var place := _label(HORIZONTAL_ALIGNMENT_RIGHT, 26.0)
	var name_label := _label(HORIZONTAL_ALIGNMENT_LEFT, 150.0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var score := _label(HORIZONTAL_ALIGNMENT_RIGHT, 78.0)
	var risk := _label(HORIZONTAL_ALIGNMENT_RIGHT, 56.0)
	var bounty := _label(HORIZONTAL_ALIGNMENT_RIGHT, 22.0)
	bounty.text = "$"
	bounty.visible = false
	bounty.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	bounty.add_theme_font_size_override("font_size", 24)
	for label: Label in [place, name_label, score, risk, bounty]:
		line.add_child(label)
	add_child(panel)
	var row: Dictionary = {
		"panel": panel,
		"place": place,
		"name": name_label,
		"score": score,
		"risk": risk,
		"bounty": bounty,
		"plain": plain,
		"own": own
	}
	_rows[slot.index] = row
	return row


func _label(align: HorizontalAlignment, width: float) -> Label:
	var label := Label.new()
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(width, 0.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return HudText.shadowed(label, 1)
