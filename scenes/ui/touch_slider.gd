class_name TouchSlider
extends RefCounted
## The slider under the right thumb on a touch screen, GAME.md 4.2: one tall pill in the bottom
## right corner with nitro, gas, brake and drift down it, top to bottom. [TouchControls] hands it
## the finger on it; this says which zone that finger is on, what each zone says, and draws it. In
## simple driving the stick works the pedals, and it is a shorter pill of nitro over drift.

## The zones, top to bottom, and each one's share of the height: the gas, where the thumb rests,
## the biggest, and the two at the ends, which a thumb reaches for, a little over the brake. Nitro
## holds the gas too, for when the tank runs dry under it, and so does drift, so a slide keeps its
## power; brake is the brake alone, and reverses once stopped.
const NITRO := &"nitro"
const GAS := &"gas"
const BRAKE := &"brake"
const DRIFT := &"drift"
const ZONES: Array[StringName] = [NITRO, GAS, BRAKE, DRIFT]
const ZONE_SHARES: Array[float] = [1.15, 1.5, 1.0, 1.15]
const SIMPLE_ZONES: Array[StringName] = [NITRO, DRIFT]
const SIMPLE_SHARES: Array[float] = [1.0, 1.0]
const ZONE_WORDS: Dictionary[StringName, String] = {
	NITRO: "NITRO", GAS: "GAS", BRAKE: "BRAKE", DRIFT: "DRIFT"
}
## How big the slider is, how far in from the right and the bottom edges it stands, and how far off
## its sides a thumb going down still takes it.
const SIZE := Vector2(124.0, 384.0)
const SIMPLE_SIZE := Vector2(124.0, 260.0)
const INSET := Vector2(34.0, 28.0)
const SLACK := 24.0
const ZONE_LINE := Color(1.0, 1.0, 1.0, 0.22)
## Below this speed forward the brake is the reverse, and says so: a kart standing still or rolling
## back goes backwards on it, and one that is going forward stops. And the drift is grayed, there
## being nothing to slide.
const STILL_SPEED := 0.5
## The nitro tank is a bar across the bottom of the nitro, this far in from its edges.
const TANK_INSET := 16.0

## The zones down it just now, and each one's share of the height: the four, or the two of simple
## driving, see [method go_simple].
var zones: Array[StringName] = ZONES
var shares: Array[float] = ZONE_SHARES
## Where it stands on the screen.
var rect := Rect2()
## The finger on it, or -1, and where that finger is.
var finger := -1
var at := Vector2.ZERO


## Stands it in the bottom right corner of a screen [param screen] big.
func place(screen: Vector2) -> void:
	var tall := SIMPLE_SIZE if zones == SIMPLE_ZONES else SIZE
	rect = Rect2(screen - INSET - tall, tall)


## The two zones of simple driving, GAME.md 4.2, or all four when [param on] is false. Placed again
## after, since the two make a shorter pill.
func go_simple(on: bool) -> void:
	zones = SIMPLE_ZONES if on else ZONES
	shares = SIMPLE_SHARES if on else ZONE_SHARES


## Whether a finger going down at [param point] takes it: on it, or a little off either side.
func takes(point: Vector2) -> bool:
	return rect.grow_individual(SLACK, 0.0, SLACK, 0.0).has_point(point)


## The stretch of it [param zone] takes up.
func zone_rect(zone: StringName) -> Rect2:
	var total := 0.0
	for share: float in shares:
		total += share
	var top := rect.position.y
	for i: int in zones.size():
		var tall := rect.size.y * shares[i] / total
		if zones[i] == zone:
			return Rect2(rect.position.x, top, rect.size.x, tall)
		top += tall
	return Rect2()


## The zone at the height [param y]: the top one above it, the bottom one below.
func zone_at(y: float) -> StringName:
	for zone: StringName in zones:
		if y < zone_rect(zone).end.y:
			return zone
	return zones[-1]


## The zone the thumb is on, or an empty name while none is.
func slid() -> StringName:
	return zone_at(at.y) if finger >= 0 else &""


## What [param zone] says on it. The brake says reverse while that is what it does, on a kart
## standing still or rolling back, and shortens it where the whole word does not fit.
func word(zone: StringName, kart: Kart) -> String:
	return word_for(zone, kart, zone_rect(zone).size.x - TANK_INSET)


## What [param zone] says in [param room] of width, on the slider or on a button of its own.
static func word_for(zone: StringName, kart: Kart, room: float) -> String:
	if zone != BRAKE or not standing_still(kart):
		return ZONE_WORDS[zone]
	var font := Type.STRONG
	var wide := font.get_string_size(
		"REVERSE", HORIZONTAL_ALIGNMENT_LEFT, -1, TouchControls.LABEL_SIZE
	)
	return "REVERSE" if wide.x <= room else "REV"


## Whether [param kart] is standing still or rolling back, where the brake is the reverse and there
## is no drifting to be had.
static func standing_still(kart: Kart) -> bool:
	return kart != null and kart.motor.forward_speed < STILL_SPEED


## Whether there is nitro enough to burn: a burn under way, or a tank past what it takes to start
## one. Short of that the nitro is drawn grayed, and is only the gas.
static func nitro_ready(kart: Kart) -> bool:
	return kart != null and (kart.nitro_active or kart.nitro_charge >= kart.stats.nitro_min_start)


## Whether [param zone] is drawn as live: nitro while there is a burn in the tank, drift while the
## kart is moving, and the other two always. A grayed one still does what it does.
static func zone_ready(zone: StringName, kart: Kart) -> bool:
	match zone:
		NITRO:
			return nitro_ready(kart)
		DRIFT:
			return not standing_still(kart)
	return true


## The pill with its zones down it onto [param canvas], the one under the thumb lit, a line between
## each and the next, and the nitro tank across the bottom of the nitro, all at [param strength].
func draw(canvas: CanvasItem, strength: float, kart: Kart) -> void:
	var round := int(rect.size.x * 0.5)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(TouchControls.FILL, TouchControls.FILL.a * strength)
	pill.border_color = Color(TouchControls.RIM, TouchControls.RIM.a * strength)
	pill.set_border_width_all(int(TouchControls.RIM_WIDTH))
	pill.set_corner_radius_all(round)
	pill.anti_aliasing = true
	canvas.draw_style_box(pill, rect)
	var on := slid()
	var size := TouchControls.LABEL_SIZE
	for i: int in zones.size():
		var zone := zones[i]
		var area := zone_rect(zone)
		var dim := strength if zone_ready(zone, kart) else strength * TouchControls.GRAYED
		var ink := TouchControls.INK if dim >= 1.0 else TouchControls.GRAY_INK
		if zone == on:
			var lit := StyleBoxFlat.new()
			lit.bg_color = Color(TouchControls.FILL_DOWN, TouchControls.FILL_DOWN.a * strength)
			lit.anti_aliasing = true
			lit.corner_radius_top_left = round if i == 0 else 0
			lit.corner_radius_top_right = round if i == 0 else 0
			lit.corner_radius_bottom_left = round if i == zones.size() - 1 else 0
			lit.corner_radius_bottom_right = round if i == zones.size() - 1 else 0
			canvas.draw_style_box(lit, area)
		if i > 0:
			var line := Color(ZONE_LINE, ZONE_LINE.a * strength)
			canvas.draw_line(area.position, Vector2(area.end.x, area.position.y), line, 2.0)
		var said := word(zone, kart)
		var font := Type.STRONG
		var width := font.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var baseline := area.get_center() + Vector2(-width * 0.5, size * 0.36)
		canvas.draw_string(font, baseline, said, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
	if kart != null:
		var nitro := zone_rect(NITRO)
		var full := nitro.size.x - TANK_INSET * 2.0
		var bar := Vector2(nitro.position.x + TANK_INSET, nitro.end.y - TANK_INSET)
		var tank := full * clampf(kart.nitro_charge, 0.0, 1.0)
		var ink := Color(TouchControls.TANK, TouchControls.TANK.a * strength)
		canvas.draw_rect(Rect2(bar, Vector2(tank, TouchControls.TANK_WIDTH)), ink)
