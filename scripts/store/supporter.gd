class_name Supporter
extends RefCounted
## The supporter pack, GAME.md 10.8: a Steam DLC a player buys to say thank you for a game that is
## free, which lets its pieces of dress be worn. The pieces are in every build and show on anybody's
## kart; this says whether the ones here may be worn, on Steam's word, asked at every start and
## never saved, and whether they are offered at all, which they are in a Steam build and in no
## other. A debug build can pretend either way: `--supporter` as if the pack were owned, and
## `--supporter=locked` as a Steam build without it, the pieces offered and locked.
##
## It names nothing of the game's, only keeps what [Store] found at the start, since the dress asks
## it and the dress is under everything: naming the store from here pulled the store's own
## dependencies under the dress, round in a loop.

enum Pretend { NONE, OWNED, LOCKED }

## How a debug build pretends, see [method start].
static var pretend := Pretend.NONE
## What the store said at the start: whether the pack is owned, and whether this is a Steam build.
static var _owned := false
static var _steam_build := false


## Keeps what the store found at the start, [param owned] whether the pack is owned and
## [param steam_build] whether this is a Steam build, and reads `--supporter` and
## `--supporter=locked` among [param args], the game's own arguments, in a debug build only.
static func start(args: PackedStringArray, owned_now: bool, steam_build: bool) -> void:
	_owned = owned_now
	_steam_build = steam_build
	pretend = Pretend.NONE
	if not OS.is_debug_build():
		return
	for arg: String in args:
		if arg == "--supporter":
			pretend = Pretend.OWNED
		elif arg == "--supporter=locked":
			pretend = Pretend.LOCKED


## Whether the pack's pieces may be worn here: Steam said at the start that the account owns it, or
## a debug build pretends so.
static func owned() -> bool:
	match pretend:
		Pretend.OWNED:
			return true
		Pretend.LOCKED:
			return false
	return _owned


## Steam's word again, for when the pack may have been bought while the game runs.
static func set_owned(owned_now: bool) -> void:
	_owned = owned_now


## Whether the pack's pieces are offered here at all: in a Steam build, owned or not, and in a debug
## build pretending either way; never in a GitHub build.
static func offered() -> bool:
	return pretend != Pretend.NONE or _steam_build
