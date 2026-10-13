class_name AchievementToast
extends Control
## An achievement earned, GAME.md 8.10: a slip of the house's dark stock sliding in from off the
## screen's edge with the achievement's chip or pin on it, tossed and spinning as a coin spins until
## it lands face up, ACHIEVEMENT UNLOCKED over its name, to its own sound, see
## tools/make_achievement_sound; three and a half seconds, and it slides back out. In a room it
## comes down from the edge to beside the corner of the seat that earned it, under any BET WON
## there and never over it, as small as it has to be to fit between that corner and whatever stands
## in the middle of the screen's edge, the clock or the lobby's count, or under the corner where
## even that is too narrow; the profile's name on it for a seat another profile sits in. Anywhere
## else it comes in at the screen's top right. Or, once, how many a profile from before
## achievements was credited. Nothing pauses and nothing has to be pressed. Queued and put up by
## [AchievementToasts].

## Its size, the chip's, and the room round them.
const SIZE := Vector2(400.0, 86.0)
const CHIP := 66.0
const PAD := 10.0
## The smallest it is drawn beside a corner before it goes under the corner instead.
const SMALLEST := 0.6
## How long it slides in and out, how long the chip spins and how many times round, and how long
## it stays in all; how far off a block or the screen's edge it stands.
const SLIDE := 0.3
const SPIN := 0.75
const TURNS := 3.0
const LASTS := 3.5
const GAP := 12.0
const INSET := 18.0
const BETWEEN := 8.0
## How much of the screen's width round its middle is looked at for what stands there, and how much
## of the width a thing there may take before it is taken for something over the whole screen.
const MIDDLE := 0.25
const WIDEST := 0.6
## What sits over the name, and over a count of them.
const UNLOCKED := "ACHIEVEMENT UNLOCKED"
const UNLOCKED_MANY := "%d achievements unlocked"
const UNLOCKED_ONE := "1 achievement unlocked"
const ALREADY := "EARNED ALREADY"
## So the camera keeps the karts out from under it, see [HudCovers].
const GROUP := &"achievement_toasts"

var achievement: Achievement
## Whose it is, said only for a seat another profile sits in.
var holder := ""
## How many a profile was credited at once, for the one toast that says so; 0 for an achievement.
var count := 0

var _block: Control
var _right := false
var _bottom := false
## How far down from its corner it stands, past the BET WON slips of its corner up before it.
var _below := 0.0
var _age := 0.0
var _chip: AchievementArt.Picture


## A toast for [param earned], beside [param block] if there is one, [param named] for a seat
## another profile sits in.
static func of(earned: Achievement, named := "", block: Control = null) -> AchievementToast:
	var toast := AchievementToast.new()
	toast.achievement = earned
	toast.holder = named
	toast._place(block)
	return toast


## The toast saying [param credited] achievements were earned already, at the top right.
static func counting(credited: int, shown: Achievement) -> AchievementToast:
	var toast := of(shown)
	toast.count = credited
	return toast


func _place(block: Control) -> void:
	_block = block
	if block != null:
		_right = block.anchor_left >= 0.5
		_bottom = block.anchor_top >= 0.5
		for other: Node in block.get_parent().get_children():
			if other is LoyaltyStamp and (other as LoyaltyStamp).get(&"_block") == block:
				_below = maxf(_below, (other as LoyaltyStamp).size.y + BETWEEN)
	else:
		_right = true


func _ready() -> void:
	name = "AchievementToast"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE
	pivot_offset = Vector2.ZERO
	add_to_group(GROUP)
	_chip = AchievementArt.picture(achievement, AchievementArt.Look.EARNED, CHIP)
	_chip.position = Vector2(PAD, (SIZE.y - CHIP) * 0.5)
	_chip.spin = TURNS * TAU
	add_child(_chip)
	Audio.play_sfx(&"achievement", -3.0, 0.0)
	_step(0.0)


func _process(delta: float) -> void:
	_step(delta)
	if _age >= LASTS:
		queue_free()


func _step(delta: float) -> void:
	_age += delta
	var spot := _spot()
	scale = Vector2.ONE * spot.size.x / SIZE.x
	# In from off the edge and back out the same way at its end: down from the top or up from the
	# foot beside a corner, in from the right anywhere else.
	var shown := minf(_age / SLIDE, (LASTS - _age) / SLIDE)
	var slid := ease(clampf(shown, 0.0, 1.0), -2.0)
	position = _off(spot).lerp(spot.position, slid)
	# Tossed: turning over and over as it rises and falls onto the slip, slowing to land face up.
	var tossed := clampf(_age / SPIN, 0.0, 1.0)
	var settled := 1.0 - pow(1.0 - tossed, 3.0)
	_chip.spin = (1.0 - settled) * TURNS * TAU
	_chip.position.y = (SIZE.y - CHIP) * 0.5 - sin(tossed * PI) * 18.0


## Where it stands once in, and how big it is drawn there: beside the block on the side toward the
## middle of the screen, under a BET WON there, as small as the room to the middle asks, or under
## the block if even its smallest would not fit; or at the screen's top right with no block.
func _spot() -> Rect2:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	if _block == null or not is_instance_valid(_block):
		return Rect2(Vector2(screen.x - SIZE.x - INSET, INSET), SIZE)
	var band := Vector2(_block.position.y, _block.position.y + _block.size.y)
	var middle := _middle(screen, band)
	var from := _block.position.x + _block.size.x + GAP
	var to := (middle.x if middle.x < middle.y else screen.x * 0.5) - GAP
	if _right:
		from = (middle.y if middle.x < middle.y else screen.x * 0.5) + GAP
		to = _block.position.x - GAP
	var fit := clampf((to - from) / SIZE.x, 0.0, 1.0)
	if fit >= SMALLEST:
		var wide := SIZE * fit
		var x := to - wide.x if _right else from
		var y := _block.position.y + _below * fit
		if _bottom:
			y = _block.position.y + _block.size.y - wide.y - _below * fit
		return Rect2(_kept_in(Vector2(x, y), wide, screen), wide)
	# No room beside it: under the block, or over it for one at the foot, its own edge lined up with
	# the block's outer one.
	var under := SIZE * minf(1.0, _block.size.x / SIZE.x)
	var x := _block.position.x + _block.size.x - under.x if _right else _block.position.x
	var y := _block.position.y + _block.size.y + GAP + _below
	if _bottom:
		y = _block.position.y - GAP - under.y - _below
	return Rect2(_kept_in(Vector2(x, y), under, screen), under)


## Where it starts its slide from, and goes back to: just off the screen's edge nearest
## [param spot], the top or the foot beside a corner, the right anywhere else.
func _off(spot: Rect2) -> Vector2:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	if _block == null or not is_instance_valid(_block):
		return Vector2(screen.x + INSET, spot.position.y)
	if _bottom:
		return Vector2(spot.position.x, screen.y + INSET)
	return Vector2(spot.position.x, -spot.size.y - INSET)


## What stands in the middle of the screen in the rows [param band] spans, as the left and right
## of all of it together: the clock and what hangs beside it, the lobby's count; or an empty span,
## left past right, with nothing there.
func _middle(screen: Vector2, band: Vector2) -> Vector2:
	var reach := Vector2(INF, -INF)
	var hud := get_parent()
	if hud == null:
		return reach
	var things: Array[Node] = hud.get_children()
	var room: Variant = hud.get(&"match_node")
	if room is Node and is_instance_valid(room):
		var count := (room as Node).get_node_or_null("ReadyCount")
		if count != null:
			things.append_array(count.get_children())
	for thing: Node in things:
		var shown := thing as Control
		if shown == null or shown == self or shown == _block or not shown.is_visible_in_tree():
			continue
		if shown is AchievementToast or shown is LoyaltyStamp:
			continue
		var rect := shown.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.x > screen.x * WIDEST:
			continue
		var center := rect.get_center().x
		if absf(center - screen.x * 0.5) > screen.x * MIDDLE:
			continue
		if rect.end.y < band.x or rect.position.y > band.y:
			continue
		reach = Vector2(minf(reach.x, rect.position.x), maxf(reach.y, rect.end.x))
	return reach


static func _kept_in(at: Vector2, wide: Vector2, screen: Vector2) -> Vector2:
	return Vector2(
		clampf(at.x, 0.0, maxf(screen.x - wide.x, 0.0)),
		clampf(at.y, 0.0, maxf(screen.y - wide.y, 0.0))
	)


func _draw() -> void:
	var slip := Rect2(Vector2.ZERO, SIZE)
	draw_rect(Rect2(Vector2(3.0, 5.0), SIZE), Color(0.0, 0.0, 0.0, 0.4))
	draw_rect(slip, HouseTheme.STOCK_RAISED)
	draw_rect(slip.grow(-4.0), Color(HouseTheme.FOIL, 0.55), false, 1.0)
	var left := PAD + CHIP + 12.0
	var wide := SIZE.x - left - PAD
	var over := UNLOCKED if count == 0 else ALREADY
	draw_string(
		Type.micro_font(),
		Vector2(left, 26.0),
		over,
		HORIZONTAL_ALIGNMENT_LEFT,
		wide,
		11,
		HouseTheme.FOIL
	)
	var title := achievement.title
	if count > 0:
		title = UNLOCKED_ONE if count == 1 else UNLOCKED_MANY % count
	draw_string(
		Type.display_font(),
		Vector2(left, 56.0),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		wide,
		26,
		HouseTheme.WORDS
	)
	if not holder.is_empty():
		draw_string(
			Type.TEXT,
			Vector2(left, 75.0),
			holder,
			HORIZONTAL_ALIGNMENT_LEFT,
			wide,
			13,
			HouseTheme.QUIET
		)
