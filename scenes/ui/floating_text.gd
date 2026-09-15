class_name FloatingText
extends Label3D
## Short-lived in-world text that rises and fades: grazes, mult gains and the cash-out tally.

var _duration := 1.0
var _age := 0.0


static func spawn(
	parent: Node,
	position: Vector3,
	text: String,
	color: Color,
	size: int = 48,
	duration: float = 1.0
) -> FloatingText:
	var label := FloatingText.new()
	label.text = text
	label.modulate = color
	label.font_size = size
	label.outline_size = maxi(size / 5, 6)
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = position + Vector3(0.0, 1.2, 0.0)
	label._duration = duration
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	_age += delta
	position.y += 1.2 * delta
	var progress := _age / _duration
	modulate.a = 1.0 - clampf((progress - 0.6) / 0.4, 0.0, 1.0)
	if _age >= _duration:
		queue_free()
