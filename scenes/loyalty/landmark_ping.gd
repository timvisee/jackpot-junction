class_name LandmarkPing
extends Control
## Where Next new has taken the kart on the loyalty map, drawn the eye to, GAME.md 8.9, as every
## dialog draws it, see [LandingCue]: once the kart is there, the landmark's sign comes up a little
## bigger and settles back, and two rings of foil cased in ink ripple out from it and fade. Over the
## map and its size, taking no clicks; gone once its rings are, or as soon as the kart is sent
## somewhere else, the next press landing on the next landmark instead.

var view: LoyaltyMapView
var id: StringName
## Seconds since the kart came to the landmark, below nothing while it is still on its way.
var since := -1.0


## The landing on [param at] over [param on], once the kart is there; the one it had before gone.
static func over(on: LoyaltyMapView, at: StringName) -> LandmarkPing:
	var before := on.get_node_or_null("Ping") as LandmarkPing
	if before != null:
		before.end()
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
		end()
		return
	if since < 0.0:
		if cursor.is_driving():
			return
		since = 0.0
	since += delta
	if since > LandingCue.LASTS:
		end()
		return
	view.sign_pop = LandingCue.pop_at(since, LandingCue.POP)
	view.queue_redraw()
	queue_redraw()


func _draw() -> void:
	if since >= 0.0:
		LandingCue.draw_rings(self, view.sign_rect(id), since, view.zoom)


## Over at once: the sign as big as ever, and the landing gone.
func end() -> void:
	set_process(false)
	view.sign_pop = 1.0
	view.queue_redraw()
	name = "PingGone"
	queue_free()
