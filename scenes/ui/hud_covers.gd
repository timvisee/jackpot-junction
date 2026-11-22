class_name HudCovers
extends Node
## What the match HUD lays over the room, GAME.md 8.2 and 8.3, and what is done about a kart under
## it: each player's corner and the hints hung off it, the standings, the clock, the hands of
## jokers, the online lobby's list, a close look put up at the side, see [CloseLook], and whatever
## else is laid over the room, see [constant GROUP], go see-through while a kart is under them, so
## the kart shows through; the respawn pick of a player who shares the screen, and on a touch screen
## the middles of the controls under the thumbs, see [method TouchHud.covers], are told to the
## camera instead, which keeps the karts out from under them, see [ClearView]. What is drawn, and
## only that: a hand's or a pick's own rectangle is the whole screen, and only its cards, its pane
## and its words are over anything; a line of words is as wide as its words, not as the row it is
## set in.
##
## The camera used to keep the karts out from under all of it, going back and sliding its aim
## across ten times a second as the karts drove up to a panel and away again, and that was most of
## what moved the screen that nobody had asked to move. A panel that a kart shows through costs the
## picture nothing. A pick being chosen from and a thumb on the glass cannot be seen through, so
## those two the camera still keeps clear of.

## What else is laid over the room by whoever puts it up, the driving test's clipboard: a control in
## this group, while it is on show, goes see-through over a kart as the HUD's own panels do.
const GROUP := &"hud_covers"
## How close two drawn things come before they are taken as one, in the HUD's units: the cards of a
## hand overlap, and are a hand.
const TOUCHING := 4.0
## How often what the HUD covers is gathered again, and the karts looked for under it, in seconds,
## GAME.md 10.7: its panels come and go far slower than frames do.
const EVERY := 0.1
## The least a drawn thing measures, across or down, in the HUD's units, to count: a key's cap or a
## count beside the hand is smaller than a kart, and hides none of one. Fewer panels are cheaper to
## keep the karts clear of, see [ClearView].
const SPECK := 48.0
## How much of a panel is left while a kart is under it, how long it takes to go that far and to
## come back, in seconds, and how long no kart has to have been under it before it comes back: a
## kart driving along under the edge of one does not make it blink.
const SEE_THROUGH := 0.25
const FADE_OUT := 0.12
const FADE_IN := 0.4
const CLEAR_FOR := 0.5

var hud: MatchHud
## Seconds until it is gathered again.
var _left := 0.0
## What was drawn over the room when it was last gathered, in the HUD's units, and the control that
## goes see-through for each, null for one the camera keeps clear of instead.
var _drawn: Array[Rect2] = []
var _owners: Array[Control] = []
## How much of each see-through panel shows now, and how long it is still to stay see-through for,
## in seconds, by the panel's instance id, which outlives the panel; a panel is dropped from both
## once it is all back, or gone.
var _shown: Dictionary[int, float] = {}
var _holding: Dictionary[int, float] = {}


static func add_to(to: MatchHud) -> HudCovers:
	var covers := HudCovers.new()
	covers.name = "Covers"
	covers.hud = to
	to.add_child(covers)
	# And what it covers drawn over the room, while the Debug page says to, see [ClearanceView];
	# and where the karts are when they cannot be seen, see [KartPointers], which the camera's
	# choices of whom to keep in the picture lean on.
	ClearanceView.add_to(to)
	KartPointers.add_to(to)
	return covers


func _process(delta: float) -> void:
	_fade(delta)
	_left -= delta
	if _left > 0.0:
		return
	_left = EVERY
	var rig := hud.match_node.camera_rig if hud.match_node != null else null
	if rig == null:
		return
	_gather()
	var see_through := Game.settings.see_through_hud
	rig.covers = _shares(see_through)
	if see_through:
		_look_under(rig)


## Everything the HUD has over the room now, in shares of the screen, x right and y down.
func covers() -> Array[Rect2]:
	_gather()
	return _shares(false)


## What of it the camera keeps the karts out from under, in shares of the screen, x right and y
## down: the respawn pick of a player who shares the screen and the touch controls, which nothing
## shows through.
func kept() -> Array[Rect2]:
	_gather()
	return _shares(true)


## [member _drawn] in shares of the screen; with [param kept_only], only what the camera avoids.
func _shares(kept_only: bool) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var screen := hud.get_viewport().get_visible_rect().size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return rects
	for i: int in _drawn.size():
		if kept_only and _owners[i] != null:
			continue
		rects.append(Rect2(_drawn[i].position / screen, _drawn[i].size / screen))
	return rects


## Works out [member _drawn] and [member _owners] afresh.
func _gather() -> void:
	_drawn.clear()
	_owners.clear()
	if hud.dismissed or not hud.visible:
		return
	for slot: PlayerSlot in hud.match_node.slots:
		var parts := hud.block_parts(slot.index)
		for part: String in ["box", "hints"]:
			_add(parts.get(part))
		# A hand's cards overlap, and are one thing over the room; so are a pick's. The two are
		# kept apart, or the room between them would be taken as covered too. A pick with nobody
		# else on this screen may cover the table, and the camera leaves it to.
		var picker := hud.picker_of(slot.index)
		var pick: Control = picker if picker != null and picker.shared() else null
		for holder: Control in [hud.hand_of(slot.index), pick]:
			if holder != null and holder.is_visible_in_tree():
				var own: Array[Rect2] = []
				for child: Node in holder.get_children():
					_add_into(own, child)
				for rect: Rect2 in merged(own):
					_add_rect(rect, null if holder == pick else holder)
	_add(hud.scoreboard())
	# And the demo for a booth's line along the foot, GAME.md 9.8.
	for named: String in ["Clock", "Lobby"]:
		_add(hud.get_node_or_null(named))
	_add(DemoLine.of(hud))
	# An achievement's toast stays a few seconds beside its corner, GAME.md 8.10.
	for toast: Node in hud.get_children():
		if toast is AchievementToast:
			_add(toast)
	# A close look at something in the room stands at the side of the screen, see [CloseLook], and
	# whatever else is laid over the room, see [constant GROUP].
	for look: Node in hud.get_tree().get_nodes_in_group(CloseLook.GROUP):
		_add(look)
	for over: Node in hud.get_tree().get_nodes_in_group(GROUP):
		_add(over)
	# The stick, the slider and the round buttons on a touch screen, GAME.md 4.2: see-through, so
	# only the middle of each, and those that touch taken together as a hand's cards are.
	var controls := hud.get_node_or_null("TouchControls") as TouchControls
	if controls != null:
		for rect: Rect2 in merged(TouchHud.covers(controls)):
			_add_rect(rect, null)


## [param thing]'s drawn rectangle, if it is a control on show, going see-through itself.
func _add(thing: Variant) -> void:
	var rect := _drawn_rect(thing)
	if rect.has_area():
		_add_rect(rect, thing as Control)


## [param rect], drawn on the screen, with the control that goes see-through for it, unless it is a
## speck, see [constant SPECK].
func _add_rect(rect: Rect2, panel: Control) -> void:
	if _big_enough(rect):
		_drawn.append(rect)
		_owners.append(panel)


## [param thing]'s drawn rectangle added to [param rects], if it is a control on show.
static func _add_into(rects: Array[Rect2], thing: Variant) -> void:
	var rect := _drawn_rect(thing)
	if rect.has_area() and _big_enough(rect):
		rects.append(rect)


## Where [param thing] is drawn on the screen, in the HUD's units: empty for anything but a control
## on show.
static func _drawn_rect(thing: Variant) -> Rect2:
	if not is_instance_valid(thing):
		return Rect2()
	var control := thing as Control
	if control == null or not control.is_visible_in_tree() or control.modulate.a < 0.05:
		return Rect2()
	var local := Rect2(Vector2.ZERO, control.size)
	var label := control as Label
	if label != null:
		if label.text.is_empty():
			return Rect2()
		local = _words_of(label)
	return control.get_global_transform() * local


## Whether [param rect] is more than a speck, see [constant SPECK].
static func _big_enough(rect: Rect2) -> bool:
	return maxf(rect.size.x, rect.size.y) >= SPECK and minf(rect.size.x, rect.size.y) > 0.0


## Every see-through panel with a kart under it, held see-through for [constant CLEAR_FOR] more.
## A kart counts as under a panel when its middle and a little air round it, as much as the camera
## keeps clear, see [constant ClearView.KART_ROOM], touch it.
func _look_under(rig: CameraRig) -> void:
	if rig.camera == null or _drawn.is_empty():
		return
	var spots: Array[Vector3] = []
	var screen := Rect2(Vector2.ZERO, hud.get_viewport().get_visible_rect().size)
	for target: Node3D in CameraRig._valid(rig.targets):
		var middle := target.global_position + Vector3.UP * CameraRig.KART_MIDDLE
		if rig.camera.is_position_behind(middle):
			continue
		var at := rig.camera.unproject_position(middle)
		# A kart off the screen is under nothing on it, however near the edge a panel is.
		if not screen.has_point(at):
			continue
		var side := rig.camera.global_basis.x * ClearView.KART_ROOM
		var reach := at.distance_to(rig.camera.unproject_position(middle + side))
		spots.append(Vector3(at.x, at.y, reach))
	for i: int in _drawn.size():
		var panel := _owners[i]
		if panel == null:
			continue
		for spot: Vector3 in spots:
			var at := Vector2(spot.x, spot.y)
			if at.clamp(_drawn[i].position, _drawn[i].end).distance_to(at) < spot.z:
				var id := panel.get_instance_id()
				_holding[id] = CLEAR_FOR
				if not _shown.has(id):
					_shown[id] = 1.0
				break


## Every see-through panel [param delta] seconds further toward what it should show, see
## [constant SEE_THROUGH]: down quickly, back slowly once nothing has been under it for a moment.
func _fade(delta: float) -> void:
	if _shown.is_empty():
		return
	for id: int in _shown.keys():
		var panel := instance_from_id(id) as Control
		if panel == null:
			_shown.erase(id)
			_holding.erase(id)
			continue
		var left: float = _holding.get(id, 0.0) - delta
		_holding[id] = left
		var shown := _shown[id]
		if left > 0.0:
			shown = maxf(shown - delta * (1.0 - SEE_THROUGH) / FADE_OUT, SEE_THROUGH)
		else:
			shown = minf(shown + delta * (1.0 - SEE_THROUGH) / FADE_IN, 1.0)
		_show(panel, shown)
		if shown >= 1.0 and left <= 0.0:
			_shown.erase(id)
			_holding.erase(id)
		else:
			_shown[id] = shown


## Shows [param panel] at [param share] of itself. A panel that sets its own see-through, as the
## standings do when a joker blinds them, takes it as a share of that.
static func _show(panel: Control, share: float) -> void:
	if panel.has_method(&"see_through"):
		panel.call(&"see_through", share)
	else:
		panel.modulate.a = share


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
