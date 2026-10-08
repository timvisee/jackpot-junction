class_name LoyaltyStamp
extends Control
## A bet of the loyalty program won in a room, GAME.md 8.9: a small slip the House prints, stamped
## BET WON, in the player's corner beside their block for two seconds, the way NOTE COLLECTED goes
## to the corner, see [NoteCollected], with the picture of the reward and what it says as it is
## paid by the story's stage, see [method Loyalty.reward_words]; nothing pausing. A bet won off the
## books is no business of the House's, STORY.md 6.6b: it is a tick in pencil on a scrap, no stamp
## and no words. Two at once stand one beside the other's corner side.

## The slip, and Kit's scrap.
const SIZE := Vector2(360.0, 72.0)
const SCRAP := Vector2(54.0, 46.0)
## How long it slides in, how long it stays in all, and how long it fades for; how far off the
## block it sits and how far in from the screen's edge, and the room between two.
const SLIDE := 0.22
const LASTS := 2.0
const FADE := 0.3
const GAP := 12.0
const INSET := 18.0
const BETWEEN := 8.0
const GROUP := &"loyalty_stamps"
const STAMP_TURN := -0.14

var landmark: LoyaltyLandmark
## The story's stage it is printed at.
var stage := 0

var _block: Control
var _right := false
var _bottom := false
var _age := 0.0
## How far on from its corner it stands, past the stamps of its corner up before it.
var _on := 0.0


## Puts the slip up in [param hud] for [param landmark], beside the block of the player in slot
## [param slot], or in the top left corner with no block to go beside.
static func show_beside(hud: Node, slot: int, won: LoyaltyLandmark) -> LoyaltyStamp:
	var block := hud.get_node_or_null("Block%d" % slot) as Control
	var stamp := LoyaltyStamp.new()
	stamp.name = "LoyaltyStamp"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.landmark = won
	stamp.stage = Story.stage_here()
	stamp._block = block
	if block != null:
		stamp._right = block.anchor_left >= 0.5
		stamp._bottom = block.anchor_top >= 0.5
	for other: Node in hud.get_children():
		if other is LoyaltyStamp and (other as LoyaltyStamp)._block == block:
			stamp._on += (other as LoyaltyStamp).size.x + BETWEEN
	stamp.size = stamp._size()
	stamp.add_to_group(GROUP)
	hud.add_child(stamp)
	Audio.play_sfx(&"pencil" if stamp._kit() else &"stamp", -6.0, 0.05)
	return stamp


func _kit() -> bool:
	return landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS


func _size() -> Vector2:
	return SCRAP if _kit() else SIZE


func _process(delta: float) -> void:
	_age += delta
	var slid := ease(clampf(_age / SLIDE, 0.0, 1.0), -2.0)
	var at := _corner()
	var away := Vector2(size.x + INSET, 0.0) * (1.0 if _right else -1.0)
	position = (at + away).lerp(at, slid)
	modulate.a = clampf((LASTS - _age) / FADE, 0.0, 1.0)
	if _age >= LASTS:
		queue_free()


## Beside the block on the side toward the middle of the screen, level with its inner edge, or in
## the corner with no block, a stamp already there pushing it on toward the middle.
func _corner() -> Vector2:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	var on := _on
	if _block == null or not is_instance_valid(_block):
		return Vector2(INSET + on, INSET)
	var x := _block.position.x + _block.size.x + GAP + on
	if _right:
		x = _block.position.x - GAP - size.x - on
	var y := _block.position.y + _block.size.y - size.y
	if _bottom:
		y = _block.position.y
	return Vector2(clampf(x, 0.0, screen.x - size.x), clampf(y, 0.0, screen.y - size.y))


func _draw() -> void:
	if _kit():
		_draw_tick()
		return
	var slip := Rect2(Vector2.ZERO, SIZE)
	draw_rect(Rect2(Vector2(3.0, 5.0), SIZE), Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(slip, HouseTheme.PAPER)
	draw_rect(slip.grow(-4.0), Color(HouseTheme.INK, 0.35), false, 1.0)
	var picture := Rect2(Vector2(12.0, 12.0), Vector2(48.0, 48.0))
	LoyaltyArt.draw_reward(self, picture, landmark, HouseTheme.INK)
	var left := picture.end.x + 12.0
	# Clear of the stamp over the right end.
	var wide := SIZE.x - left - 124.0
	draw_string(
		Type.STRONG,
		Vector2(left, 32.0),
		landmark.title,
		HORIZONTAL_ALIGNMENT_LEFT,
		wide,
		18,
		HouseTheme.INK
	)
	var words := Loyalty.reward_words(landmark, stage)
	draw_string(
		Type.micro_font(),
		Vector2(left, 52.0),
		words,
		HORIZONTAL_ALIGNMENT_LEFT,
		wide,
		10,
		HouseTheme.INK_FAINT
	)
	# BET WON over its right end, in the stamp's red, askew.
	var at := Vector2(SIZE.x - 66.0, SIZE.y * 0.5)
	draw_set_transform(at, STAMP_TURN, Vector2.ONE)
	var box := Rect2(Vector2(-54.0, -17.0), Vector2(108.0, 34.0))
	draw_rect(box, Color(HouseTheme.PAPER, 0.6))
	draw_rect(box, HouseTheme.STAMP_RED, false, 2.6)
	draw_rect(box.grow(-4.0), Color(HouseTheme.STAMP_RED, 0.7), false, 1.0)
	var font := Type.display_font()
	draw_string(
		font,
		Vector2(-54.0, 9.0),
		StoryLines.BET_WON,
		HORIZONTAL_ALIGNMENT_CENTER,
		108.0,
		24,
		HouseTheme.STAMP_RED
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Off the books: a scrap of paper with a tick on it in pencil, and nothing else.
func _draw_tick() -> void:
	var scrap := PackedVector2Array(
		[
			Vector2(2.0, 4.0),
			Vector2(18.0, 0.0),
			Vector2(34.0, 5.0),
			Vector2(SCRAP.x, 1.0),
			Vector2(SCRAP.x - 3.0, SCRAP.y - 2.0),
			Vector2(30.0, SCRAP.y),
			Vector2(12.0, SCRAP.y - 4.0),
			Vector2(0.0, SCRAP.y - 1.0),
		]
	)
	draw_colored_polygon(scrap, NoteCollected.PAPER)
	var tick := PackedVector2Array([Vector2(13.0, 24.0), Vector2(22.0, 34.0), Vector2(41.0, 11.0)])
	draw_polyline(tick, NoteCollected.PENCIL, 3.2, true)
	var again := PackedVector2Array()
	for point: Vector2 in tick:
		again.append(point + Vector2(0.8, 0.6))
	draw_polyline(again, Color(NoteCollected.PENCIL, 0.4), 1.6, true)
