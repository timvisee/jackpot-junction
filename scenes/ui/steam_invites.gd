class_name SteamInvites
extends PanelContainer
## The friends online, each to be invited to the Steam game being played, GAME.md 10.8: what Invite
## opens from the menu when Steam's own invite dialog cannot come up over the game, Steam's overlay
## being off, as it is in a game started from the editor.

## Back: the menu is up again in its place.
signal closed

## How tall the list may grow before it scrolls.
const ROOM := 420.0

var _list: VBoxContainer
var _back: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(MenuTheme.title("Invite friends", Type.TITLE))
	column.add_child(MenuTheme.perforation())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(MenuTheme.button_size().x, 0.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "Friends"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	_back = MenuTheme.button("Back")
	_back.pressed.connect(func() -> void: closed.emit())
	column.add_child(_back)


## Up, with the friends online now, the cursor on the first.
func open() -> void:
	visible = true
	for old: Node in _list.get_children():
		_list.remove_child(old)
		old.queue_free()
	var friends: Array[Dictionary] = Store.steam.friends.online() if Store.on() else []
	for friend: Dictionary in friends:
		var invite := MenuTheme.button(str(friend["name"]), Type.BODY)
		invite.name = "Invite%d" % (int(friend["id"]) & 0x7FFFFFFF)
		invite.pressed.connect(_invite.bind(int(friend["id"]), invite))
		_list.add_child(invite)
	if friends.is_empty():
		_list.add_child(MenuTheme.subtitle("Nobody is online on Steam", Type.BODY))
	var scroll := _list.get_parent() as ScrollContainer
	scroll.custom_minimum_size.y = minf(ROOM, maxf(friends.size(), 1) * 72.0)
	MenuTheme.deal(self)
	var first := _list.get_child(0) as Button if _list.get_child_count() > 0 else null
	(first if first != null else _back).grab_focus()


func _invite(friend: int, button: Button) -> void:
	if Store.on() and Store.steam.lobbies.invite_friend(friend):
		button.text += "  · invited"
		button.disabled = true
