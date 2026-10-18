class_name LandingCue
extends Control
## Where Next new has taken the cursor, drawn the eye to, GAME.md 8.8, the same in every dialog that
## has it, the cursor having come from anywhere: what it lands on comes up a little bigger over what
## is round it and settles back, and two rings of the House's foil, cased in ink, ripple out from it
## in its own shape and fade, as a stone's do in water. On a card of the catalog or a row of the
## achievements it is a node of its own on the thing, see [method on]; on the loyalty map, whose
## landmarks are drawn rather than nodes, [LandmarkPing] draws it with what is here, once the kart
## is there. One at a time: the next landing ends the last at once.

## How much bigger a card comes up, and a row, as wide as the case, which would run off it at that.
const POP := 1.16
const GENTLE := 1.03
## How long it takes to come up, and to settle back.
const GROWS := 0.12
const SETTLES := 0.45
## How many rings go out, how long after one another, and how long each takes to go and fade.
const RINGS := 2
const APART := 0.22
const GOES := 0.75
## How far out a ring goes, how thick it is, how much thicker the ink casing under it is, which
## keeps it seen on paper and felt alike, and how round its corners are as it starts.
const REACH := 50.0
const WIDTH := 4.0
const CASED := 3.0
const ROUND := 10.0
const CASING := Color(HouseTheme.INK, 0.85)
## How long the whole of it takes, the last ring gone.
const LASTS := GOES + APART * (RINGS - 1)

## The landing under way, for the next to end.
static var _current: LandingCue
## The rings' ink and their casing, drawn one ring after another.
static var _ink: StyleBoxFlat
static var _casing: StyleBoxFlat

## What it landed on, how much bigger that comes up, and where the rings go out from in its space.
var target: Control
var most := POP
var frame := Rect2()
## Seconds since it landed.
var since := 0.0

var _z := 0
var _pivot := Vector2.ZERO


## The landing on [param at], come up to [param grows] and its rings going out from [param from],
## the whole of it where that is nothing; the one under way before it ended.
static func on(at: Control, grows := POP, from := Rect2()) -> LandingCue:
	if _current != null and is_instance_valid(_current):
		_current.end()
	var cue := LandingCue.new()
	cue.name = "Landing"
	cue.target = at
	cue.most = grows
	cue.frame = from if from.has_area() else Rect2(Vector2.ZERO, at.size)
	cue._z = at.z_index
	cue._pivot = at.pivot_offset
	at.pivot_offset = at.size * 0.5
	# Over what is round it, as it comes up over it.
	at.z_index = cue._z + 1
	at.add_child(cue)
	_current = cue
	return cue


## How big a thing that landed is [param time] seconds after, coming up to [param grows] with a
## little give past it and settling back.
static func pop_at(time: float, grows: float) -> float:
	if time < GROWS:
		var up: float = Tween.interpolate_value(
			1.0, grows - 1.0, time, GROWS, Tween.TRANS_BACK, Tween.EASE_OUT
		)
		return up
	var settled := clampf((time - GROWS) / SETTLES, 0.0, 1.0)
	return lerpf(grows, 1.0, (1.0 - cos(settled * PI)) * 0.5)


## The rings going out from [param from] on [param on], [param time] seconds after the landing, at
## [param zoom] of their size, as the loyalty map draws them at its own.
static func draw_rings(on: CanvasItem, from: Rect2, time: float, zoom := 1.0) -> void:
	if _ink == null:
		_ink = _ring()
		_casing = _ring()
	for ring: int in RINGS:
		var gone := (time - APART * float(ring)) / GOES
		if gone <= 0.0 or gone >= 1.0:
			continue
		# Quick out and slowing as it fades, as a ripple goes.
		var out := REACH * zoom * (1.0 - pow(1.0 - gone, 3.0))
		var shape := from.grow(out)
		var corner := roundi(ROUND * zoom + out)
		_dress(_casing, CASING, 1.0 - gone, WIDTH + CASED, corner)
		on.draw_style_box(_casing, shape.grow(CASED * 0.5))
		_dress(_ink, HouseTheme.FOIL, 1.0 - gone, WIDTH, corner)
		on.draw_style_box(_ink, shape)


## Over at once: what it landed on as it was, and the landing gone.
func end() -> void:
	set_process(false)
	if is_instance_valid(target):
		target.scale = Vector2.ONE
		target.z_index = _z
		target.pivot_offset = _pivot
	if _current == self:
		_current = null
	queue_free()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	since += delta
	if since >= LASTS or not is_instance_valid(target):
		end()
		return
	target.scale = Vector2.ONE * pop_at(since, most)
	queue_redraw()


func _draw() -> void:
	draw_rings(self, frame, since)


static func _ring() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.anti_aliasing = true
	return style


static func _dress(style: StyleBoxFlat, ink: Color, alpha: float, wide: float, corner: int) -> void:
	style.border_color = Color(ink, ink.a * alpha)
	style.set_border_width_all(roundi(wide))
	style.set_corner_radius_all(corner)
