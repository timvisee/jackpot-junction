class_name LandmarkPing
extends Control
## The eye drawn to the landmark Next new has taken the kart to, GAME.md 8.9: once the kart is
## there, rings of the House's foil go out from its sign one after the other and fade, as a sonar's
## ping does, so the cursor is found at once wherever on the map it has gone. Over the map and its
## size, taking no clicks; gone once its rings are, or as soon as the kart is sent somewhere else,
## the next press pinging the next landmark instead.

## How many rings go out, how long after one another, and how long each takes to go and fade.
const RINGS := 2
const APART := 0.22
const GOES := 0.75
## How far past the sign's corners a ring goes, in the map's own pixels, how thick it is, and how
## much thicker the dark casing under it, which keeps the foil seen on the paper as on a road.
const REACH := 50.0
const WIDTH := 4.0
const CASED := 3.0

var view: LoyaltyMapView
var id: StringName
## Seconds since the kart came to the landmark, below nothing while it is still on its way.
var since := -1.0


## The ping of [param at] over [param on], once the kart is there; the one it had before gone.
static func over(on: LoyaltyMapView, at: StringName) -> LandmarkPing:
	var before := on.get_node_or_null("Ping")
	if before != null:
		before.name = "PingGone"
		before.queue_free()
	var ping := LandmarkPing.new()
	ping.name = "Ping"
	ping.view = on
	ping.id = at
	on.add_child(ping)
	return ping


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	var cursor := view.cursor
	if cursor == null or cursor.at != id or not view.is_on_sheet(id):
		queue_free()
		return
	if since < 0.0:
		if cursor.is_driving():
			return
		since = 0.0
	since += delta
	if since > GOES + APART * float(RINGS - 1):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if since < 0.0:
		return
	var sign := view.sign_rect(id)
	var from := sign.size.length() * 0.5
	for ring: int in RINGS:
		var gone := (since - APART * float(ring)) / GOES
		if gone <= 0.0 or gone >= 1.0:
			continue
		# Quick out of the sign and slowing as it fades, as a ripple goes.
		var out := 1.0 - pow(1.0 - gone, 3.0)
		var radius := from + REACH * view.zoom * out
		var casing := LoyaltyArt.SELECTED_CASING
		casing.a *= 1.0 - gone
		draw_arc(sign.get_center(), radius, 0.0, TAU, 64, casing, WIDTH + CASED, true)
		var ink := HouseTheme.FOIL
		ink.a = 1.0 - gone
		draw_arc(sign.get_center(), radius, 0.0, TAU, 64, ink, WIDTH, true)
