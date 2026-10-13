class_name AchievementToast
extends Control
## An achievement earned, GAME.md 8.10: its chip or its pin tossed in, spinning as a tossed coin
## spins, coming to rest on a slip of the house's dark stock with ACHIEVEMENT UNLOCKED over its
## name, for three and a half seconds, and gone; a chip landing with a chip's clack and a short
## chime, a pin with the chime alone. Beside the corner of the seat that earned it in a room, after
## any BET WON there and never over it, the profile's name on it for a seat another profile sits in;
## at the screen's top right anywhere else. Or, once, how many a profile from before achievements
## was credited. Nothing pauses and nothing has to be pressed. Queued and put up by
## [AchievementToasts].

## Its size, the chip's, and the room round them.
const SIZE := Vector2(400.0, 86.0)
const CHIP := 66.0
const PAD := 10.0
## How long it slides in, how long the chip spins and how many times round, how long it stays in all
## and how long it fades for; how far off a block or the screen's edge it stands.
const SLIDE := 0.25
const SPIN := 0.75
const TURNS := 3.0
const LASTS := 3.5
const FADE := 0.3
const GAP := 12.0
const INSET := 18.0
const BETWEEN := 8.0
## What sits over the name, and over a count of them.
const UNLOCKED := "ACHIEVEMENT UNLOCKED"
const UNLOCKED_MANY := "%d achievements unlocked"
const UNLOCKED_ONE := "1 achievement unlocked"
const ALREADY := "Earned already"
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
var _landed := false


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
	add_to_group(GROUP)
	_chip = AchievementArt.picture(achievement, AchievementArt.Look.EARNED, CHIP)
	_chip.position = Vector2(PAD, (SIZE.y - CHIP) * 0.5)
	_chip.spin = TURNS * TAU
	add_child(_chip)
	Audio.play_sfx(&"bank_done", -4.0, 0.0)
	_step(0.0)


func _process(delta: float) -> void:
	_step(delta)
	if _age >= LASTS:
		queue_free()


func _step(delta: float) -> void:
	_age += delta
	var slid := ease(clampf(_age / SLIDE, 0.0, 1.0), -2.0)
	var at := _corner()
	var away := Vector2(size.x + INSET, 0.0) * (1.0 if _right else -1.0)
	position = (at + away).lerp(at, slid)
	modulate.a = clampf((LASTS - _age) / FADE, 0.0, 1.0)
	# Tossed: turning over and over as it rises and falls onto the slip, slowing to land face up.
	var tossed := clampf(_age / SPIN, 0.0, 1.0)
	var settled := 1.0 - pow(1.0 - tossed, 3.0)
	_chip.spin = (1.0 - settled) * TURNS * TAU
	_chip.position.y = (SIZE.y - CHIP) * 0.5 - sin(tossed * PI) * 18.0
	if tossed >= 1.0 and not _landed:
		_landed = true
		if count > 0 or not achievement.is_pin():
			Audio.play_sfx(&"chip", -2.0)


## Beside the block on the side toward the middle of the screen, under a BET WON there, or at the
## screen's top right with no block.
func _corner() -> Vector2:
	var screen := get_viewport_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	if _block == null or not is_instance_valid(_block):
		return Vector2(screen.x - size.x - INSET, INSET)
	var x := _block.position.x + _block.size.x + GAP
	if _right:
		x = _block.position.x - GAP - size.x
	var y := _block.position.y + _below
	if _bottom:
		y = _block.position.y + _block.size.y - size.y - _below
	return Vector2(clampf(x, 0.0, screen.x - size.x), clampf(y, 0.0, screen.y - size.y))


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
