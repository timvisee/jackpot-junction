class_name FakeSteam
extends RefCounted
## Steam as the tests see it, GAME.md 10.8: the GodotSteam methods [SteamStore] calls, by
## GodotSteam's own names, answering as Steam would and keeping what it was told, so that no test
## ever talks to the real thing.

# gdlint: disable=function-name

## What starting answers, [constant SteamStore.STARTED] or why not.
var status := SteamStore.STARTED
## Whether Steam would rather start the game itself.
var restarts := false
var account := 76561197960287930
var persona := "Ann"
## Every call made, its name and arguments, oldest first.
var calls: Array[String] = []
## The achievements the app has on Steamworks, by name; empty for an app that takes any.
var known: Array[String] = []
## Whether Steam takes nothing yet, as while it is still reading the account at the start.
var busy := false
var achieved: Dictionary[String, bool] = {}
var stats: Dictionary[String, int] = {}
## How many times it was asked to keep what it was told.
var stores := 0
## Its rich presence, key by key.
var presence: Dictionary[String, String] = {}


func restartAppIfNecessary(app_id: int) -> bool:
	calls.append("restartAppIfNecessary %d" % app_id)
	return restarts


func steamInitEx(app_id: int, embed_callbacks: bool) -> Dictionary:
	calls.append("steamInitEx %d %s" % [app_id, embed_callbacks])
	return {"status": status, "verbal": "" if status == SteamStore.STARTED else "No Steam here"}


func getSteamID() -> int:
	return account


func getPersonaName() -> String:
	return persona


func setAchievement(achievement_name: String) -> bool:
	calls.append("setAchievement %s" % achievement_name)
	if busy or (not known.is_empty() and achievement_name not in known):
		return false
	achieved[achievement_name] = true
	return true


func getAchievement(achievement_name: String) -> Dictionary:
	var there := known.is_empty() or achievement_name in known
	return {"ret": there, "achieved": achieved.get(achievement_name, false)}


func setStatInt(stat_name: String, value: int) -> bool:
	calls.append("setStatInt %s %d" % [stat_name, value])
	if busy:
		return false
	stats[stat_name] = value
	return true


func getStatInt(stat_name: String) -> int:
	return stats.get(stat_name, 0)


func storeStats() -> bool:
	stores += 1
	return true


func getNumAchievements() -> int:
	return known.size()


func getAchievementName(achievement_index: int) -> String:
	return known[achievement_index]


func resetAllStats(_achievements_too: bool) -> bool:
	achieved.clear()
	stats.clear()
	return true


func setRichPresence(key: String, value: String) -> bool:
	calls.append("setRichPresence %s %s" % [key, value])
	if value.is_empty():
		presence.erase(key)
	else:
		presence[key] = value
	return true


func clearRichPresence() -> void:
	presence.clear()
