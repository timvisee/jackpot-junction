class_name FloatingText
extends Label3D
## Short-lived in-world text that rises and fades: grazes, mult gains and the cash-out tally.

var _duration := 1.0
var _age := 0.0
var _prefix := ""
var _count_from := 0
var _count_to := -1
var _count_time := 0.0


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
	# Set as every number of the HUD is, GAME.md 8.1a: the condensed cut, figures all one width,
	# outlined in the house's dark rather than black.
	label.font = Type.numbers_font()
	label.outline_size = maxi(size / 5, 6)
	label.outline_modulate = Color(0.05, 0.045, 0.065)
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = position + Vector3(0.0, 1.2, 0.0)
	label._duration = duration
	parent.add_child(label)
	return label


## A tally that counts up to [param total] over [param count_time] seconds before fading.
static func spawn_counting(
	parent: Node,
	position: Vector3,
	prefix: String,
	total: int,
	color: Color,
	size: int,
	duration: float
) -> FloatingText:
	var label := spawn(parent, position, prefix + "0", color, size, duration)
	label._prefix = prefix
	label._count_to = total
	label._count_time = maxf(duration * 0.5, 0.1)
	return label


## The tally this label is counting to, so a run of them can be added up into one.
func total() -> int:
	return _count_to


## Keeps a tally alive and sends it on to a bigger number, counting from wherever it had got
## to. A player sitting on the Junction while the flush pads trickle banks over and over, and
## one number climbing says that better than a new label every second. The equation the first
## cash-out showed is dropped, since it is no longer what made the total.
func extend_to(new_total: int) -> void:
	_prefix = ""
	_count_from = _shown()
	_count_to = new_total
	_age = 0.0
	modulate.a = 1.0


## The number on the label right now, part way through its count.
func _shown() -> int:
	if _count_to < 0:
		return 0
	return int(
		round(lerpf(float(_count_from), float(_count_to), clampf(_age / _count_time, 0.0, 1.0)))
	)


func _process(delta: float) -> void:
	_age += delta
	if _count_to >= 0:
		var shown := _shown()
		text = "%s%d" % [_prefix, shown]
		position.y += 0.3 * delta
	else:
		position.y += 1.2 * delta
	var progress := _age / _duration
	modulate.a = 1.0 - clampf((progress - 0.6) / 0.4, 0.0, 1.0)
	if _age >= _duration:
		queue_free()
