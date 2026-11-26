class_name CornerPaint
extends Node
## A player's corner of the HUD in their new color the moment they pick it, GAME.md 4.4: the name,
## the stripe, the nitro line, the hints and the hearts. The HUD keeps its corners in their colors
## frame by frame, see [method HudBlock.follow], and the pause menu the color is picked in holds
## those frames still; this hears the kart painted, see [signal Events.kart_painted], instead.

var hud: MatchHud


static func add_to(to: MatchHud) -> CornerPaint:
	var paint := CornerPaint.new()
	paint.name = "CornerPaint"
	paint.hud = to
	to.add_child(paint)
	return paint


func _ready() -> void:
	Events.kart_painted.connect(_on_kart_painted)


func _exit_tree() -> void:
	Events.kart_painted.disconnect(_on_kart_painted)


func _on_kart_painted(kart: Node3D) -> void:
	var match_node := hud.match_node
	if match_node == null:
		return
	for slot: PlayerSlot in match_node.slots:
		var block := hud.block_parts(slot.index)
		if slot.kart == kart and not block.is_empty():
			HudBlock.follow(block, slot)
			HudBlock.show_lives(block, slot)
