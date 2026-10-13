class_name AchievementState
extends RefCounted
## One profile's achievements, GAME.md 8.10: which it has earned and when, and which of them the
## list has not shown it yet, kept in a section of its own in the profile's file. Earned through
## [method Achievements.earn]; nothing of it goes over the wire.
##
## Kept by id. An id this version does not know, one a newer version has, is kept as it is and never
## shown or counted, so no record is lost to a version.

const SECTION := "achievements"

## When each achievement was earned, by its id, in seconds since the Unix epoch.
var earned: Dictionary[StringName, int] = {}
## Those earned that the list has not shown under its cursor yet, which wear a NEW tag there.
var fresh := PackedStringArray()
## Whether what the profile's records already held has been counted for it, GAME.md 8.10, Earned
## already: false for a profile from before achievements until the title has come up with it.
var credited := false


func read(file: ConfigFile) -> void:
	earned = {}
	var kept: Variant = file.get_value(SECTION, "earned", {})
	if kept is Dictionary:
		for key: Variant in kept:
			var when: Variant = kept[key]
			if (key is String or key is StringName) and (when is int or when is float):
				earned[StringName(key)] = int(when)
	fresh = PackedStringArray()
	var listed: Variant = file.get_value(SECTION, "fresh", PackedStringArray())
	if listed is PackedStringArray or listed is Array:
		for id: Variant in listed:
			if has(StringName(str(id))) and str(id) not in fresh:
				fresh.append(str(id))
	credited = bool(file.get_value(SECTION, "credited", false))


func write(file: ConfigFile) -> void:
	var plain := {}
	for id: StringName in earned:
		plain[String(id)] = earned[id]
	file.set_value(SECTION, "earned", plain)
	file.set_value(SECTION, "fresh", fresh)
	file.set_value(SECTION, "credited", credited)


## Whether [param id] has been earned.
func has(id: StringName) -> bool:
	return earned.has(id)


## [param id] earned at [param when]. True the first time; earned once, it is never earned again.
func earn(id: StringName, when: int) -> bool:
	if id == &"" or has(id):
		return false
	earned[id] = when
	if String(id) not in fresh:
		fresh.append(String(id))
	return true


## Whether [param id] was earned since the list last showed it.
func is_fresh(id: StringName) -> bool:
	return String(id) in fresh


## The list has shown [param id] under its cursor. True if it was fresh until now.
func look_at(id: StringName) -> bool:
	var at := fresh.find(String(id))
	if at < 0:
		return false
	fresh.remove_at(at)
	return true


## When [param id] was earned, in seconds since the Unix epoch, or 0 for one not earned.
func when(id: StringName) -> int:
	return earned.get(id, 0)
