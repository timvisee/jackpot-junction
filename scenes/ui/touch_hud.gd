class_name TouchHud
extends RefCounted
## Where the HUD stands round the touch controls on a touch screen, GAME.md 4.2: the hand of jokers
## in the lane between the stick and the buttons, the kill feed over the buttons, and the pieces
## that are only read drawn smaller. Worked out from [TouchControls] every frame, since the layout
## and the UI scale may change under a match. And what of the controls themselves the camera keeps
## the karts out from under, see [method covers].

## How far in from the stick and the buttons the hand of jokers keeps, and the least room over the
## top of the hand the respawn pick keeps, GAME.md 4.2.
const LANE_GAP := 16.0
const FLOOR_GAP := 10.0
## How much smaller than the rest of the UI the pieces of the HUD that are only read are drawn on a
## touch screen, GAME.md 4.2: the player's corner, the standings and the kill feed. A phone is
## drawn big so that its buttons can be pressed; what is only looked at does not need the size,
## and on a phone's short screen it was the arena it took the room from.
const COMPACT := 0.75
## How much of each touch control the camera keeps the karts out from under, GAME.md 4.2 and 8.2,
## as a share of its drawn size across and down, about its middle. The controls are see-through,
## so a kart partly under the edge of one is still seen: only the middle of each is taken as
## covering the room. Seven tenths of a round button's square is about the square inside its ring.
const COVERED := 0.7


## Where the highest of [param controls]' driving buttons and the slider reaches up to.
static func buttons_top(controls: TouchControls) -> float:
	var top := controls.slider.rect.position.y if controls.uses_slider() else controls.size.y
	for id: StringName in controls.driving_buttons():
		var each := controls.pad(id)
		top = minf(top, each.center.y - each.radius * TouchControls.REACH)
	return top


## The stretch of the bottom of the screen between the stick's ring and the nearest button.
static func hand_lane(controls: TouchControls) -> Vector2:
	var right := controls.slider.rect.position.x if controls.uses_slider() else controls.size.x
	for id: StringName in controls.driving_buttons():
		var each := controls.pad(id)
		right = minf(right, each.center.x - each.radius * TouchControls.REACH)
	return Vector2(TouchStick.HOME.x + TouchStick.RADIUS + LANE_GAP, right - LANE_GAP)


## Where [param controls] cover the room, on the screen, for [HudCovers] to tell the camera: the
## stick's ring, the slider and each round driving button, as they are drawn just now, each
## [constant COVERED] of its size about its middle. Only what is drawn: nothing while there is no
## kart here to drive and the driving controls are not up, and never the menu button, which is
## smaller in its corner than a kart.
static func covers(controls: TouchControls) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if not TouchInput.enabled or not controls.is_visible_in_tree() or not controls.driving():
		return rects
	var to_screen := controls.get_global_transform()
	rects.append(to_screen * _middle(_ring(controls.stick.center, TouchStick.RADIUS)))
	for id: StringName in controls.driving_buttons():
		var each := controls.pad(id)
		rects.append(to_screen * _middle(_ring(each.center, each.radius)))
	if controls.uses_slider():
		rects.append(to_screen * _middle(controls.slider.rect))
	return rects


## The square a ring of [param radius] round [param center] is drawn in.
static func _ring(center: Vector2, radius: float) -> Rect2:
	return Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)


## [constant COVERED] of [param rect] about its middle.
static func _middle(rect: Rect2) -> Rect2:
	var kept := rect.size * COVERED
	return Rect2(rect.get_center() - kept * 0.5, kept)


## [param slot]'s corner, the standings and the kill feed of [param hud], drawn
## [constant COMPACT] of their size, each shrunk toward the corner or the edge it hangs from.
static func compact(hud: MatchHud, slot: PlayerSlot) -> void:
	if hud == null:
		return
	var pieces: Array[Control] = [hud.scoreboard(), hud.kill_feed()]
	if slot != null:
		pieces.append(hud.block_of(slot.index))
	for piece: Control in pieces:
		if piece == null:
			continue
		piece.pivot_offset = Vector2(
			piece.size.x * piece.anchor_left, piece.size.y * piece.anchor_top
		)
		piece.scale = Vector2.ONE * COMPACT
