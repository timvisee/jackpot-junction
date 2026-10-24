extends RefCounted
## An area burst, GAME.md 5.3: everything in the radius takes it -- karts lose a life, crates and
## turrets break and other bombs go off. Shared by the explosive shots, the rocket and grenade, see
## [Bullet]; the [Bomb] does its own the same way. The damage is dealt on the host alone; the flash,
## [Explosion], is shown on every machine from [signal Events.burst], so a client sees it as well.


## Bursts [param radius] wide around [param at] in [param match_node], crediting [param owner_slot]
## of [param team], and tells every machine to show it in [param color]. The caller is the host: a
## shot on a client is a puppet and deals no damage.
static func go(
	match_node: Match, at: Vector3, radius: float, owner_slot: int, team: int, color: Color
) -> void:
	if match_node == null:
		return
	_karts(match_node, at, radius, owner_slot, team)
	_things(match_node, at, radius, owner_slot, team)
	Events.burst.emit(at, radius, color)


## The karts within reach, each losing a life unless a teammate of the owner's, GAME.md 3.14.
static func _karts(
	match_node: Match, at: Vector3, radius: float, owner_slot: int, team: int
) -> void:
	for node: Node in MatchSnapshot.own_nodes(match_node, &"karts"):
		var kart := node as Kart
		if kart != null and _within(at, kart.global_position, radius, 0.5):
			if not Teams.spares(owner_slot, team, kart):
				kart.take_blast(owner_slot)


## The crates, turrets and other bombs within reach: crates and turrets break, bombs go off.
static func _things(
	match_node: Match, at: Vector3, radius: float, owner_slot: int, team: int
) -> void:
	for node: Node in MatchSnapshot.own_nodes(match_node, &"crates"):
		var crate := node as Crate
		if crate != null and crate.alive and _within(at, crate.global_position, radius, 0.5):
			crate.hit(owner_slot)
	for node: Node in MatchSnapshot.own_nodes(match_node, &"turrets"):
		var turret := node as Turret
		if turret != null and turret.alive and _within(at, turret.global_position, radius, 0.4):
			var friendly := turret.spares_team and turret.owner_slot != owner_slot
			if not (friendly and Teams.same(team, turret.team)):
				turret.destroy()
	for node: Node in MatchSnapshot.own_nodes(match_node, &"bombs"):
		var bomb := node as Bomb
		if bomb != null and bomb.alive and _within(at, bomb.global_position, radius, 0.0):
			bomb.explode()


static func _within(at: Vector3, point: Vector3, radius: float, margin: float) -> bool:
	var flat := Vector3(point.x - at.x, 0.0, point.z - at.z)
	return flat.length() <= radius + margin
