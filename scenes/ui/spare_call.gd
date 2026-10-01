class_name SpareCall
extends Node
## What it looks like when a joker takes a hit for a kart, GAME.md 7.3: over the kart, the heart
## that would have broken rises whole and wears a halo, in the pale gold of an angel, and in the
## hand of a player at this screen the card that did it lights up. The item it spent is gone from
## the corner, and without a word for it that reads as an item lost rather than a life kept. A
## picture rather than the joker's name over the kart, the way a life lost is a heart breaking
## rather than words, GAME.md 3.6: two words are read, and a player reading is not driving.

const INK := Color(1.0, 0.92, 0.6)
## How long the heart and its halo take to rise and fade, in seconds.
const SHOWN := 1.4
## The halo over the heart in the unit box, y downwards: its middle, its two radii, how thick its
## ring is, and how many pieces round it is made of.
const HALO_AT := Vector2(0.5, 0.11)
const HALO_RADII := Vector2(0.3, 0.085)
const HALO_RING := 0.055
const HALO_PIECES := 24
## How much of the unit box the heart under it takes, and how far down it starts.
const HEART_SHARE := 0.74
const HEART_TOP := 0.25

var hud: MatchHud


static func add_to(on: MatchHud) -> SpareCall:
	var call := SpareCall.new()
	call.name = "SpareCall"
	call.hud = on
	on.add_child(call)
	return call


func _ready() -> void:
	Events.kart_spared.connect(_on_spared)


func _exit_tree() -> void:
	if Events.kart_spared.is_connected(_on_spared):
		Events.kart_spared.disconnect(_on_spared)


func _on_spared(slot: int, joker: StringName) -> void:
	var match_node := hud.match_node
	if match_node == null or slot < 0 or slot >= match_node.slots.size():
		return
	var kart := match_node.slots[slot].kart
	if kart != null:
		FloatingIcon.spawn(
			match_node, kart.global_position, shapes(), INK, MatchHud.LIFE_ICON * 1.3, SHOWN
		)
	var hand := hud.hand_of(slot)
	if hand != null:
		hand.flash(joker)


## A whole heart with a halo over it, in the unit box, for [FloatingIcon].
static func shapes() -> Array[PackedVector2Array]:
	var drawn: Array[PackedVector2Array] = []
	var heart := PackedVector2Array()
	var inset := (1.0 - HEART_SHARE) * 0.5
	for point: Vector2 in Heart.unit_shape():
		heart.append(Vector2(inset, HEART_TOP) + point * HEART_SHARE)
	drawn.append(heart)
	var inner := HALO_RADII - Vector2.ONE * HALO_RING
	for i: int in HALO_PIECES:
		var from := TAU * i / HALO_PIECES
		var to := TAU * (i + 1) / HALO_PIECES
		var way_from := Vector2(cos(from), sin(from))
		var way_to := Vector2(cos(to), sin(to))
		var piece := PackedVector2Array()
		piece.append(HALO_AT + way_from * HALO_RADII)
		piece.append(HALO_AT + way_to * HALO_RADII)
		piece.append(HALO_AT + way_to * inner)
		piece.append(HALO_AT + way_from * inner)
		drawn.append(piece)
	return drawn
