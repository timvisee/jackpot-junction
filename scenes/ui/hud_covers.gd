class_name HudCovers
extends Node
## What the match HUD lays over the room, GAME.md 8.2 and 8.3, told to the camera every frame so
## that it keeps the karts out from under it, see [ClearView]: each player's corner and the hints
## hung off it, the standings, the clock, the hands of jokers, the respawn pick of a player who
## shares the screen, the online lobby's list, a close look put up at the side, see
## [CloseLook], and on a touch screen the middles of the controls under the thumbs, see
## [method TouchHud.covers]. What is drawn, and only that: a hand's or a
## pick's own rectangle is the whole screen, and only its cards, its pane and its words are over
## anything; a line of words is as wide as its words, not as the row it is set in.

## How close two drawn things come before they are taken as one, in the HUD's units: the cards of a
## hand overlap, and are a hand.
const TOUCHING := 4.0
## How often what the HUD covers is gathered again, in seconds, GAME.md 10.7: its panels come and go
## far slower than frames do, and the camera eases toward them anyway.
const EVERY := 0.1
## The least a drawn thing measures, across or down, in the HUD's units, to be one the camera keeps
## the karts out from under: a key's cap or a count beside the hand is smaller than a kart, and
## hides none of one. Fewer panels are cheaper to keep the karts clear of, see [ClearView].
const SPECK := 48.0

var hud: MatchHud
## Seconds until it is gathered again.
var _left := 0.0


static func add_to(to: MatchHud) -> HudCovers:
	var covers := HudCovers.new()
	covers.name = "Covers"
	covers.hud = to
	to.add_child(covers)
	# And what it covers drawn over the room, while the Debug page says to, see [ClearanceView].
	ClearanceView.add_to(to)
	return covers


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	var rig := hud.match_node.camera_rig if hud.match_node != null else null
	if rig != null:
		rig.covers = covers()


## Everything the HUD has over the room now, in shares of the screen, x right and y down.
func covers() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if hud.dismissed or not hud.visible:
		return rects
	var drawn: Array[Rect2] = []
	for slot: PlayerSlot in hud.match_node.slots:
		var parts := hud.block_parts(slot.index)
		for part: String in ["box", "hints"]:
			_add(drawn, parts.get(part))
		# A hand's cards overlap, and are one thing over the room; so are a pick's. The two are
		# kept apart, or the room between them would be taken as covered too. A pick with nobody
		# else on this screen may cover the table, and the camera leaves it to.
		var picker := hud.picker_of(slot.index)
		var pick: Control = picker if picker != null and picker.shared() else null
		for holder: Control in [hud.hand_of(slot.index), pick]:
			if holder != null and holder.is_visible_in_tree():
				var own: Array[Rect2] = []
				for child: Node in holder.get_children():
					_add(own, child)
				drawn.append_array(merged(own))
	_add(drawn, hud.scoreboard())
	# And the demo for a booth's line along the foot, GAME.md 9.8.
	for named: String in ["Clock", "Lobby"]:
		_add(drawn, hud.get_node_or_null(named))
	_add(drawn, DemoLine.of(hud))
	# An achievement's toast stays a few seconds beside its corner, GAME.md 8.10.
	for toast: Node in hud.get_children():
		if toast is AchievementToast:
			_add(drawn, toast)
	# A close look at something in the room stands at the side of the screen, see [CloseLook].
	for look: Node in hud.get_tree().get_nodes_in_group(CloseLook.GROUP):
		_add(drawn, look)
	# The stick, the slider and the round buttons on a touch screen, GAME.md 4.2: see-through, so
	# only the middle of each, and those that touch taken together as a hand's cards are.
	var controls := hud.get_node_or_null("TouchControls") as TouchControls
	if controls != null:
		for rect: Rect2 in merged(TouchHud.covers(controls)):
			_add_rect(drawn, rect)
	var screen := hud.get_viewport().get_visible_rect().size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return rects
	for rect: Rect2 in drawn:
		rects.append(Rect2(rect.position / screen, rect.size / screen))
	return rects


## [param thing]'s drawn rectangle on the screen added to [param rects], if it is a control on show.
static func _add(rects: Array[Rect2], thing: Variant) -> void:
	if not is_instance_valid(thing):
		return
	var control := thing as Control
	if control == null or not control.is_visible_in_tree() or control.modulate.a < 0.05:
		return
	var local := Rect2(Vector2.ZERO, control.size)
	var label := control as Label
	if label != null:
		if label.text.is_empty():
			return
		local = _words_of(label)
	_add_rect(rects, control.get_global_transform() * local)


## [param rect], drawn on the screen, added to [param rects] unless it is a speck, see
## [constant SPECK].
static func _add_rect(rects: Array[Rect2], rect: Rect2) -> void:
	if maxf(rect.size.x, rect.size.y) >= SPECK and minf(rect.size.x, rect.size.y) > 0.0:
		rects.append(rect)


## Where [param label]'s words are inside it, rather than the whole row it is set in.
static func _words_of(label: Label) -> Rect2:
	var words := label.get_minimum_size().min(label.size)
	var spare := label.size - words
	var x := 0.0
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x = spare.x * 0.5
	elif label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = spare.x
	var y := 0.0
	if label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		y = spare.y * 0.5
	elif label.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
		y = spare.y
	return Rect2(Vector2(x, y), words)


## [param rects] with those that touch or overlap taken together as one.
static func merged(rects: Array[Rect2]) -> Array[Rect2]:
	var out := rects.duplicate()
	var joined := true
	while joined:
		joined = false
		for i: int in out.size():
			for j: int in range(i + 1, out.size()):
				if out[i].grow(TOUCHING).intersects(out[j]):
					out[i] = out[i].merge(out[j])
					out.remove_at(j)
					joined = true
					break
			if joined:
				break
	return out
