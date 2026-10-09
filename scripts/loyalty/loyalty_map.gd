class_name LoyaltyMap
extends Resource
## The loyalty program's map, GAME.md 8.9: its landmarks and the roads between them. Two landmarks
## joined by a road open each other: winning either opens the other, see [Loyalty].
##
## Drawn as a grid of characters, the way the arenas of 6.3 are, so a landmark is added by drawing
## it in and giving it a line: each landmark's [member LoyaltyLandmark.mark] where it stands, the
## house's roads in ink and Kit's in pencil, bends and crossings, and the roundabout. The roads are
## read off the grid: a run of road from one landmark to another joins them, through any bend or
## crossing on the way, a road that reaches the roundabout leads there, and one that runs off an
## edge of the grid leads off the map, as the slip road comes onto it.

## A road across, and up and down, in the house's ink.
const INK_ACROSS := "-"
const INK_DOWN := "|"
## A bend or a crossing with no landmark on it: every road meeting there is joined.
const BEND := "+"
## A road across, and up and down, in pencil, off the books.
const PENCIL_ACROSS := "."
const PENCIL_DOWN := ":"
## The roundabout in the middle, round the pot.
const ROUNDABOUT := "@"

const _ACROSS := [Vector2i.LEFT, Vector2i.RIGHT]
const _DOWN := [Vector2i.UP, Vector2i.DOWN]
const _ALL := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## The map drawn as a grid of characters, a row a line.
@export_multiline var grid := ""
## Every landmark on the map.
@export var landmarks: Array[LoyaltyLandmark] = []

## The landmarks by id, and each one's roads, the ids it is joined to, worked out once.
var _by_id: Dictionary[StringName, LoyaltyLandmark] = {}
var _roads: Dictionary[StringName, Array] = {}
## Where each landmark stands on the grid, which lead to the roundabout, and what is wrong with the
## grid, read once.
var _at: Dictionary[StringName, Vector2i] = {}
var _to_roundabout: Array[StringName] = []
var _problems := PackedStringArray()
var _read := false
var _rows := PackedStringArray()
## Every run of road on the grid as it was read, see [method runs].
var _runs: Array[Dictionary] = []


## The landmark [param id], or null for one this map does not have.
func landmark(id: StringName) -> LoyaltyLandmark:
	_index()
	return _by_id.get(id)


## The ids of the landmarks [param id] has a road to.
func roads_of(id: StringName) -> Array[StringName]:
	_read_grid()
	var joined: Array[StringName] = []
	joined.assign(_roads.get(id, []))
	return joined


## A road between [param a] and [param b], which open each other.
func join(a: StringName, b: StringName) -> void:
	_read_grid()
	if a == b:
		return
	for pair: Array in [[a, b], [b, a]]:
		var roads: Array = _roads.get(pair[0], [])
		if pair[1] not in roads:
			roads.append(pair[1])
		_roads[pair[0]] = roads


## Where [param id] stands on the grid, a column and a row; (-1, -1) for one not drawn.
func at(id: StringName) -> Vector2i:
	_read_grid()
	return _at.get(id, Vector2i(-1, -1))


## Whether a road from [param id] leads to the roundabout.
func reaches_roundabout(id: StringName) -> bool:
	_read_grid()
	return id in _to_roundabout


## Every run of road on the grid, for drawing it: a dictionary each, its `cells`, the landmarks
## at its `ends` by id, whether it reaches the `roundabout`, whether it runs `off_the_map`, and
## whether it is drawn in `pencil`.
func runs() -> Array[Dictionary]:
	_read_grid()
	return _runs


## The cells the road from [param from] to [param to] runs through, the two landmarks' own at its
## ends, for driving it; none for two with no road between them. The road is the run of road that
## joins them, through any bend or crossing on the way and past no other landmark.
func path(from: StringName, to: StringName) -> Array[Vector2i]:
	_read_grid()
	var cells: Array[Vector2i] = []
	var start: Vector2i = _at.get(from, Vector2i(-1, -1))
	var goal: Vector2i = _at.get(to, Vector2i(-1, -1))
	if start.x < 0 or goal.x < 0 or to not in roads_of(from):
		return cells
	var came := {start: start}
	var next: Array[Vector2i] = [start]
	while not next.is_empty() and not came.has(goal):
		var here: Vector2i = next.pop_front()
		for step: Vector2i in _ALL if here == start else _ways(cell(here)):
			var there := here + step
			var what := cell(there)
			var onward := _is_road(what) and step in _ways(what)
			if not came.has(there) and (there == goal or onward):
				came[there] = here
				next.append(there)
	if not came.has(goal):
		return cells
	cells.append(goal)
	while cells[0] != start:
		cells.push_front(came[cells[0]])
	return cells


## How big the grid is, its widest row and its rows.
func size() -> Vector2i:
	_read_grid()
	var widest := 0
	for row: String in _rows:
		widest = maxi(widest, row.length())
	return Vector2i(widest, _rows.size())


## The character at [param cell] of the grid: a space off its edges.
func cell(at_cell: Vector2i) -> String:
	_read_grid()
	if at_cell.y < 0 or at_cell.y >= _rows.size() or at_cell.x < 0:
		return " "
	var row := _rows[at_cell.y]
	return row[at_cell.x] if at_cell.x < row.length() else " "


## What is wrong with the map, a line each, none for a map that holds together: a character with
## no landmark, a landmark not drawn or drawn twice, two landmarks alike, a road going nowhere, a
## landmark no road reaches from where a district opens, a keystone of the house's with no road to
## the roundabout.
func problems() -> PackedStringArray:
	_read_grid()
	var found := _problems.duplicate()
	_index()
	var ids := {}
	var marks := {}
	for each: LoyaltyLandmark in landmarks:
		if ids.has(each.id):
			found.append("Two landmarks are called %s." % each.id)
		ids[each.id] = true
		if marks.has(each.mark):
			found.append("Two landmarks are drawn as %s." % each.mark)
		marks[each.mark] = true
		if not _at.has(each.id) and not grid.is_empty():
			found.append("%s is not drawn on the grid." % each.id)
		var house := each.district != LoyaltyLandmark.District.OFF_THE_BOOKS
		if each.keystone and house and not reaches_roundabout(each.id):
			found.append("The keystone %s has no road to the roundabout." % each.id)
	for id: StringName in _unreached():
		found.append("No road reaches %s." % id)
	return found


func _index() -> void:
	if _by_id.size() == landmarks.size():
		return
	_by_id.clear()
	for each: LoyaltyLandmark in landmarks:
		_by_id[each.id] = each


## The landmarks no road reaches from a landmark open from the start of its district.
func _unreached() -> Array[StringName]:
	var reached: Array[StringName] = []
	var next: Array[StringName] = []
	for each: LoyaltyLandmark in landmarks:
		if each.entry:
			next.append(each.id)
	while not next.is_empty():
		var id: StringName = next.pop_back()
		if id in reached:
			continue
		reached.append(id)
		next.append_array(roads_of(id))
	var unreached: Array[StringName] = []
	for each: LoyaltyLandmark in landmarks:
		if each.id not in reached:
			unreached.append(each.id)
	return unreached


## Reads the landmarks' places and the roads off [member grid], once.
func _read_grid() -> void:
	if _read:
		return
	_read = true
	if grid.is_empty():
		return
	_rows = grid.split("\n")
	var by_mark := {}
	for each: LoyaltyLandmark in landmarks:
		by_mark[each.mark] = each.id
	var seen := {}
	for y: int in _rows.size():
		for x: int in _rows[y].length():
			var here := _rows[y][x]
			if by_mark.has(here):
				var id: StringName = by_mark[here]
				if _at.has(id):
					_problems.append("%s is drawn twice." % id)
				_at[id] = Vector2i(x, y)
			elif not _is_road(here) and here != ROUNDABOUT and here != " ":
				_problems.append("Nothing is drawn as %s, at %d, %d." % [here, x, y])
	for y: int in _rows.size():
		for x: int in _rows[y].length():
			var start := Vector2i(x, y)
			if _is_road(cell(start)) and not seen.has(start):
				_follow(start, seen, by_mark)


## Follows the road from [param start] as far as it goes, every cell of it into [param seen], and
## joins every landmark at its ends; one that also reaches the roundabout leads there.
func _follow(start: Vector2i, seen: Dictionary, by_mark: Dictionary) -> void:
	var ends: Array[StringName] = []
	var roundabout := false
	var off_the_map := false
	var bounds := Rect2i(Vector2i.ZERO, size())
	var next: Array[Vector2i] = [start]
	var cells: Array[Vector2i] = [start]
	var pencil := false
	seen[start] = true
	while not next.is_empty():
		var here: Vector2i = next.pop_back()
		var road := cell(here)
		pencil = pencil or road in [PENCIL_ACROSS, PENCIL_DOWN]
		for step: Vector2i in _ways(road):
			var there := here + step
			var what := cell(there)
			if not bounds.has_point(there):
				# A road runs on off the edge; a bend only turns where there is road to turn into.
				off_the_map = off_the_map or road != BEND
			elif by_mark.has(what):
				if by_mark[what] not in ends:
					ends.append(by_mark[what])
			elif what == ROUNDABOUT:
				roundabout = true
			elif _is_road(what) and step in _ways(what) and not seen.has(there):
				seen[there] = true
				next.append(there)
				cells.append(there)
	(
		_runs
		. append(
			{
				"cells": cells,
				"ends": ends,
				"roundabout": roundabout,
				"off_the_map": off_the_map,
				"pencil": pencil,
			}
		)
	)
	if ends.size() + (1 if roundabout else 0) + (1 if off_the_map else 0) < 2:
		_problems.append("A road at %d, %d goes nowhere." % [start.x, start.y])
	for a: StringName in ends:
		for b: StringName in ends:
			if a != b:
				var roads: Array = _roads.get(a, [])
				if b not in roads:
					roads.append(b)
				_roads[a] = roads
		if roundabout and a not in _to_roundabout:
			_to_roundabout.append(a)


## The ways a road drawn as [param what] runs.
static func _ways(what: String) -> Array:
	match what:
		INK_ACROSS, PENCIL_ACROSS:
			return _ACROSS
		INK_DOWN, PENCIL_DOWN:
			return _DOWN
		BEND:
			return _ALL
	return []


static func _is_road(what: String) -> bool:
	return what in [INK_ACROSS, INK_DOWN, BEND, PENCIL_ACROSS, PENCIL_DOWN]


## The ways a road drawn as [param what] runs on the grid.
static func ways(what: String) -> Array:
	match what:
		INK_ACROSS, PENCIL_ACROSS:
			return [Vector2i.LEFT, Vector2i.RIGHT]
		INK_DOWN, PENCIL_DOWN:
			return [Vector2i.UP, Vector2i.DOWN]
		BEND:
			return [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	return []
