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
