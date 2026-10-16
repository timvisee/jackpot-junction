class_name SteamInvites
extends PanelContainer
## The friends online, each to be invited to the Steam game being played, GAME.md 10.8: what Invite
## opens from the menu when Steam's own invite dialog cannot come up over the game, Steam's overlay
## being off, as it is in a game started from the editor. A search field over the list keeps to the
## friends whose names have what is typed in them, the list as tall whatever it holds so the pane
## stays put while a name is typed; a friend invited says so for as long as the list is up.

## Back: the menu is up again in its place.
signal closed

## How tall the list may grow before it scrolls, and a row of it with the gap under it.
const ROOM := 420.0
const ROW := 72.0
## The longest search there is: as long as a Steam name.
const LONGEST := 32
## What a friend's row says once they are invited, after their name.
const INVITED := "  · invited"

var _search: LineEdit
var _list: VBoxContainer
var _scroll: ScrollContainer
var _back: Button
## The friends online as the list came up, by account and name, and those invited since.
var _friends: Array[Dictionary] = []
var _invited: Dictionary[int, bool] = {}


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(MenuTheme.title("Invite friends", Type.TITLE))
	column.add_child(MenuTheme.perforation())
	_search = MenuTheme.field("", "Search friends", LONGEST)
	_search.name = "Search"
	_search.custom_minimum_size = Vector2(MenuTheme.button_size().x, 44.0)
	_search.text_changed.connect(func(_typed: String) -> void: _show())
	# The keys are the box's while it has the cursor: the room goes on under the menu online.
	_search.focus_entered.connect(func() -> void: PlayerInput.typing = true)
	_search.focus_exited.connect(func() -> void: PlayerInput.typing = false)
	column.add_child(_search)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(MenuTheme.button_size().x, 0.0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.name = "Friends"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list)
	_back = MenuTheme.button("Back")
	_back.pressed.connect(func() -> void: closed.emit())
	column.add_child(_back)


## Up, with the friends online now and nothing searched for, the cursor on the first.
func open() -> void:
	visible = true
	_friends = Store.steam.friends.online() if Store.on() else []
	_invited.clear()
	_search.text = ""
	_scroll.custom_minimum_size.y = minf(ROOM, maxf(_friends.size(), 1) * ROW)
	_show()
	MenuTheme.deal(self)
	var first := _list.get_child(0) as Button if _list.get_child_count() > 0 else null
	(first if first != null else _back).grab_focus()


## The friends whose names have [param typed] in them, any case, or every one for nothing typed.
static func matching(friends: Array[Dictionary], typed: String) -> Array[Dictionary]:
	var wanted := typed.strip_edges().to_lower()
	var found: Array[Dictionary] = []
	for friend: Dictionary in friends:
		if wanted.is_empty() or str(friend["name"]).to_lower().contains(wanted):
			found.append(friend)
	return found


## The list made again for what is typed, the cursor kept where it was.
func _show() -> void:
	for old: Node in _list.get_children():
		_list.remove_child(old)
		old.queue_free()
	var shown := matching(_friends, _search.text)
	for friend: Dictionary in shown:
		var account := int(friend["id"])
		var invite := MenuTheme.button(str(friend["name"]), Type.BODY)
		invite.name = "Invite%d" % (account & 0x7FFFFFFF)
		if _invited.has(account):
			invite.text += INVITED
			invite.disabled = true
		invite.pressed.connect(_invite.bind(account, invite))
		_list.add_child(invite)
	if _friends.is_empty():
		_list.add_child(MenuTheme.subtitle("Nobody is online on Steam", Type.BODY))
	elif shown.is_empty():
		_list.add_child(MenuTheme.subtitle("Nobody online is called that", Type.BODY))


func _invite(friend: int, button: Button) -> void:
	if Store.on() and Store.steam.lobbies.invite_friend(friend):
		_invited[friend] = true
		button.text += INVITED
		button.disabled = true


func _exit_tree() -> void:
	PlayerInput.typing = false
