class_name Layers
extends RefCounted
## Physics layer bits, matching the layer names in project.godot.

const WORLD := 1 << 0
const KART := 1 << 1
const BULLET := 1 << 2
const PICKUP := 1 << 3
const TRIGGER := 1 << 4
const GRAZE := 1 << 5
const TURRET := 1 << 6
const PROTECTED := 1 << 7
## Bombs: bullets hit them, karts drive over them.
const BOMB := 1 << 8
## A client's own kart while it is driving it ahead of the host, GAME.md 10.3, and the puppets of
## everybody else's. Kept off [constant KART] on purpose: a host and a puppet match can share a
## scene tree, in tests and in a future split screen, and a predicted kart that answered to the
## other match's karts and triggers would be shoved about by a room it is not in.

const PUPPET := 1 << 9
## The waiting room's football, see [RoomBall]: like a bomb, bullets hit it and karts drive
## through it, but on a bit of its own so that nothing looking for a bomb ever finds a ball.
const BALL := 1 << 10
