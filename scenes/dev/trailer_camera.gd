extends Camera3D
## The store trailer's own camera, docs/STEAM.md "The trailer", for the one close shot the match's
## camera cannot take: held on a spot, or travelling between two, each eased; and handed over to the
## match's own camera by blending into wherever it is looking, so a close shot opens out into the
## game as a player sees it, see [method blend_to].

enum Mode { HOLD, DOLLY, BLEND, OFF }

var mode := Mode.OFF
var from := Vector3.ZERO
var to := Vector3.ZERO
var looking := Vector3.ZERO
var looking_to := Vector3.ZERO
var seconds := 1.0
var _at := 0.0
var _from_basis := Basis.IDENTITY
var _from_fov := 46.0
var _into: Camera3D


func _init() -> void:
	fov = 46.0
	near = 0.05
	far = 400.0


## Still at [param place], looking at [param at].
func hold(place: Vector3, at: Vector3) -> void:
	mode = Mode.HOLD
	global_position = place
	look_at(at)
	make_current()


## From [param start] looking at [param at_start] to [param end] looking at [param at_end], over
## [param length] seconds, eased at both ends.
func dolly(start: Vector3, end: Vector3, at_start: Vector3, at_end: Vector3, length: float) -> void:
	mode = Mode.DOLLY
	from = start
	to = end
	looking = at_start
	looking_to = at_end
	seconds = maxf(length, 0.01)
	_at = 0.0
	global_position = start
	look_at(at_start)
	make_current()


## From where it is into [param camera], following it as it moves, over [param length] seconds,
## eased; then [param camera] is the one drawn.
func blend_to(camera: Camera3D, length: float) -> void:
	mode = Mode.BLEND
	_into = camera
	_from_basis = global_basis.orthonormalized()
	from = global_position
	_from_fov = fov
	seconds = maxf(length, 0.01)
	_at = 0.0


func _process(delta: float) -> void:
	match mode:
		Mode.DOLLY:
			_at = minf(_at + delta / seconds, 1.0)
			var eased := smoothstep(0.0, 1.0, _at)
			global_position = from.lerp(to, eased)
			look_at(looking.lerp(looking_to, eased))
		Mode.BLEND:
			if not is_instance_valid(_into):
				mode = Mode.OFF
				return
			_at = minf(_at + delta / seconds, 1.0)
			# Eased in slowly and out slower, as a crane rises and settles.
			var eased := 1.0 - pow(1.0 - smoothstep(0.0, 1.0, _at), 2.0)
			var target := _into.global_transform
			global_position = from.lerp(target.origin, eased)
			global_basis = _from_basis.slerp(target.basis.orthonormalized(), eased)
			fov = lerpf(_from_fov, _into.fov, eased)
			if _at >= 1.0:
				mode = Mode.OFF
				_into.make_current()
