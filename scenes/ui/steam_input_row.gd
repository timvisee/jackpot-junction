class_name SteamInputRow
extends RefCounted
## The Controls page's rows for Steam Input, GAME.md 10.8, in a game with Steam on alone: its
## switch, which reads the controllers through Steam or leaves them to the game, and the way to
## Steam's own settings for the layout of the controller in hand.

const SWITCH := "Steam Input"
const LAYOUT_ROW := "Controller layout"
const LAYOUT := "Change in Steam"
const TIP := (
	"On, Steam reads your controllers, each with the layout you pick for it in Steam. Off, the game"
	+ " reads them itself: then pick a gamepad layout for the game in Steam too, or turn Steam"
	+ " Input off for it in its Steam properties."
)


## The rows put in [param column] as [param settings] has Steam Input, with Steam on; none without.
static func add_to(column: VBoxContainer, settings: Settings) -> void:
	if not Store.on():
		return
	var switch := MenuTheme.toggle(settings.steam_input)
	switch.name = "SteamInput"
	switch.tooltip_text = TIP
	var layout := MenuTheme.button(LAYOUT, Type.BODY)
	layout.name = "SteamLayout"
	layout.tooltip_text = TIP
	layout.disabled = not settings.steam_input
	switch.toggled.connect(
		func(on: bool) -> void:
			settings.steam_input = on
			Store.use_steam_input(Game, on)
			layout.disabled = not on
	)
	layout.pressed.connect(
		func() -> void:
			if SteamPads.running != null:
				SteamPads.running.show_layout()
	)
	column.add_child(MenuTheme.row(SWITCH, switch))
	column.add_child(MenuTheme.row(LAYOUT_ROW, layout))
