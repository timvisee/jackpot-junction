class_name AchievementList
extends Resource
## Every achievement of GAME.md 8.10 in the order the list shows them, group by group, read from
## `data/achievements/list.tres`, so one is added with a line there.

@export var achievements: Array[Achievement] = []
