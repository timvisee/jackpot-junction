class_name SupporterWatch
extends Node
## The Steam supporter pack bought while the game runs, GAME.md 10.8. Steam is asked again whenever
## a DLC is installed and whenever its overlay closes, see [method Store.recheck_supporter], and the
## moment the pack turns owned while a menu is up, the title or the settings, with the kart dialog
## over either or not, its thank-you card comes up over it at once rather than at the next visit to
## the title, see [method thank]. In a match it waits for the title, as it always has. Added by
## [Game] in a build that offers the pack.

## The screens that are menus, where the card may come up at once.
const MENUS: Array[String] = [Game.TITLE_SCENE, Game.SETTINGS_SCENE]

## Whether the pack was owned when last looked at.
var _owned := false


func _ready() -> void:
	name = "SupporterWatch"
	_owned = Supporter.owned()


func _process(_delta: float) -> void:
	var now := Supporter.owned()
	if now == _owned:
		return
	_owned = now
	if now:
		thank(get_tree().current_scene)


## The thank-you card over [param scene], started at once, where it is a menu, the card is due and
## it is not up there already; else null.
static func thank(scene: Node) -> SupporterThanks:
	var menu := scene as Control
	if menu == null or menu.scene_file_path not in MENUS or not SupporterThanks.due():
		return null
	if menu.find_child("SupporterThanks", true, false) != null:
		return null
	var thanks := SupporterThanks.over(menu)
	if thanks != null:
		thanks.start()
	return thanks
