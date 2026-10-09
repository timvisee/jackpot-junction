class_name LoyaltyBeacon
extends Control
## The roundabout calling over the loyalty map while an edition is owed for a lap of it, GAME.md
## 8.9: rings of the foil going out from it one after another, fading as they go. Drawn afresh every
## frame on its own, so the map under it is not.

## How long a ring takes going out, how far it goes at a zoom of one, and how many are out at once.
const TAKES := 1.6
const OUT := 90.0
const RINGS := 2

var _view: LoyaltyMapView


func _init(view: LoyaltyMapView) -> void:
	_view = view
	name = "Beacon"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func _process(_delta: float) -> void:
	visible = is_calling()
	if visible:
		queue_redraw()


## Whether the roundabout calls on the sheet shown: an edition owed for a lap of it.
func is_calling() -> bool:
	return (
		_view.layout != null
		and _view.profile != null
		and _view.sheet == LoyaltyMapLayout.Sheet.HOUSE
		and _view.profile.loyalty.owed > 0
	)


func _draw() -> void:
	var ring := _view.sign_rect(Loyalty.ROUNDABOUT)
	var middle := ring.get_center()
	var zoom := _view.zoom
	var from := ring.size.x * 0.5 + 6.0 * zoom
	for i: int in RINGS:
		var out := gone(i, RINGS)
		var ink := Color(HouseTheme.FOIL, 1.0 - out)
		var wide := (6.0 - out * 4.5) * zoom
		draw_arc(middle, from + out * OUT * zoom, 0.0, TAU, 72, ink, wide, true)


## How far out a ring is now, from 0 at the roundabout to 1 gone: the [param i]th of [param rings]
## out at once.
static func gone(i := 0, rings := 1) -> float:
	return fposmod(Time.get_ticks_msec() / 1000.0 / TAKES + float(i) / rings, 1.0)
