class_name LoyaltyMapLand
extends RefCounted
## The country of the loyalty program's map, GAME.md 8.9: what is on the paper besides its roads,
## its landmarks and its furniture, laid out once with the rest of [LoyaltyMapLayout] and kept clear
## of all of it.
##
## The House's districts are built up: a block of buildings between their side streets wherever
## there is room, and each has a sight of its own where it has most room, the Strip a fountain on
## its plaza, the Department a test track. The little drawings come in groups, as a country's woods
## and farms do: woods of round trees and pines on a tint of green, fields side by side in a
## patchwork with a barn, a row of hills, a village of a few houses and a tree. On the Strip a block
## of casinos, a row of palms, chips and dice; in the Department cones in a row, a depot with its
## stack of tires, a grove, a row of houses; Kit's in his margins, stars, spirals and question
## marks. The odd drawing stands on its own between them. The water is [LoyaltyMapWater]'s. The
## biggest wood, the farm and the hills have names, the house's puns on its tables. Kit has put his
## coffee down on his sheet.

## How big a place on the paper is, that a drawing takes or keeps clear of.
const CLEAR := 20.0
## The groups: tried on a lattice this far apart, each this far off it at most; the share of the
## places tried that get one in a district and in Kit's, and in the country where a slow swell
## over the paper is high, this far across a swell is, with this share anywhere between.
const GROUP_STEP := 112.0
const GROUP_JITTER := 40.0
const GROUPS := 1.0
const KIT_GROUPS := 0.45
const SWELL := 0.0017
const SCATTER := 0.5
## How near two drawings of one group may stand, a share of their sizes.
const PACK := 0.6
## The odd drawing on its own between the groups: tried this far apart, and the share that get one.
const STRAY_STEP := 44.0
const STRAYS := 0.13
## The places named, the woods, the farm and the hills, see [LoyaltyMapWater] for the water's; and
## the share of the groups that could have a name that are given it, the first of each kind laid
## big enough.
const NAMED := 0.45
## The fewest drawings a group laid can have and keep its name.
const NAMED_LEAST := 4
const WOODS_NAMES: Array[String] = ["Lucky Pines", "Flop Forest"]
const FARM_NAME := "Full House Farm"
const HILLS_NAME := "High Roller Hills"
## Each House district's sight, the drawing and how big; and the share of the blocks between its
## side streets that are built on.
const SIGHTS := {
	LoyaltyLandmark.District.STRIP: [&"fountain", 56.0],
	LoyaltyLandmark.District.DEPARTMENT: [&"track", 88.0],
}
const BUILT := 0.85
## Kit's coffee ring, how far round, and where on his sheet, a share of it.
const STAIN := 46.0
const STAIN_AT := Vector2(0.76, 0.66)
## The drawings that stand on their own in each district and, between them, in the country.
const STRAYS_OF := {
	LoyaltyLandmark.District.STRIP: [&"star", &"palm", &"dice", &"chips"],
	LoyaltyLandmark.District.DEPARTMENT: [&"cone", &"wood", &"house", &"tires"],
	LoyaltyLandmark.District.OFF_THE_BOOKS: [&"doodle_star", &"question", &"spiral"],
	-1: [&"wood", &"wood", &"pine", &"house", &"pond"],
}

var layout: LoyaltyMapLayout
var taken := {}
## The places of [member taken] a road took, and those something else did, which the river keeps
## off where it can go under a road.
var road := {}
var solid := {}
## The places water took, the moat's and the lakes', which the river runs through.
var water := {}
## The places the signs themselves and the districts' names took, which a district's blocks keep
## off: a ticket is drawn over whatever is under it.
var signs := {}
## The box round each district's wash, by its district.
var _boxes := {}
## The names of the country's places not given yet, by the kind of group they go to.
var _names := {&"woods": WOODS_NAMES.duplicate(), &"farm": [FARM_NAME], &"hills": [HILLS_NAME]}


## Lays out the country of [param on], into its drawings, woods, river, lake, bridges, places and
## stain.
static func lay(on: LoyaltyMapLayout) -> void:
	var land := LoyaltyMapLand.new()
	land.layout = on
	land._lay()


func _lay() -> void:
	_take_all()
	if layout.sheet == LoyaltyMapLayout.Sheet.HOUSE:
		LoyaltyMapWater.lay(self)
		_lay_features()
		_lay_blocks()
	else:
		layout.stain = Vector3(layout.paper.x * STAIN_AT.x, layout.paper.y * STAIN_AT.y, STAIN)
	_lay_groups()
	_lay_strays()


## A number from 0 to 1 for [param seed], the same every time, see [method LoyaltyMapLayout.roll].
static func _roll(seed: String) -> float:
	return LoyaltyMapLayout.roll(seed)


## A number from -1 to 1 for [param seed], the same every time.
static func _wobble(seed: String) -> float:
	return LoyaltyMapLayout.roll(seed) * 2.0 - 1.0


## Each House district's sight, see [constant SIGHTS], in the clear place inside it nearest its
## middle, and taken.
func _lay_features() -> void:
	for district: int in SIGHTS:
		if not layout.washes.has(district):
			continue
		var kind: StringName = SIGHTS[district][0]
		var size: float = SIGHTS[district][1]
		_district_at(Vector2.ZERO)
		var box: Rect2 = _boxes[district]
		var middle := middle_of(layout.washes[district])
		var best := Vector2.ZERO
		var nearest := INF
		var y := box.position.y
		while y < box.end.y:
			var x := box.position.x
			while x < box.end.x:
				var at := Vector2(x, y)
				x += 26.0
				if at.distance_to(middle) >= nearest or _district_at(at) != district:
					continue
				if not is_taken(at, size * 0.55):
					nearest = at.distance_to(middle)
					best = at
			y += 26.0
		if nearest < INF:
			layout.doodles.append({"kind": kind, "at": best, "size": size, "turn": 0.0})
			take(best, size * 0.6)


## The built-up blocks between the House's side streets, see [member LoyaltyMapLayout.blocks]:
## those clear of the signs, the districts' names and the roads that the dice say are built on,
## [constant BUILT] of them, taken so the little drawings keep off them; the rest left out. A
## ticket under a sign is drawn over the blocks there.
func _lay_blocks() -> void:
	var built: Array[Dictionary] = []
	for i: int in layout.blocks.size():
		var block: Dictionary = layout.blocks[i]
		var low := Vector2(INF, INF)
		var high := -low
		for corner: Vector2 in block["quad"]:
			low = low.min(corner)
			high = high.max(corner)
		var box := Rect2(low, high - low)
		if _roll("block %d" % i) > BUILT or _is_in(box.grow(-2.0), signs):
			continue
		if _crosses_a_road(block["quad"], box):
			continue
		built.append(block)
		take_rect(box)
	layout.blocks = built


## Whether any place [param rect] covers is in [param places].
static func _is_in(rect: Rect2, places: Dictionary) -> bool:
	var low := (rect.position / CLEAR).floor()
	var high := (rect.end / CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			if places.has(Vector2i(x, y)):
				return true
	return false


## Whether a road runs over the block [param quad], [param box] round it, or nearer it than half a
## road's width: the roads near its box alone tried.
func _crosses_a_road(quad: PackedVector2Array, box: Rect2) -> bool:
	var grown := LoyaltyMapLayout.largest(Geometry2D.offset_polygon(quad, LoyaltyMapArt.ROAD))
	for each: Dictionary in layout.roads:
		var line: PackedVector2Array = each["points"]
		var low := Vector2(INF, INF)
		var high := -low
		for point: Vector2 in line:
			low = low.min(point)
			high = high.max(point)
		if not Rect2(low, high - low).grow(LoyaltyMapArt.ROAD).intersects(box):
			continue
		if not Geometry2D.intersect_polyline_with_polygon(line, grown).is_empty():
			return true
	return false


## Everything the country keeps clear of taken: the roads and the words at the end of one off the
## sheet, each sign with the ticket under it, the districts' names, and the roundabout, the
## compass, the legend and the title block.
func _take_all() -> void:
	for each: Dictionary in layout.roads:
		var line: PackedVector2Array = each["points"]
		take_line(line, 26.0, road)
		if each.get("off_to", &"") != &"":
			take_rect(Rect2(line[-1] - Vector2(40.0, 70.0), Vector2(300.0, 140.0)))
	for id: StringName in layout.points:
		var rect := layout.sign_rect(id).grow(18.0)
		take_rect(layout.sign_rect(id).grow(10.0), signs)
		rect.size.y += 70.0
		take_rect(rect)
	for district: int in layout.names_at:
		var named := Rect2(layout.names_at[district] - Vector2(0.0, 30.0), Vector2(340.0, 44.0))
		take_rect(named, signs)
	if layout.sheet != LoyaltyMapLayout.Sheet.HOUSE:
		return
	var ring := layout.ring + 40.0
	take_rect(Rect2(layout.ring_middle - Vector2.ONE * ring, Vector2.ONE * ring * 2.0))
	var compass := LoyaltyMapLayout.COMPASS + 30.0
	take_rect(Rect2(layout.compass - Vector2.ONE * compass, Vector2.ONE * compass * 2.0))
	take_rect(layout.legend.grow(20.0))
	take_rect(layout.cartouche.grow(20.0))


## How far [param at] is from the nearest of [param points].
static func furthest(at: Vector2, points: Array[Vector2]) -> float:
	var least := INF
	for point: Vector2 in points:
		least = minf(least, point.distance_to(at))
	return least


## Names [param named] with its baseline's middle at [param at], where it is clear, and takes it.
## False where it is not clear.
func name_place(named: String, at: Vector2, wet: bool) -> bool:
	var font := LoyaltyMapPrint.place_font()
	var size := font.get_string_size(
		named, HORIZONTAL_ALIGNMENT_LEFT, -1, LoyaltyMapPrint.PLACE_SIZE
	)
	var rect := Rect2(at - Vector2(size.x * 0.5, size.y * 0.8), size)
	if not inside(rect.position) or not inside(rect.end) or is_rect_taken(rect.grow(4.0)):
		return false
	layout.places.append({"name": named, "at": at, "water": wet})
	take_rect(rect.grow(6.0))
	return true


## The groups of drawings, on a lattice over the paper, each row of it half a step along from the
## last: in each place the dice say gets one and that is clear, a group of the kind its district
## has, or the country's.
func _lay_groups() -> void:
	var paper := layout.paper
	var row := 0
	var y := GROUP_STEP * 0.5
	while y < paper.y:
		var x := GROUP_STEP * (0.25 + 0.5 * (row % 2))
		while x < paper.x:
			var seed := "group %d,%d" % [roundi(x), roundi(y)]
			var at := Vector2(x, y)
			at += Vector2(_wobble(seed + "a"), _wobble(seed + "b")) * GROUP_JITTER
			x += GROUP_STEP
			var district := _district_at(at)
			if (
				_roll(seed + "keep") < _chance(district, at)
				and inside(at)
				and not is_taken(at, 10.0)
			):
				_group(_kind_of(district, at, seed), district, at, seed)
		y += GROUP_STEP * 0.87
		row += 1


## The share of places at [param at], in [param district] or none, that get a group.
func _chance(district: int, at: Vector2) -> float:
	if district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		return KIT_GROUPS
	if layout.sheet == LoyaltyMapLayout.Sheet.KIT:
		# Graph paper has no country on it, only what Kit drew.
		return 0.0
	if district >= 0:
		return GROUPS
	return SCATTER + (1.0 - SCATTER) * _swell(at)


## The kind of group at [param at] in [param district]: the district's own, or out in the country
## farmland in one place and woods in another, by a second swell.
func _kind_of(district: int, at: Vector2, seed: String) -> StringName:
	var roll := _roll(seed + "kind")
	match district:
		LoyaltyLandmark.District.STRIP:
			return &"casinos" if roll < 0.36 else (&"palms" if roll < 0.72 else &"table")
		LoyaltyLandmark.District.DEPARTMENT:
			if roll < 0.3:
				return &"cones"
			return &"grove" if roll < 0.55 else (&"houses" if roll < 0.78 else &"depot")
		LoyaltyLandmark.District.OFF_THE_BOOKS:
			return &"stars" if roll < 0.45 else (&"scribble" if roll < 0.78 else &"pointer")
	if _swell(at.rotated(1.1) * 0.7) > 0.35:
		return &"farm" if roll < 0.55 else (&"village" if roll < 0.8 else &"hills")
	return &"woods" if roll < 0.52 else (&"hills" if roll < 0.74 else &"village")


## The drawings a group of [param kind] round [param at] tries: a kind, a place and a size each.
func _tries(kind: StringName, at: Vector2, seed: String) -> Array:
	# The group's own dice, thrown in turn, rather than a seed made and stirred for each throw.
	var dice := RandomNumberGenerator.new()
	dice.seed = int(LoyaltyMapLayout.roll(seed) * 2147483647.0)
	var turn := dice.randf_range(-0.5, 0.5)
	var many := func(least: int, most: int) -> int: return dice.randi_range(least, most)
	var tries: Array = []
	match kind:
		&"woods":
			var trees: int = many.call(6, 14)
			var reach := 26.0 + trees * 3.4
			for i: int in trees * 2:
				var off := Vector2.from_angle(dice.randf() * TAU) * sqrt(dice.randf()) * reach
				var tree := &"pine" if dice.randf() < 0.4 else &"wood"
				tries.append(
					[
						tree,
						at + (off * Vector2(1.4, 0.8)).rotated(turn * 0.6),
						22.0 + dice.randf() * 8.0
					]
				)
		&"farm":
			var across: int = many.call(2, 3)
			var down := 1 + int(dice.randf() * 2.0)
			var crops: Array[StringName] = [&"field", &"wheat", &"meadow"]
			for i: int in across:
				for k: int in down:
					var off := Vector2(
						(i - (across - 1) * 0.5) * 41.0, (k - (down - 1) * 0.5) * 29.0
					)
					var crop := crops[posmod(i + k * 2 + hash(seed), crops.size())]
					tries.append([crop, at + off.rotated(turn * 0.4), 40.0])
			var barn := Vector2((across * 0.5 + 0.55) * 41.0, 4.0).rotated(turn * 0.4)
			tries.append([&"barn", at + barn, 28.0])
			tries.append([&"wood", at - barn, 24.0])
		&"hills":
			var hills: int = many.call(3, 4)
			for i: int in hills:
				var off := Vector2((i - (hills - 1) * 0.5) * 24.0, sin(i * 1.9) * 7.0)
				tries.append([&"hills", at + off.rotated(turn * 0.4), 28.0 + dice.randf() * 8.0])
		&"village":
			var homes: int = many.call(3, 5)
			for i: int in homes + 2:
				var off := (
					Vector2.from_angle(TAU * i / (homes + 2) + turn) * (18.0 + dice.randf() * 18.0)
				)
				tries.append([&"house" if i < homes else &"wood", at + off, 24.0])
		&"casinos", &"palms", &"cones", &"houses":
			var rows := {
				&"casinos": [&"casino", 2, 3, 31.0, 30.0],
				&"palms": [&"palm", 3, 5, 22.0, 28.0],
				&"cones": [&"cone", 3, 5, 17.0, 22.0],
				&"houses": [&"house", 2, 3, 26.0, 24.0]
			}
			var spec: Array = rows[kind]
			var count: int = many.call(spec[1], spec[2])
			for i: int in count:
				var off := Vector2((i - (count - 1) * 0.5) * spec[3], sin(i * 1.3) * 3.0)
				tries.append([spec[0], at + off.rotated(turn * 0.5), spec[4]])
		&"table":
			tries.append([&"chips", at, 28.0])
			tries.append([&"dice", at + Vector2(24.0, 6.0).rotated(turn), 20.0])
			tries.append([&"dice", at + Vector2(-22.0, 8.0).rotated(turn), 18.0])
		&"grove":
			for i: int in many.call(2, 4):
				tries.append([&"wood", at + Vector2.from_angle(TAU * i / 4.0 + turn) * 15.0, 24.0])
		&"depot":
			tries.append([&"parking", at, 30.0])
			tries.append([&"tower", at + Vector2(30.0, -6.0).rotated(turn * 0.3), 28.0])
			tries.append([&"tires", at + Vector2(-26.0, 6.0).rotated(turn * 0.3), 22.0])
		&"stars":
			for i: int in many.call(3, 4):
				var off := Vector2.from_angle(dice.randf() * TAU) * (12.0 + dice.randf() * 22.0)
				tries.append([&"doodle_star", at + off, 16.0 + dice.randf() * 10.0])
		&"scribble":
			tries.append([&"spiral", at, 28.0])
			tries.append([&"question", at + Vector2(26.0, -4.0), 24.0])
		&"pointer":
			tries.append([&"arrow", at, 30.0])
			tries.append([&"question", at + Vector2(-26.0, 2.0), 24.0])
	return tries


## Lays a group of [param kind] in [param district] round [param at]: each of its drawings where
## it is clear of everything laid before the group, in the group's own district, and not too near
## another of it; taken once it is laid, and kept to be named. A wood laid a tint of green under it.
func _group(kind: StringName, district: int, at: Vector2, seed: String) -> void:
	var laid: Array[Dictionary] = []
	var named := _name_group(kind, at, seed)
	var tries := _tries(kind, at, seed)
	for i: int in tries.size():
		var each: Array = tries[i]
		var spot: Vector2 = each[1]
		var size: float = each[2]
		if not inside(spot) or is_taken(spot, size * 0.36) or _district_at(spot) != district:
			continue
		var near := false
		for other: Dictionary in laid:
			near = (
				near
				or (other["at"] as Vector2).distance_to(spot) < (size + other["size"]) * 0.5 * PACK
			)
		if near:
			continue
		var upright: bool = (
			each[0] in [&"wood", &"pine", &"house", &"barn", &"tower", &"casino", &"palm"]
		)
		var turn := sin(float(i) * 2.7 + float(hash(seed) % 97)) * (0.07 if upright else 0.3)
		laid.append({"kind": each[0], "at": spot, "size": size, "turn": turn})
	if named != "" and laid.size() < NAMED_LEAST:
		# Too little came of it to carry a name: the name to the next of its kind.
		layout.places.pop_back()
		_names[kind].push_front(named)
	if laid.size() < mini(2, tries.size()):
		return
	var points := PackedVector2Array()
	for each: Dictionary in laid:
		layout.doodles.append(each)
		points.append(each["at"])
	for each: Dictionary in laid:
		take(each["at"], each["size"] * 0.5)
	if kind == &"woods" and points.size() >= 4:
		var hull := Geometry2D.convex_hull(points)
		var grown := LoyaltyMapLayout.largest(
			Geometry2D.offset_polygon(hull, 16.0, Geometry2D.JOIN_ROUND)
		)
		if grown.size() >= 3:
			layout.woods.append(LoyaltyMapLayout.by_hand(grown, seed, 6.0, 12.0))


## The name of a group of [param kind] round [param at], where it is one of the House's places
## with a name and the dice say it is to have it: put down before the group is, so its drawings
## keep clear of it, across a wood's middle as a map names one and under a farm or a row of hills.
## Empty where it has none.
func _name_group(kind: StringName, at: Vector2, seed: String) -> String:
	var left: Array = _names.get(kind, [])
	if layout.sheet != LoyaltyMapLayout.Sheet.HOUSE or left.is_empty():
		return ""
	if _roll(seed + "named") > NAMED:
		return ""
	var under := Vector2(0.0, 8.0 if kind == &"woods" else 40.0)
	if not name_place(left[0], at + under, false):
		return ""
	return left.pop_front()


## The odd drawing on its own between the groups, on a lattice of its own, its district's kind or
## the country's.
func _lay_strays() -> void:
	var inside := Rect2(Vector2.ONE * 60.0, layout.paper - Vector2.ONE * 120.0)
	var y := inside.position.y
	while y < inside.end.y:
		var x := inside.position.x
		while x < inside.end.x:
			var seed := "%d,%d" % [roundi(x), roundi(y)]
			x += STRAY_STEP
			# The dice first, the most any place gets, before the rest is worked out.
			var keep := _roll(seed + "keep")
			if keep >= STRAYS * 2.0:
				continue
			var at := Vector2(x - STRAY_STEP, y)
			at += Vector2(_wobble(seed + "a"), _wobble(seed + "b")) * 18.0
			var district := _district_at(at)
			var chance := STRAYS * (2.0 if district >= 0 else 1.0)
			if layout.sheet == LoyaltyMapLayout.Sheet.KIT and district < 0:
				chance = 0.0
			var size := 28.0 + _wobble(seed + "size") * 5.0
			if keep >= chance or is_taken(at, size * 0.5):
				continue
			var kinds: Array = STRAYS_OF[district if district >= 0 else -1]
			var kind: StringName = kinds[posmod(hash(seed + "kind"), kinds.size())]
			var turn := _wobble(seed + "turn") * 0.12
			layout.doodles.append({"kind": kind, "at": at, "size": size, "turn": turn})
			take(at, size * 0.55)
		y += STRAY_STEP * 0.86


## Whether [param at] is inside the paper's rule, a way in from its edge.
func inside(at: Vector2) -> bool:
	return Rect2(Vector2.ONE * 50.0, layout.paper - Vector2.ONE * 100.0).has_point(at)


## The slow swell over the paper the country's groups gather where it is high: nothing over half of
## it, and the other half rising to most.
static func _swell(at: Vector2) -> float:
	var rise := (
		sin(at.x * SWELL * TAU + 1.3) * cos(at.y * SWELL * 1.3 * TAU - 0.7)
		+ sin((at.x + at.y) * SWELL * 2.1 * TAU) * 0.5
	)
	return clampf(rise, 0.0, 1.0)


## The district whose wash [param at] is in, -1 for none; the box round each wash tried first.
func _district_at(at: Vector2) -> int:
	if _boxes.is_empty():
		for district: int in layout.washes:
			var low := Vector2(INF, INF)
			var high := -low
			for point: Vector2 in layout.washes[district]:
				low = low.min(point)
				high = high.max(point)
			_boxes[district] = Rect2(low, high - low)
	for district: int in layout.washes:
		var box: Rect2 = _boxes[district]
		if box.has_point(at) and Geometry2D.is_point_in_polygon(at, layout.washes[district]):
			return district
	return -1


static func middle_of(points: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for point: Vector2 in points:
		sum += point
	return sum / maxf(float(points.size()), 1.0)


## Takes the places [param radius] round every point of [param line], into [param also] as well
## as everything taken: the roads into [member road], the rest into [member solid].
func take_line(line: PackedVector2Array, radius: float, also: Variant = null) -> void:
	for i: int in range(1, line.size()):
		var steps := maxi(int(line[i - 1].distance_to(line[i]) / 12.0), 1)
		for k: int in steps + 1:
			take(line[i - 1].lerp(line[i], float(k) / float(steps)), radius, also)


func take(at: Vector2, radius: float, also: Variant = null) -> void:
	take_rect(Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), also)


## Takes every place [param rect] covers, into [param also] as well, [member solid] where none is
## named.
func take_rect(rect: Rect2, also: Variant = null) -> void:
	var into: Dictionary = also if also != null else solid
	var low := (rect.position / CLEAR).floor()
	var high := (rect.end / CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			taken[Vector2i(x, y)] = true
			into[Vector2i(x, y)] = true


## Whether any place a drawing [param radius] round [param at] would cover is taken.
func is_taken(at: Vector2, radius: float) -> bool:
	return is_rect_taken(Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))


func is_rect_taken(rect: Rect2) -> bool:
	var low := (rect.position / CLEAR).floor()
	var high := (rect.end / CLEAR).floor()
	for x: int in range(int(low.x), int(high.x) + 1):
		for y: int in range(int(low.y), int(high.y) + 1):
			if taken.has(Vector2i(x, y)):
				return true
	return false
