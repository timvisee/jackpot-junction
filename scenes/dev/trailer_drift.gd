extends Node2D
## The trailer's drifting chips and cards, see [method scenes/dev/trailer_caption.gd.drift]: the
## title screen's poker chips and face-down cards, GAME.md 8.1, in the backs the loyalty program
## pays out, 8.9, a card wearing the next of them each time it comes round again, scrolling up
## across the whole frame, each turning as it goes. Where each is comes from the trailer's own clock
## alone, [member at] seconds as the shot starts and on a frame at a time, never from a shot's own
## start, so every shot that shows them has them where the one before left them and they run on
## unbroken across the cuts and through the dissolves. Faint all the while: hardly there as the
## opening rises into the match, building up slowly over it to their strongest over the run of
## features, then going under the end card, see [constant STRENGTH]; chips and cards each faded as
## one, see [CanvasGroup], so a chip's notches are not seen through its face.

const FPS := 60
const CHIPS := 10
const CARDS := 3
## How big a chip is across its radius, and a card from top to bottom, against the frame's height,
## the least and the most, so a 4K frame shows them as a 1080p one does.
const CHIP_RADIUS := Vector2(0.022, 0.042)
const CARD_TALL := Vector2(0.12, 0.18)
## How long one takes to scroll from the foot of the frame to past its top, the least and the most,
## in seconds, and how far it turns on the way, in whole turns, every other one the other way.
const CROSSING := Vector2(5.0, 9.0)
const SPIN := Vector2(0.3, 0.9)
## How strong the chips and the cards are at most, a card a little more so its back is seen.
const CHIP_ALPHA := 0.3
const CARD_ALPHA := 0.4
## How strong they are by the trailer's second, [time, share], eased from each to the next: barely
## in once the opening's camera has risen into the match, building up slowly with the room to the
## run of features, under the end card and gone before the license.
const STRENGTH: Array[Vector2] = [
	Vector2(8.0, 0.0),
	Vector2(14.0, 0.08),
	Vector2(21.0, 0.25),
	Vector2(30.0, 0.6),
	Vector2(37.5, 1.0),
	Vector2(39.0, 0.45),
	Vector2(42.5, 0.35),
	Vector2(43.4, 0.0),
]
const SEED := 7714
## The backs the cards wear, by [constant CardBack.STYLES]: the house's and those the loyalty
## program pays out, not the supporter pack's.
const BACKS: Array[int] = [0, 1, 2, 3]

## The trailer's second as the shot starts.
var at := 0.0
var _born := 0
var _items: Array[Dictionary] = []
var _backs: Dictionary[int, Texture2D] = {}
var _chips: CanvasGroup
var _cards: CanvasGroup


func _ready() -> void:
	_born = Engine.get_frames_drawn()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# Each its own lane across the frame, the lanes dealt out at random, so none bunch up.
	var lanes: Array[int] = []
	for i: int in CHIPS + CARDS:
		lanes.append(i)
	for i: int in range(lanes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept := lanes[i]
		lanes[i] = lanes[j]
		lanes[j] = kept
	for i: int in CHIPS + CARDS:
		var card := i >= CHIPS
		var reach := CARD_TALL if card else CHIP_RADIUS
		(
			_items
			. append(
				{
					"card": card,
					"x": (float(lanes[i]) + rng.randf_range(0.2, 0.8)) / float(CHIPS + CARDS),
					"phase": rng.randf(),
					"seconds": rng.randf_range(CROSSING.x, CROSSING.y),
					"spin": rng.randf_range(SPIN.x, SPIN.y) * (1.0 if i % 2 == 0 else -1.0),
					"size": rng.randf_range(reach.x, reach.y),
					"face": Palette.PLAYER_COLORS[i % Palette.PLAYER_COLORS.size()],
				}
			)
		)
	_chips = _group("Chips", _draw_chips)
	_cards = _group("Cards", _draw_cards)
	for style: int in BACKS:
		CardBack.picture(style, self, func(back: Texture2D) -> void: _backs[style] = back)


func _group(named: String, drawing: Callable) -> CanvasGroup:
	var group := CanvasGroup.new()
	group.name = named
	add_child(group)
	var drawn := Node2D.new()
	drawn.draw.connect(drawing.bind(drawn))
	group.add_child(drawn)
	return group


func _process(_delta: float) -> void:
	var strong := strength(now())
	_chips.self_modulate.a = CHIP_ALPHA * strong
	_cards.self_modulate.a = CARD_ALPHA * strong
	_chips.visible = strong > 0.0
	_cards.visible = strong > 0.0 and _backs.size() == BACKS.size()
	for group: CanvasGroup in [_chips, _cards]:
		(group.get_child(0) as Node2D).queue_redraw()


## The trailer's second this frame.
func now() -> float:
	return at + float(Engine.get_frames_drawn() - _born) / FPS


## How strong they are at the trailer's [param second], see [constant STRENGTH].
static func strength(second: float) -> float:
	if second <= STRENGTH[0].x or second >= STRENGTH[-1].x:
		return 0.0
	for i: int in range(1, STRENGTH.size()):
		if second < STRENGTH[i].x:
			var from := STRENGTH[i - 1]
			var to := STRENGTH[i]
			return lerpf(from.y, to.y, smoothstep(from.x, to.x, second))
	return 0.0


## Where an item is this frame, its turn, and its size in pixels, in a Vector4 of x, y, turn, size.
func _place(item: Dictionary, frame: Vector2) -> Vector4:
	var size := float(item["size"]) * frame.y
	var margin := size * 2.0
	var phase := fmod(_crossings(item), 1.0)
	return Vector4(
		float(item["x"]) * frame.x,
		(1.0 - phase) * (frame.y + margin * 2.0) - margin,
		phase * TAU * float(item["spin"]),
		size
	)


## How many times [param item] has crossed the frame by now, and how far into this crossing.
func _crossings(item: Dictionary) -> float:
	return float(item["phase"]) + now() / float(item["seconds"])


func _draw_chips(canvas: Node2D) -> void:
	var frame := get_viewport_rect().size
	for item: Dictionary in _items:
		if item["card"]:
			continue
		var placed := _place(item, frame)
		canvas.draw_set_transform(Vector2(placed.x, placed.y), placed.z)
		ChipArt.chip(canvas, Vector2.ZERO, placed.w, item["face"])
	canvas.draw_set_transform(Vector2.ZERO)


func _draw_cards(canvas: Node2D) -> void:
	if _backs.size() < BACKS.size():
		return
	var frame := get_viewport_rect().size
	var aspect := JokerCard.SIZE.x / JokerCard.SIZE.y
	for i: int in _items.size():
		var item := _items[i]
		if not item["card"]:
			continue
		var placed := _place(item, frame)
		var tall := placed.w
		var wide := tall * aspect
		# Each card its own back, and the next one each time it comes round.
		var back := _backs[BACKS[(i + floori(_crossings(item))) % BACKS.size()]]
		canvas.draw_set_transform(Vector2(placed.x, placed.y), placed.z)
		canvas.draw_texture_rect(back, Rect2(-wide * 0.5, -tall * 0.5, wide, tall), false)
	canvas.draw_set_transform(Vector2.ZERO)
