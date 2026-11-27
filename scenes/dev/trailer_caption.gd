extends CanvasLayer
## A caption of the store trailer, docs/STEAM.md "The trailer": a line printed in foil on a ticket
## of the House's black stock torn off its printer, GAME.md 8.1a. It is stamped down, as the House
## stamps a license PASSED: big and faint, then down hard in a tenth of a second with the least
## bounce, settling on a turn of its own, with the House's stamp heard quietly as it lands; it fades
## away at the end of its time, see scenes/dev/trailer.gd.
##
## The run of features, a table or a screen a beat, lists them as it goes: each beat stamps its
## feature big in the middle, then flies it off to its place in a list down the left side, then down
## the right, every one before it still there at its own turn, the same in every shot of the run, so
## the list grows across the cuts. Past the last a few more beats keep the list and stamp a big word
## each in the middle, see [method rack].

## Where a caption's ticket stands, its middle as shares of the frame; how much bigger it starts
## and how much more turned; how long the stamp takes, and the fade away.
const STANDS := Vector2(0.5, 0.8)
const FROM_SCALE := 1.9
const TURN_IN := -0.08
const STAMP := 0.11
const AWAY := 0.2
## How loud the stamp is heard as it lands, under the music.
const STAMP_DB := -10.0
## How big its words are, and the room round them.
const WORDS := 64
const ACROSS := 42.0
const DOWN := 16.0
## The run of features, in order, and the turn each is stamped at.
const FEATURES: Array[String] = [
	"7 tables",
	"48 jokers",
	"21 power-ups",
	"Teams",
	"Slot machines",
	"Grand Prix",
	"Showdowns",
	"Bounties",
	"Driving school",
	"Loyalty rewards",
	"Any controller",
	"Open source",
]
const FEATURE_TURNS: Array[float] = [
	-0.05, 0.035, -0.02, 0.055, -0.04, 0.025, -0.06, 0.04, -0.03, 0.05, -0.045, 0.03
]
## Where the listed ones stand, the left column and then the right, as shares of the frame, and
## how big; the big words stamped past the list's end, their turns, and where and how big.
const RACK_X := Vector2(0.15, 0.85)
const RACK_Y := Vector2(0.25, 0.86)
const RACKED := 0.62
const BIG_WORDS: Array[String] = ["And", "much", "more", "fun"]
const BIG_TURNS: Array[float] = [-0.04, 0.03, -0.025, 0.045]
## Every word the trailer prints, in each other language the game speaks, by its locale, keyed by
## the English: the captions `tools/trailer` gives the shots, the run of features and its big words,
## and the end card's, see [method said]. Written with the store page's words in that language,
## docs/steam/store_<language>.md, in the game's own terms; a word not here is printed in English.
const WORDS_IN: Dictionary[String, Dictionary] = {
	"nl":
	{
		"Drift. Shoot.": "Drift. Schiet.",
		"Knock them out.": "Schakel ze uit.",
		"Scoop the chips.": "Graai de fiches.",
		"Cash out before they cash you in.": "Verzilver voor zij jou verzilveren.",
		"Bend the rules.": "Buig de regels.",
		"4 on one screen · 8 online": "4 op één scherm · 8 online",
		"7 tables": "7 tafels",
		"Slot machines": "Gokkasten",
		"Bounties": "Premies",
		"Driving school": "Rijschool",
		"Loyalty rewards": "Loyaliteitsprogramma",
		"Any controller": "Elke controller",
		"And": "En",
		"much": "nog",
		"more": "meer",
		"fun": "plezier",
		"PLAY FREE ON STEAM": "SPEEL GRATIS OP STEAM",
		"Up to 4 on one screen  ·  8 online": "Tot 4 op één scherm  ·  8 online",
	},
	"zh_CN":
	{
		"Drift. Shoot.": "漂移。射击。",
		"Knock them out.": "把他们撞出局。",
		"Scoop the chips.": "捞走筹码。",
		"Cash out before they cash you in.": "趁还没被收割，先把筹码兑现。",
		"Bend the rules.": "改写规则。",
		"4 on one screen · 8 online": "同屏 4 人 · 联机 8 人",
		"7 tables": "7 张赌桌",
		"48 jokers": "48 张小丑牌",
		"21 power-ups": "21 种道具",
		"Teams": "组队",
		"Slot machines": "老虎机",
		"Grand Prix": "大奖赛",
		"Showdowns": "摊牌对决",
		"Bounties": "悬赏",
		"Driving school": "驾校",
		"Loyalty rewards": "会员奖励",
		"Any controller": "任意手柄",
		"Open source": "开源",
		"And": "还有",
		"much": "更多",
		"more": "精彩",
		"fun": "乐趣",
		"PLAY FREE ON STEAM": "STEAM 免费畅玩",
		"Up to 4 on one screen  ·  8 online": "同屏最多 4 人  ·  联机最多 8 人",
	},
}
const BIG := Vector2(0.5, 0.5)
const BIG_SIZE := 1.6
## How big a feature is stamped in the middle of the frame, and when it sets off for its place in
## the list after it lands there and how long it takes to get there, in seconds: in the list well
## before the next beat's cut, which has it there already.
const MIDDLE_SIZE := 1.3
const FLY_AT := 0.26
const FLY := 0.16

var _ticket: PanelContainer
var _age := 0.0
var _going := -1.0
var _turn := -0.025
var _middle := STANDS
var _scale := 1.0
var _settled := false
var _heard := false
## Where it flies off to after it is stamped, how big it is there and at what turn: the list's place
## of a feature stamped in the middle first; none when [member _fly_size] is 0.
var _fly_to := Vector2.ZERO
var _fly_size := 0.0
var _fly_turn := 0.0


## A caption saying [param words] over [param parent]'s frame at [param turn], stamped down at
## once; or with [param settled] already down, standing at [param middle] at [param size].
static func over(
	parent: Node, words: String, turn := -0.025, middle := STANDS, size := 1.0, settled := false
) -> CanvasLayer:
	var caption: CanvasLayer = load("res://scenes/dev/trailer_caption.gd").new()
	caption.name = "TrailerCaption"
	caption.layer = 90
	caption.set("_turn", turn)
	caption.set("_middle", middle)
	caption.set("_scale", size)
	caption.set("_settled", settled)
	parent.add_child(caption)
	caption.call("_build", words)
	return caption


## The run of features at its [param index]th beat over [param parent]: those before it listed
## down the sides, its own stamped big in the middle and flown off to its place in the list; past
## the list's end, the whole list and a big word stamped in the middle.
static func rack(parent: Node, index: int) -> void:
	var per := ceili(FEATURES.size() / 2.0)
	for i: int in mini(index + 1, FEATURES.size()):
		var row := i % per
		var down := lerpf(RACK_Y.x, RACK_Y.y, float(row) / maxf(per - 1, 1))
		var at := Vector2(RACK_X.x if i < per else RACK_X.y, down)
		if i < index:
			over(parent, FEATURES[i], FEATURE_TURNS[i], at, RACKED, true)
			continue
		var stamped := over(parent, FEATURES[i], FEATURE_TURNS[i], BIG, MIDDLE_SIZE)
		stamped.set("_fly_to", at)
		stamped.set("_fly_size", RACKED)
		stamped.set("_fly_turn", FEATURE_TURNS[i])
	var past := index - FEATURES.size()
	if past >= 0 and past < BIG_WORDS.size():
		over(parent, BIG_WORDS[past], BIG_TURNS[past], BIG, BIG_SIZE)


## [param english] in the language the trailer is recorded in, `tools/trailer --language=nl`:
## from [constant WORDS_IN], or as it is.
static func said(english: String) -> String:
	return WORDS_IN.get(Lang.current, {}).get(english, english)


func _build(words: String) -> void:
	_ticket = PanelContainer.new()
	var stock := TicketStyle.cut(HouseTheme.STOCK, 11.0, ACROSS, DOWN)
	stock.torn = true
	stock.frame = Color(HouseTheme.FOIL, 0.8)
	stock.shadow = 18.0
	_ticket.add_theme_stylebox_override(&"panel", stock)
	var label := Label.new()
	label.text = said(words).to_upper()
	label.add_theme_font_override(&"font", Type.mark_font())
	label.add_theme_font_size_override(&"font_size", WORDS)
	label.add_theme_color_override(&"font_color", HouseTheme.FOIL)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticket.add_child(label)
	add_child(_ticket)
	if _settled:
		_age = 1.0
	_place()


## Fades the ticket away.
func go() -> void:
	if _going < 0.0:
		_going = 0.0


func _process(delta: float) -> void:
	_age += delta
	if not _settled and not _heard and _age >= STAMP:
		_heard = true
		Audio.play_sfx(&"stamp", STAMP_DB, 0.05)
	if _going >= 0.0:
		_going += delta
	_place()


func _place() -> void:
	if _ticket == null:
		return
	var frame := Vector2(get_viewport().get_visible_rect().size)
	var size := _ticket.get_combined_minimum_size()
	var middle := _middle
	var big := _scale
	var turn := _turn
	if _fly_size > 0.0:
		# Off to its place in the list, quick away and slowing as it gets there.
		var gone := clampf((_age - FLY_AT) / FLY, 0.0, 1.0)
		gone = 1.0 - pow(1.0 - gone, 3.0)
		middle = _middle.lerp(_fly_to, gone)
		big = lerpf(_scale, _fly_size, gone)
		turn = lerpf(_turn, _fly_turn, gone)
	_ticket.size = size
	_ticket.pivot_offset = size * 0.5
	_ticket.position = frame * middle - size * 0.5
	var down := clampf(_age / STAMP, 0.0, 1.0)
	# Down hard, then the least bounce back up off the felt and settled.
	var bounce := sin(clampf((_age - STAMP) / 0.16, 0.0, 1.0) * PI) * 0.035
	_ticket.scale = Vector2.ONE * big * (lerpf(FROM_SCALE, 1.0, down * down) + bounce)
	_ticket.rotation = lerpf(turn + TURN_IN, turn, down)
	var shown := clampf(down * 1.5, 0.0, 1.0)
	if _going >= 0.0:
		shown *= 1.0 - clampf(_going / AWAY, 0.0, 1.0)
	_ticket.modulate.a = shown


## Every real input event taken before anything else hears it, see [method deafen].
class Deaf:
	extends Node

	func _input(_event: InputEvent) -> void:
		get_viewport().set_input_as_handled()


## Keeps real input out of a run of the trailer: under the hidden display a pad or a keyboard
## plugged into the machine reaches the game and walks its cursors about, and the trailer is staged
## by script alone. Last in the tree, so it hears every event first and takes it, ahead of the
## controls, while the script's own focus and presses still land, as a viewport with its input
## turned off would not let them.
static func deafen(parent: Node) -> void:
	var deaf := Deaf.new()
	deaf.name = "TrailerDeaf"
	parent.get_tree().root.add_child.call_deferred(deaf)


## The title screen's poker chips and face-down cards scrolling up over the whole of
## [param parent]'s frame, faint, [param at] seconds into the trailer as the shot starts: placed by
## the trailer's clock alone, so each shot that shows them picks them up where the one before left
## them, see scenes/dev/trailer_drift.gd, which also says how strong they are when. Drawn on
## [param layer_at]: over a posed screen, and over a match's room but under its HUD, so a hand of
## jokers or the standings are never veiled by them.
static func drift(parent: Node, at: float, layer_at := 80) -> void:
	var layer := CanvasLayer.new()
	layer.name = "TrailerDrift"
	layer.layer = layer_at
	parent.add_child(layer)
	var drifting := Node2D.new()
	drifting.name = "Drift"
	drifting.set_script(load("res://scenes/dev/trailer_drift.gd"))
	drifting.set("at", at)
	layer.add_child(drifting)
