class_name ReadPlan
extends RefCounted
## The leaves of a whole read of the driving school's theory book, GAME.md 9.4a, planned before
## the first: when each starts, counted from when the reading starts, how long it takes, never
## longer than until the next, so no leaf is put down mid-air, and the page number it lands on,
## going on a spread a leaf while the leaves are slow, racing while they riffle and counting on a
## spread a leaf again as they slow to the end's, 211 and 212. See [SchoolTheory].

var at: PackedFloat32Array = []
var lasting: PackedFloat32Array = []
var folio: PackedInt32Array = []


## When each leaf of a whole read starts, counted from when the reading starts: the first after
## [constant SchoolTheory.TURN_FIRST], each next one sooner by [constant SchoolTheory.TURN_RAMP]
## down to the riffle, slowing again over [constant SchoolTheory.SLOW_FOR] before the last, which
## turns at [constant SchoolTheory.LAST_TURN] onto the end, a slow leaf's gap after the one before
## it at the least.
static func starts() -> PackedFloat32Array:
	var found := PackedFloat32Array()
	var when := SchoolTheory.TURN_FIRST
	var interval := SchoolTheory.TURN_FIRST
	while when < SchoolTheory.LAST_TURN:
		found.append(when)
		if when >= SchoolTheory.LAST_TURN - SchoolTheory.SLOW_FOR:
			interval = minf(interval / SchoolTheory.TURN_RAMP, SchoolTheory.TURN_SLOWEST)
		else:
			interval = maxf(interval * SchoolTheory.TURN_RAMP, SchoolTheory.TURN_FASTEST)
		when += interval
	while found.size() > 1 and SchoolTheory.LAST_TURN - found[found.size() - 1] < interval * 0.7:
		found.remove_at(found.size() - 1)
	found.append(SchoolTheory.LAST_TURN)
	return found


## How many leaves a whole read turns, the last onto the end, so the text can be checked to be
## long enough never to come round again.
static func turns() -> int:
	return starts().size()


## The plan of a whole read, see [member at]: each leaf takes most of the time to the next and
## the last a slow leaf's time, and the page numbers race up the curve of the pace until the
## riffle slows, then count on by a spread a leaf to the end's, 211 and 212.
static func of_a_read() -> ReadPlan:
	var plan := ReadPlan.new()
	plan.at = starts()
	var count := plan.at.size()
	plan.lasting.resize(count)
	for i: int in count - 1:
		var gap := plan.at[i + 1] - plan.at[i]
		plan.lasting[i] = minf(gap * SchoolTheory.TURN_SHARE, SchoolTheory.TURN_SLOWEST)
	plan.lasting[count - 1] = SchoolTheory.TURN_SLOWEST
	var slow_from := count - 1
	for i: int in count:
		if plan.at[i] >= SchoolTheory.LAST_TURN - SchoolTheory.SLOW_FOR:
			slow_from = i
			break
	var slowing := SchoolTheory.PAGES - 1 - 2 * (count - 1 - slow_from)
	var top := exp(SchoolTheory.FOLIO_RAMP) - 1.0
	plan.folio.resize(count)
	var last := 1
	for i: int in count:
		var number := SchoolTheory.PAGES - 1 - 2 * (count - 1 - i)
		if i < slow_from:
			var share := (
				(exp(SchoolTheory.FOLIO_RAMP * float(i) / float(maxi(slow_from, 1))) - 1.0) / top
			)
			number = 1 + roundi(share * float(slowing - 3))
			number = mini(maxi(number, last + 2), slowing - 2 * (slow_from - i))
		plan.folio[i] = number
		last = number
	return plan
