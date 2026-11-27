class_name ViewChoices
extends RefCounted
## The choices a player makes about how a match is seen, GAME.md 8.2 and 8.5, kept in [Settings]:
## what it is played on, who the camera keeps in the picture, and the rings under the karts.

## What the game is played on, GAME.md 8.5, which Auto suits the camera to: a desk's screen an
## arm's length away, a television across the room, or a handheld; and the UI scale each starts at.
const SCREEN_DESK := "desk"
const SCREEN_TV := "tv"
const SCREEN_HANDHELD := "handheld"
const SCREENS: Array[String] = [SCREEN_DESK, SCREEN_TV, SCREEN_HANDHELD]
## What the Video page calls each, shown through tr().
const SCREEN_NAMES: Array[String] = ["Desk", "TV", "Handheld"]
const SCREEN_UI_SCALES: Array[float] = [1.0, 1.25, 1.5]
## Steam's word on its own machines, GodotSteam's `SteamHardwareType`, see
## [constant SteamStore.NOT_STEAM_HARDWARE]: a Steam Deck and a Steam Machine. Numbers of its own
## here rather than [SteamStore]'s: naming that class, or [Settings], from this one, which the
## camera and the match read, closed a loop of preloads that broke an exported build.
const STEAM_DECK := 1
const STEAM_MACHINE := 2
## Who the camera keeps in the picture, GAME.md 8.2: as suits the screen, every kart, the karts
## driven here and the rivals near them, or the karts driven here alone.
const FOLLOW_AUTO := "auto"
const FOLLOW_EVERYONE := "everyone"
const FOLLOW_NEARBY := "nearby"
const FOLLOW_MINE := "mine"
const FOLLOWS: Array[String] = [FOLLOW_AUTO, FOLLOW_EVERYONE, FOLLOW_NEARBY, FOLLOW_MINE]
## The rings under the karts, GAME.md 8.5: none, under the karts driven here, or under every kart.
const RINGS_OFF := "off"
const RINGS_HERE := "here"
const RINGS_ALL := "all"
const RINGS: Array[String] = [RINGS_OFF, RINGS_HERE, RINGS_ALL]
## The arrows at the edge of the screen pointing at a rival out of the picture, GAME.md 8.2: none,
## faint, or as bold as those at the karts driven here.
const RIVAL_ARROWS_OFF := "off"
const RIVAL_ARROWS_FAINT := "faint"
const RIVAL_ARROWS_FULL := "full"
const RIVAL_ARROWS: Array[String] = [RIVAL_ARROWS_OFF, RIVAL_ARROWS_FAINT, RIVAL_ARROWS_FULL]


## What a machine is played on until its player says, GAME.md 8.5: a phone or a tablet in the hand,
## anything else at a desk.
static func default_screen() -> String:
	return SCREEN_HANDHELD if OS.has_feature("mobile") else SCREEN_DESK


## What a machine is played on at its first start, GAME.md 8.5: on Steam's own, what it is,
## [param hardware] Steam's word on it, see [constant STEAM_DECK]: a Steam Deck
## in the hand, as it is too where SteamOS says so, [param on_deck], in a build without Steam; a
## Steam Machine under a television. Anywhere else, see [method default_screen].
static func first_screen(hardware: int, on_deck: bool) -> String:
	if hardware == STEAM_DECK or on_deck:
		return SCREEN_HANDHELD
	if hardware == STEAM_MACHINE:
		return SCREEN_TV
	return default_screen()


## The UI scale [param screen], one of [constant SCREENS], starts at, see
## [constant SCREEN_UI_SCALES].
static func ui_scale_of(screen: String) -> float:
	return SCREEN_UI_SCALES[maxi(SCREENS.find(screen), 0)]


## The UI scale drawn just now: a size being tried on the Video page, or the one kept.
static func ui_scale_now() -> float:
	return Settings.ui_scale_for_now if Settings.ui_scale_for_now > 0.0 else Game.settings.ui_scale


## The window the game is played in, in the system's own points: its size on the screen, not the
## 1920 by 1080 the menus and the HUD are laid out in, which every window is stretched to and so
## says nothing of how big it is. Zero where there is no window, as in a test.
static func screen_now() -> Vector2:
	return Vector2(DisplayServer.window_get_size()) / maxf(DisplayServer.screen_get_scale(), 1.0)


## Whether a window [param screen] points across, see [method screen_now], is a small one to play
## on, GAME.md 8.5: a handheld, a television across the room, a small window, or anywhere the UI is
## drawn bigger than it was laid out, which is somebody saying the screen is hard to read.
static func small_screen(screen: Vector2) -> bool:
	if Game.settings.screen != SCREEN_DESK or OS.has_feature("mobile"):
		return true
	return _small_window(screen) or ui_scale_now() > 1.0


## Whether [param screen] is a window under 760 points down or across; not one of no size at all.
static func _small_window(screen: Vector2) -> bool:
	var side := minf(screen.x, screen.y)
	return side > 0.0 and side < 760.0


## What Auto settles the camera's distance on for a window [param screen] points across, GAME.md
## 8.5, as a share of the fit, for the camera and for the Video page to show in brackets: the bigger
## the UI, the smaller the screen and the further away it is watched from, the closer it comes in;
## a wide desktop sits a little further back.
static func auto_distance(screen: Vector2) -> float:
	var factor := 0.8 - maxf(ui_scale_now() - 1.0, 0.0) * 0.35
	if Game.settings.screen == SCREEN_TV:
		factor -= 0.12
	elif Game.settings.screen == SCREEN_HANDHELD:
		factor -= 0.05
	elif OS.has_feature("mobile") or _small_window(screen):
		factor -= 0.05
	return clampf(factor, 0.52, 0.9)


## Who the camera keeps in the picture for a window [param screen] points across, GAME.md 8.2: as
## chosen, or with Auto every kart at a desk, and on a small screen, see [method small_screen],
## where every kart in the picture is a kart too small to make out, the karts driven here and the
## rivals near them. Never the karts driven here alone, which on a television across the room
## followed one kart so close the table was lost round it: that only where it is chosen.
static func follows(screen: Vector2) -> String:
	var chosen := Game.settings.camera_follows
	return follows_auto(screen) if chosen == FOLLOW_AUTO else chosen


## Whom Auto follows in a window [param screen] points across, see [method follows].
static func follows_auto(screen: Vector2) -> String:
	return FOLLOW_NEARBY if small_screen(screen) else FOLLOW_EVERYONE
