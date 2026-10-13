class_name Emotes
extends Node
## Emotes over the karts, GAME.md 3.8: a player flicks the right stick, or presses one of the keys
## 7 to 0, and a bubble with the emote on it pops up over their kart for a moment, rimmed in their
## color, the way the ready tick floats over it. The machine that runs the karts decides, the host
## online, and says so with [signal Events.emoted], which every machine answers by putting the
## bubble up, so they come up everywhere at once, a client's own included.

## How high over the kart the bubble floats, clear of the tick and the hints under it.
const HEIGHT := 3.1
## How long a bubble stays up, how long it takes to pop in and to fade out, all in seconds.
const SHOWN := 2.2
const POP := 0.18
const FADE := 0.3
## How soon after one a player may put up the next: enough to read one before it is replaced.
const COOLDOWN := 1.0
## How big the bubble is drawn, in pixels, and how big that is in the world.
const SIDE := 128.0
const PIXEL := 0.01

var match_node: Match

var _cool: Dictionary[int, float] = {}


static func add_to(in_match: Match) -> Emotes:
	var emotes := Emotes.new()
	emotes.name = "Emotes"
	emotes.match_node = in_match
	in_match.add_child(emotes)
	return emotes


func _ready() -> void:
	Events.emoted.connect(_on_emoted)


func _exit_tree() -> void:
	if Events.emoted.is_connected(_on_emoted):
		Events.emoted.disconnect(_on_emoted)


func _physics_process(delta: float) -> void:
	if match_node.puppet:
		return
	# Past the whistle nobody drives and nothing else reads a player's controls here, but the
	# photo finish is a moment to say something too, see [ResultsPodium]. A client's come over the
	# wire as ever.
	var after := match_node.state == Match.State.RESULTS
	for slot: PlayerSlot in match_node.slots:
		_cool[slot.index] = maxf(_cool.get(slot.index, 0.0) - delta, 0.0)
		if not slot.is_human() or slot.input == null or slot.kart == null:
			continue
		if after and slot.input is PlayerInput:
			slot.input.poll(delta)
		var emote := slot.input.emote
		# Dead or not: a player waiting to come back has something to say too, and it floats up
		# from the bottom of the screen with nothing to put it over, see [WatcherEmotes].
		if emote < 0 or emote >= EmoteArt.EMOTES.size() or _cool[slot.index] > 0.0:
			continue
		_cool[slot.index] = COOLDOWN
		Events.emoted.emit(slot.index, emote)


## Somebody has emoted, here or on the host: up it goes over their kart, in place of one still up.
## A dead one's has no kart to go over, and floats up from the bottom instead, see [WatcherEmotes].
func _on_emoted(index: int, emote: int) -> void:
	if index < 0 or index >= match_node.slots.size():
		return
	var slot := match_node.slots[index]
	var kart := slot.kart
	if kart == null or not is_instance_valid(kart) or not kart.alive:
		return
	pop_over(kart, emote, slot.color())


## [param emote]'s bubble, rimmed in [param ink], popping up [param height] over [param over] in
## place of one still up there, staying a moment and fading: over a kart, or over its likeness on
## the podium of the photo finish, see [ResultsPodium], [param big] as it is drawn there.
static func pop_over(over: Node3D, emote: int, ink: Color, height := HEIGHT, big := 1.0) -> void:
	var old := over.get_node_or_null("Emote")
	if old != null:
		over.remove_child(old)
		old.queue_free()
	var bubble := InputHint.billboard(EmoteArt.picture(emote, ink, SIDE), PIXEL * big)
	bubble.name = "Emote"
	bubble.position = Vector3(0.0, height, 0.0)
	bubble.scale = Vector3.ONE * 0.2
	over.add_child(bubble)
	var face := bubble.get_node("Face") as Sprite3D
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "scale", Vector3.ONE, POP).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_interval(SHOWN - POP - FADE)
	tween.tween_property(face, "modulate:a", 0.0, FADE)
	tween.tween_callback(bubble.queue_free)
