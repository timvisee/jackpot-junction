class_name SteamInputRow
extends RefCounted
## The Controls page's rows for Steam Input, GAME.md 10.8, in a game with Steam on alone: its
## switch, which reads the controllers through Steam or leaves them to the game, and the way to
## Steam's own settings for the layout of the controller in hand. And its Gamepad column with such
## a controller in hand: each action where Steam has it on that controller, a binding asked to
## change opening Steam's settings, Steam binding it rather than the game.

const SWITCH := "Steam Input"
const LAYOUT_ROW := "Controller layout"
const LAYOUT := "Change in Steam"
## The Gamepad column's head, and what it says with a controller of Steam Input's in hand.
const PAD_HEAD := "Gamepad"
const IN_STEAM := "Gamepad, in Steam"
## What the Controls page says as a binding of such a controller is asked to change.
const OPENED := "Steam binds this controller: change it in Steam's controller settings"
const NO_OVERLAY := "Steam binds this controller: turn on the Steam overlay to change it there"
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


## The pad of Steam Input's whose bindings the Gamepad column shows: the one touched last, or, with
## no pad of the engine's touched last, the first of Steam's; -1 for none, the column showing the
## game's own bindings, which the engine's pads read.
static func pad() -> int:
	if DeviceInput.steam_pads.is_empty():
		return -1
	var last := PadFamily.last_pad()
	if DeviceInput.steam_pads.has(last):
		return last
	return -1 if last >= 0 else DeviceInput.steam_pads.keys().min()


## The Gamepad column's head [param head], or what it says with a controller of Steam's in hand.
static func head(text: String) -> String:
	return IN_STEAM if text == PAD_HEAD and pad() >= 0 else text


## Puts in [param row] where Steam has [param action] bound on [method pad], drawn in [param ink]
## at [param size]; nothing where Steam has it on nothing.
static func add_glyph(row: Control, action: StringName, ink: Color, size: int) -> void:
	var glyph := InputGlyph.of_steam(action, pad(), ink, size)
	if glyph != null:
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(glyph)


## What [param action] is bound to, in words, for a screen reader: on [method pad] where Steam has
## it, see [method InputActions.binding_text] otherwise.
static func bound_text(action: StringName, keyboard: bool) -> String:
	var device := -1 if keyboard else pad()
	if device < 0:
		return InputActions.binding_text(action, keyboard)
	var place := DeviceInput.steam_bound(action, device)
	if place.has("event"):
		return InputActions.event_text(place["event"], PadFamily.of_device(device))
	return str(place.get("word", "-"))


## Opens Steam's settings for [method pad], a gamepad binding having been asked to change with a
## controller of Steam's in hand, and says so on [param status]. Says whether it was one.
static func rebound_in_steam(status: Label) -> bool:
	var device := pad()
	if device < 0 or SteamPads.running == null:
		return false
	status.text = OPENED if SteamPads.running.show_layout(device) else NO_OVERLAY
	return true
