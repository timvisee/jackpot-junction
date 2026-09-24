class_name WatcherEmotes
extends Control
## The emotes of somebody watching, GAME.md 3.8. They have no kart to put one over, so it floats up
## from the bottom of every screen instead, at a spot of its own, and fades, the way a reaction
## rises up a live stream: on a bubble rimmed in gray rather than in a player's color, since a
## watcher has none, with their name under it.

## The gray a watcher's bubble is rimmed in, and their name written in.
const INK := Color(0.62, 0.62, 0.66)
## How big the bubble is, how far up the screen it floats and for how long, and how long of that
## it takes to fade.
const SIDE := 64.0
const RISE := 220.0
const SHOWN := 2.4
const FADE := 0.6
## How far in from the sides of the screen a bubble may start, as a share of its width.
const SPREAD := 0.15

var _rng := RandomNumberGenerator.new()


static func add_to(hud: CanvasLayer) -> WatcherEmotes:
	var emotes := WatcherEmotes.new()
	emotes.name = "WatcherEmotes"
	hud.add_child(emotes)
	return emotes


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	Events.watcher_emoted.connect(_on_watcher_emoted)


func _exit_tree() -> void:
	if Events.watcher_emoted.is_connected(_on_watcher_emoted):
		Events.watcher_emoted.disconnect(_on_watcher_emoted)


func _on_watcher_emoted(watcher: String, emote: int) -> void:
	if emote < 0 or emote >= EmoteArt.EMOTES.size():
		return
	var bubble := VBoxContainer.new()
	bubble.name = "WatcherEmote"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.alignment = BoxContainer.ALIGNMENT_CENTER
	bubble.add_theme_constant_override("separation", 2)
	var picture := EmoteArt.picture(emote, INK, SIDE)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bubble.add_child(picture)
	var label := Label.new()
	label.text = watcher
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(label, Type.LABEL, INK)
	HudText.shadowed(label)
	bubble.add_child(label)
	add_child(bubble)
	bubble.size = bubble.get_combined_minimum_size()
	var x := _rng.randf_range(size.x * SPREAD, size.x * (1.0 - SPREAD)) - bubble.size.x * 0.5
	bubble.position = Vector2(x, size.y - bubble.size.y - 24.0)
	var tween := bubble.create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position:y", bubble.position.y - RISE, SHOWN).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_property(bubble, "modulate:a", 0.0, FADE).set_delay(SHOWN - FADE)
	tween.chain().tween_callback(bubble.queue_free)
