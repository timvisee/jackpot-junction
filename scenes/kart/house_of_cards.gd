class_name HouseOfCards
extends DressMoments
## The supporter pack's House of cards, GAME.md 10.8: playing cards balanced on the helmet in
## storeys, a storey more as the pot grows, one below a pot worth banking, two from there and three
## at a full one; the cards settling into place as a storey goes on, the whole of it wobbling a
## little as it rides. At a death it collapses, the cards thrown off and falling, and it stands
## again at the respawn; at a cash-out it folds into a neat deck and builds again. Push your luck,
## worn on the head. The cards are one [MultiMesh], so the whole house is one draw.

enum State { STANDING, FALLING, DOWN, FOLDING }

## A card, in the measures a hat is cut in, how far each leans in its pair, and how far apart the
## pairs of a storey stand.
const CARD := Vector2(0.19, 0.264)
const LEAN := 22.0
const SPAN := 0.24
## The most storeys it stands, and how many cards that takes.
const MOST := 3
const MOST_CARDS := 15
## How high its first storey stands, on the helmet.
const FOOT := 0.08
## How long a storey takes to settle, how far above it the cards come down from, how long the cards
## fall at a death, how hard they are thrown and how strong their fall is, how long it takes to
## fold into a deck at a cash-out and how long the deck is held before it builds again.
const SETTLE := 0.3
const DROP := 0.08
const FALL := 1.1
const THROW := 1.6
const GRAVITY := 6.0
const FOLD := 0.35
const HOLD := 0.25
## How far it is turned on the helmet, so that neither the camera in front of the kart nor the one
## beside it sees its cards edge-on; and how far it wobbles as it rides, in radians, and how fast.
const TURN := 40.0
const WOBBLE := 0.025
const WOBBLE_RATE := 1.7

## The cards it stands, and how many storeys it stands now.
var cards: MultiMeshInstance3D
## How far it is turned on the helmet, in degrees: [constant TURN] on a kart, none in the rack's
## picture, whose camera is itself turned to the side, see [method DressPicture.film].
var turn := TURN
var storeys := 0
var state := State.STANDING
var _time := 0.0
var _from: Array[Transform3D] = []
var _velocities: Array[Vector3] = []
var _spins: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_rng.seed = 7
	# Turned from the start, for a picture taken before it is first stepped.
	if cards != null:
		cards.rotation.y = deg_to_rad(turn)
	stand(wanted())


## How many storeys the pot asks for.
func wanted() -> int:
	if pot < 0.0:
		return MOST
	if pot < worth:
		return 1
	return 2 if pot < full else MOST


## Stands [param count] storeys, the cards settling into place.
func stand(count: int) -> void:
	storeys = count
	state = State.STANDING
	_time = 0.0
	if cards != null:
		var placed := layout(count)
		cards.multimesh.visible_instance_count = placed.size()
		# Laid at once, settled, for a picture taken before it is first stepped.
		for i: int in placed.size():
			cards.multimesh.set_instance_transform(i, placed[i])


## Where each card of a house of [param count] storeys stands, in the house's own space: each storey
## its pairs leaning together, one fewer pair a storey up, a flat card bridging each two pairs for
## the storey above to stand on.
static func layout(count: int) -> Array[Transform3D]:
	var placed: Array[Transform3D] = []
	var lean := deg_to_rad(LEAN)
	var tall := cos(lean) * CARD.y
	var half_gap := sin(lean) * CARD.y * 0.5
	var y := FOOT
	for storey: int in count:
		var pairs := count - storey
		for pair: int in pairs:
			var x := (float(pair) - float(pairs - 1) * 0.5) * SPAN
			for side: float in [-1.0, 1.0]:
				var turned := Basis(Vector3.BACK, side * lean) * Basis(Vector3.UP, PI * 0.5)
				placed.append(
					Transform3D(turned, Vector3(x + side * half_gap, y + tall * 0.5, 0.0))
				)
		y += tall
		for bridge: int in pairs - 1:
			var x := (float(bridge) - float(pairs - 2) * 0.5) * SPAN
			var flat := Basis(Vector3.RIGHT, -PI * 0.5) * Basis(Vector3.BACK, PI * 0.5)
			placed.append(Transform3D(flat, Vector3(x, y + 0.004, 0.0)))
		y += 0.008
	return placed


## The box round the whole house standing, in its own space, see [method layout]: what its cards
## are framed and culled by, since the engine cannot measure cards it moves itself.
static func bounds() -> AABB:
	var card := AABB(Vector3(-CARD.x, -CARD.y, -0.01) * 0.5, Vector3(CARD.x, CARD.y, 0.01))
	var box := AABB()
	var placed := layout(MOST)
	for i: int in placed.size():
		box = placed[i] * card if i == 0 else box.merge(placed[i] * card)
	return box


func _died() -> void:
	state = State.FALLING
	_time = 0.0
	_from = _current()
	_velocities.clear()
	_spins.clear()
	for card: Transform3D in _from:
		var out := Vector3(card.origin.x, 0.0, _rng.randf_range(-0.5, 0.5)).normalized()
		_velocities.append((out + Vector3.UP * _rng.randf_range(0.6, 1.4)) * THROW)
		_spins.append(
			Vector3(
				_rng.randf_range(-9.0, 9.0),
				_rng.randf_range(-9.0, 9.0),
				_rng.randf_range(-9.0, 9.0)
			)
		)


func _respawned() -> void:
	stand(wanted())


func _cashed() -> void:
	state = State.FOLDING
	_time = 0.0
	_from = _current()


func tick(delta: float) -> void:
	if cards == null:
		return
	_time += delta
	cards.rotation = Vector3(
		sin(clock * WOBBLE_RATE) * WOBBLE,
		deg_to_rad(turn),
		sin(clock * WOBBLE_RATE * 1.3 + 1.0) * WOBBLE
	)
	match state:
		State.STANDING:
			if alive and not cashing and wanted() != storeys:
				stand(wanted())
			var settled := ease(clampf(_time / SETTLE, 0.0, 1.0), 0.4)
			var placed := layout(storeys)
			for i: int in placed.size():
				var lift := Vector3.UP * DROP * (1.0 - settled) * (1.0 + 0.3 * float(i % 3))
				cards.multimesh.set_instance_transform(i, placed[i].translated(lift))
		State.FALLING:
			var gone := minf(_time, FALL)
			for i: int in _from.size():
				var card := _from[i]
				var moved := _velocities[i] * gone + Vector3.DOWN * GRAVITY * 0.5 * gone * gone
				var spun := Basis.from_euler(_spins[i] * gone) * card.basis
				cards.multimesh.set_instance_transform(i, Transform3D(spun, card.origin + moved))
			if _time >= FALL:
				state = State.DOWN
				cards.multimesh.visible_instance_count = 0
		State.FOLDING:
			var folded := ease(clampf(_time / FOLD, 0.0, 1.0), -2.0)
			for i: int in _from.size():
				var deck := Transform3D(
					Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, FOOT + 0.006 * float(i), 0.0)
				)
				cards.multimesh.set_instance_transform(i, _from[i].interpolate_with(deck, folded))
			if _time >= FOLD + HOLD:
				stand(wanted())


## Where each card shown stands now.
func _current() -> Array[Transform3D]:
	var now: Array[Transform3D] = []
	for i: int in cards.multimesh.visible_instance_count:
		now.append(cards.multimesh.get_instance_transform(i))
	return now
