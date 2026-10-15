class_name KartMoves
extends RefCounted
## What the kart dialog's kart does with itself, GAME.md 4.4a, see [KartStage]: where it is in a
## move at a moment of it, as how far it is lifted, tipped and turned and about where. Every move
## starts and ends with the kart standing as it was, so one runs on into the next without a cut.
##
## A jump, a wheelie, a quick spin, a drift and a donut; and, standing about, a rev of its engine,
## a shake as a wet dog's, a look round either way, three little hops, and a tip onto the wheels of
## one side.


## [param move], one of [enum KartStage.Move], [param elapsed] seconds into it of
## [param length]: its lift, its pitch, its roll and its turn, how far it slides sideways, how far
## it is squashed, and the point it turns about, in the kart's own space.
static func pose(move: int, elapsed: float, length: float) -> Dictionary:
	var t := clampf(elapsed / length, 0.0, 1.0)
	var lift := 0.0
	var pitch := 0.0
	var roll := 0.0
	var turned := 0.0
	var slide := 0.0
	var squash := 1.0
	var pivot := Vector3.ZERO
	# How far into and out of it a move that eases in and out is.
	var held := smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.85, 1.0, t))
	match move:
		KartStage.Move.JUMP:
			var air := clampf(elapsed / (length * 0.8), 0.0, 1.0)
			lift = sin(air * PI) * KartStage.JUMP
			pitch = sin(air * TAU) * 0.12
			if air >= 1.0:
				squash = 1.0 - sin((elapsed - length * 0.8) / (length * 0.2) * PI) * 0.14
		KartStage.Move.WHEELIE:
			pivot = Vector3(0.0, 0.0, KartStage.REAR_AXLE)
			var up := smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.8, 1.0, t))
			pitch = up * (0.42 + sin(elapsed * 14.0) * 0.04)
		KartStage.Move.SPIN:
			turned = TAU * ease(t, -2.2)
			lift = sin(t * PI) * 0.15
		KartStage.Move.DRIFT:
			turned = sin(t * TAU) * 0.6
			slide = sin(t * TAU + PI * 0.5) * 0.25 * sin(t * PI)
			roll = -sin(t * TAU) * 0.08
		KartStage.Move.DONUT:
			# Two whole turns, so it ends as it started rather than snapping back to it.
			pivot = Vector3(0.0, 0.0, KartStage.FRONT_AXLE)
			turned = TAU * 2.0 * ease(t, -1.8)
			roll = sin(t * PI) * 0.07
		KartStage.Move.REV:
			# The engine revved hard twice: its back squatting, the whole of it shaking.
			var revs := maxf(sin(t * TAU * 2.0), 0.0) * held
			pivot = Vector3(0.0, 0.0, KartStage.FRONT_AXLE)
			pitch = -revs * 0.06
			lift = sin(elapsed * 61.0) * 0.008 * held
			roll = sin(elapsed * 47.0) * 0.015 * held
		KartStage.Move.SHIMMY:
			# A shake from side to side, as a wet dog's, quick and dying away.
			var shake := sin(t * TAU * 4.0) * held * (1.0 - t * 0.6)
			roll = shake * 0.13
			turned = sin(t * TAU * 4.0 + 0.6) * 0.1 * held
			lift = absf(shake) * 0.03
		KartStage.Move.PEEK:
			# A look over one shoulder and then the other, and back.
			turned = sin(t * TAU) * 0.65 * held
			pitch = -absf(sin(t * TAU)) * 0.04
		KartStage.Move.BOUNCE:
			# Three little hops on the spot, each a little lower, landing with a squash.
			var hop := fmod(t * 3.0, 1.0)
			var high := 0.13 * (1.0 - floorf(t * 3.0) * 0.25)
			lift = sin(hop * PI) * high
			# A squash as each hop lands, over and gone before the next one leaves the floor.
			var landing := clampf((hop - 0.82) / 0.18, 0.0, 1.0)
			squash = 1.0 - sin(landing * PI) * 0.08
		KartStage.Move.TIP:
			# Up onto the wheels of its left side, held there a moment, and down again.
			pivot = Vector3(-KartStage.REAR_TRACK, 0.0, 0.0)
			roll = held * (0.34 + sin(elapsed * 9.0) * 0.03)
	return {
		"lift": lift,
		"pitch": pitch,
		"roll": roll,
		"turned": turned,
		"slide": slide,
		"squash": squash,
		"pivot": pivot,
	}
