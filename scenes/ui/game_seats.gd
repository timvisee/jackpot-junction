class_name GameSeats
extends Control
## A Steam game's seats and ping at the end of its row, GAME.md 10.8: a chip in their color for
## each player, a gray chip for each bot and a ring for each free seat, so bots making way for
## people is seen at a glance; then the ping as four bars and its number, one red bar past
## [constant SLOW]. Drawn, not read: the row's button says the same in words for a screen reader.

## How big a chip is, the room between two, and how many fit at most.
const CHIP := 14.0
const CHIP_GAP := 4.0
const MOST := 8
## A bar of the ping, the room between two, the shortest and the tallest.
const BAR := 4.0
const BAR_GAP := 2.0
const BAR_LOW := 5.0
const BAR_HIGH := 16.0
## From how slow a ping is one red bar, in milliseconds, GAME.md 10.8, and how fast each bar more.
const SLOW := 200
const BARS_AT: Array[int] = [200, 110, 60]
## The inks: a bot's chip and its rim, a free seat's ring, a lit bar, a slow one, an unlit one, and
## the number.
const BOT := Color(0.29, 0.28, 0.33)
const BOT_RIM := Color(0.47, 0.45, 0.5)
const FREE := Color(0.33, 0.32, 0.37)
const LIT := Color(0.62, 0.83, 0.42)
const SLOW_INK := Color(0.88, 0.34, 0.29)
const UNLIT := Color(0.23, 0.22, 0.26)
const NUMBER_INK := Color(0.66, 0.65, 0.71)
## The room the number takes, and the whole width.
const NUMBER_ROOM := 56.0
const WIDTH := MOST * (CHIP + CHIP_GAP) + 12.0 + 4 * (BAR + BAR_GAP) + NUMBER_ROOM

## The people's colors, by number; how many bots; how many seats in all; the ping, or
## [constant SteamPublic.NO_PING].
var colors: Array[int] = []
var bots := 0
var seats := 0
var ping := SteamPublic.NO_PING


## The seats and ping of [param game], as [GameList] has it.
static func of(game: Dictionary) -> GameSeats:
	var made := GameSeats.new()
	made.name = "Seats"
	made.colors.assign(game.get("colors", []))
	made.bots = int(game.get("bots", 0))
	made.seats = maxi(int(game.get("most", 0)), made.colors.size() + made.bots)
	made.ping = int(game.get("ping", SteamPublic.NO_PING))
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	made.custom_minimum_size = Vector2(WIDTH, BAR_HIGH)
	return made


## How many bars [param ms] lights, 1 to 4, or 0 for no ping at all.
static func bars_for(ms: int) -> int:
	if ms < 0:
		return 0
	var lit := 4
	for at: int in BARS_AT:
		if ms >= at:
			lit -= 1
	return maxi(lit, 1)


func _draw() -> void:
	var middle := size.y / 2.0
	var x := CHIP / 2.0
	var shown := mini(seats, MOST)
	for index: int in shown:
		var center := Vector2(x, middle)
		if index < colors.size():
			var ink := Palette.player_color(colors[index])
			draw_circle(center, CHIP / 2.0, ink)
			draw_arc(center, CHIP / 2.0 - 2.0, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.55), 1.5)
		elif index < colors.size() + bots:
			draw_circle(center, CHIP / 2.0, BOT)
			draw_arc(center, CHIP / 2.0 - 1.0, 0.0, TAU, 20, BOT_RIM, 1.5)
		else:
			draw_arc(center, CHIP / 2.0 - 1.0, 0.0, TAU, 20, FREE, 1.5)
		x += CHIP + CHIP_GAP
	x = MOST * (CHIP + CHIP_GAP) + 12.0
	var lit := bars_for(ping)
	var ink := SLOW_INK if ping >= SLOW else LIT
	for bar: int in 4:
		var tall := lerpf(BAR_LOW, BAR_HIGH, bar / 3.0)
		var rect := Rect2(x, middle + BAR_HIGH / 2.0 - tall, BAR, tall)
		draw_rect(rect, ink if bar < lit else UNLIT)
		x += BAR + BAR_GAP
	if ping < 0:
		return
	var font := Type.TEXT
	var at := Vector2(x + 6.0, middle + Type.SMALL * 0.35)
	draw_string(font, at, "%d ms" % ping, HORIZONTAL_ALIGNMENT_LEFT, -1, Type.SMALL, NUMBER_INK)
