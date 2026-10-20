class_name KartPuppet
extends RefCounted
## A kart on a client, GAME.md 10.3: driven by the host's snapshots rather than simulated here.
## [method Kart.apply_puppet_state] hands each snapshot entry to [method apply], which keeps the
## pose as a target the kart's own physics step glides toward, and puts life state and effects on
## at once.


## Records one snapshot entry [param state] for the puppet [param kart].
static func apply(kart: Kart, state: Dictionary) -> void:
	var target := Vector3(state["x"], 0.0, state["z"])
	var was_alive := kart.alive
	kart.alive = state["alive"]
	if was_alive and not kart.alive and not KartShock.holds(kart):
		var color := Palette.player_color(kart.color_index)
		# Sprung apart as on the host, GAME.md 8.1b, but for a kart that shrank away down a pit, or
		# one held in a shock by a live cabinet first, which springs apart once that is over.
		if kart.scale.x > 0.5:
			KartWreck.spawn(kart.get_parent(), kart._body)
		Burst.spawn(kart.get_parent(), kart.global_position, color, 0.7, 10)
	if was_alive and not kart.alive:
		# A dead kart is not in the way. The host takes a kart's collisions off it when it dies,
		# and a puppet is never killed here, so until now nobody had: a kart somebody had just
		# shot went invisible and stayed solid, and the spot it died on could not be driven
		# through until it came back.
		kart.collision_layer = 0
		kart.collision_mask = 0
	if kart.alive and not was_alive:
		# Back on the floor, which is the host's to place. A respawn is a teleport rather than
		# driving, so it is one of the few things a kart driven here still takes from the
		# snapshot: without it a kart that went down a hole would come back still standing in
		# the hole, and fall down it again, for ever.
		kart.scale = Vector3.ONE
		kart.global_position = target
		kart.motor.heading = state["h"]
		kart.rotation = Vector3(0.0, kart.motor.heading, 0.0)
		kart.motor.velocity = Vector3.ZERO
		kart.motor.forward_speed = 0.0
		# Moved before it is made solid again, and in that order. A kart that fell down a hole is
		# still standing in one until it is put back, and a hole notices a kart the moment the
		# kart is something it can notice: made solid where it died, it would be dropped down the
		# same hole again on the frame it came back from it.
		kart.falling = false
		kart.collision_layer = Layers.PUPPET
	# A kart this client is driving takes its pose from its own driving and its corrections from
	# the message addressed to it, GAME.md 10.3. The broadcast snapshot is a third of a second of
	# round trip out of date for this one kart, and putting it here would undo the prediction
	# thirty times a second. Everything below is the host's either way.
	if not kart.predicted:
		var far := kart.global_position.distance_to(target) > Kart.PUPPET_SNAP_DISTANCE
		if not kart._puppet_has_target or not kart.alive or not was_alive or far:
			kart.global_position = target
			kart.motor.heading = state["h"]
			kart.rotation = Vector3(0.0, kart.motor.heading, 0.0)
		kart._puppet_target = target
		kart._puppet_heading = state["h"]
		kart._puppet_velocity = Vector3(state.get("vx", 0.0), 0.0, state.get("vz", 0.0))
		kart._puppet_has_target = true
		kart.motor.drifting = state["drift"]
		kart.motor.drift_time = state.get("drift_time", 0.0)
	kart.protection_left = 1.0 if state["prot"] else 0.0
	var blink := fmod(Time.get_ticks_msec() * 0.001, Kart.BLINK_PERIOD) < Kart.BLINK_PERIOD * 0.5
	var shown := kart.protection_left <= 0.0 or blink
	kart._body.visible = kart.alive and shown and not KartShock.holds(kart)
	kart.smoke.emitting = kart.alive
	kart.set_shielded(state["shield"])
	kart.channel_progress = state["ring"]
	kart._aim_arrow.visible = state["aim"]
	if not kart.predicted:
		# A kart driven here burns its own nitro and lights its own flame, GAME.md 10.3. The
		# host's word for it is a round trip old, and laying that over the top is what made
		# nitro flicker on a client: lit here, put out by the next snapshot, lit again.
		kart._flame.set_active(state.get("nitro", false))
