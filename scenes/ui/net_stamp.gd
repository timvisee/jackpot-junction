class_name NetStamp
extends Control
## Where an online game is played, stamped on its room and on its menu, GAME.md 10.8: among Steam
## friends, on the network here, or at a dedicated server, so it is never in doubt which. The
## house's rubber stamp, [StampArt], PLAYED ON over the network and what it is.

## How big it is drawn, unless asked bigger, how far it is turned, and its ink, the House's gold
## stamp of the license, which reads on the dark of a room's tags and a menu's shade where the
## slip's red does not.
const RADIUS := 36.0
const TURN := -0.14
const INK := Color(0.86, 0.66, 0.24, 0.86)
## What it says over the word.
const OVER := "PLAYED ON"

## The word in the middle, and the line under it.
var word := ""
var under := ""
var radius := RADIUS


func _init(drawn_at := RADIUS) -> void:
	radius = drawn_at
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * radius * 2.3


## The word and the line under it for the game [param config] plays: STEAM among friends, SERVER
## and the server's name, or LAN.
static func words_for(config: MatchConfig) -> PackedStringArray:
	if config.steam:
		return PackedStringArray(["STEAM", "FRIENDS"])
	if not config.server.is_empty():
		var named := config.server_name if not config.server_name.is_empty() else config.server
		return PackedStringArray(["SERVER", named.to_upper()])
	return PackedStringArray(["LAN", "THIS NETWORK"])


## Stamped for the game [param config] plays, or put away for none, a game on this machine alone.
func show_for(config: MatchConfig) -> void:
	visible = config != null and not config.online.is_empty()
	if not visible:
		return
	var words := words_for(config)
	word = words[0]
	under = words[1]
	queue_redraw()


func _draw() -> void:
	StampArt.stamp(self, size * 0.5, radius, word, OVER, under, TURN, INK)
