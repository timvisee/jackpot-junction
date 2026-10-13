class_name AchievementToasts
extends CanvasLayer
## Where every achievement earned at this machine comes up, GAME.md 8.10, on whatever screen the
## game is on: one [AchievementToast] at a time, the rest waiting their turn. Hung under [Game]
## once, so it outlives the scenes, and never in a run nobody watches. In a room a toast goes into
## the room's HUD beside the corner of the seat that earned it; anywhere else onto this layer, over
## the dialogs and under the loading screen.

## Over the dialogs, 25, and the notices, 40; under the loading screen, 100.
const LAYER := 45
const GROUP := Achievements.TOAST_LAYERS

## What is waiting to come up: the profile's id, the achievement's and the seat's, or a count.
var _waiting: Array[Dictionary] = []
var _up: AchievementToast


func _ready() -> void:
	layer = LAYER
	add_to_group(GROUP)
	Events.achievement_earned.connect(_on_earned)
	# The first seat's, so in a room they come up beside its corner.
	for id: String in Achievements.toasts_due:
		_on_earned(Game.settings.profile.id, StringName(id), 0)
	Achievements.toasts_due.clear()


func _exit_tree() -> void:
	if Events.achievement_earned.is_connected(_on_earned):
		Events.achievement_earned.disconnect(_on_earned)


## The one toast saying how many achievements [param profile] was credited at once, GAME.md 8.10,
## Earned already; called through the group, see [method Achievements.arrive].
func credited(profile: Profile, earned: Array[Achievement]) -> void:
	if earned.is_empty():
		return
	_waiting.append({"count": earned.size(), "shown": earned[-1], "profile": profile.id})


func _on_earned(profile_id: String, id: StringName, slot: int) -> void:
	_waiting.append({"profile": profile_id, "id": id, "slot": slot})


func _process(_delta: float) -> void:
	# The ending's last lines have the screen to themselves: what is up waits out of sight, and
	# nothing more comes up, STORY.md 8.5.
	visible = get_tree().get_nodes_in_group(LastLines.GROUP).is_empty()
	if _up != null and is_instance_valid(_up):
		_up.visible = visible
		return
	if not visible or get_tree().get_first_node_in_group(LoadingScreen.GROUP) != null:
		return
	_up = null
	while not _waiting.is_empty() and _up == null:
		_up = _show(_waiting.pop_front())


func _show(next: Dictionary) -> AchievementToast:
	if next.has("count"):
		var counted := AchievementToast.counting(int(next["count"]), next["shown"])
		add_child(counted)
		return counted
	var earned := Achievements.find(StringName(next["id"]))
	if earned == null:
		return null
	var hud := _hud()
	var block: Control = null
	var slot := int(next["slot"])
	# Beside the seat's corner while the room is being played in; over the payout slip, or a HUD
	# stood down, at the top right as anywhere else.
	var playing := (
		hud != null
		and hud.visible
		and not hud.dismissed
		and hud.match_node != null
		and hud.match_node.state != Match.State.RESULTS
	)
	if playing and slot >= 0:
		block = hud.get_node_or_null("Block%d" % slot) as Control
	var toast := AchievementToast.of(earned, _named(str(next["profile"])), block)
	if block != null:
		hud.add_child(toast)
	else:
		add_child(toast)
	return toast


## The name on a toast: none for the profile playing, whose screen it is, and the profile's own for
## one sat in at another seat.
static func _named(profile_id: String) -> String:
	var settings := Game.settings
	if settings == null or settings.profile == null or settings.profile.id == profile_id:
		return ""
	for seat: int in range(1, settings.linked.size()):
		var sat := settings.seat_profile(seat)
		if sat != null and sat.id == profile_id:
			return sat.display_name()
	return ""


## The HUD of the room the game is in, if it is in one: found through the room's records, which
## every room that counts has.
func _hud() -> MatchHud:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for record: Node in get_tree().get_nodes_in_group(MatchRecord.GROUP):
		var room := record.get(&"match_node") as Match
		if room != null and is_instance_valid(room) and scene.is_ancestor_of(room):
			return room.hud
	return null
