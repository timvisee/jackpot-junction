class_name Perforation
extends Control
## The perforation across a pane under its header, GAME.md 8.1a: a dotted line with a bite out of
## either side of the pane, the way a ticket's stub is torn off. The holes and the bites are the
## pane's own to draw, see [member TicketStyle.perforations]; this stands in the column where they
## go and tells the pane, again whenever it is moved, so a header that grows by a line moves the
## perforation down with it.
##
## It is as tall as it takes for the gap between the hairline round the header and what is over
## it, and between the hairline round the body and what is under it, to be the pane's own gap,
## the one beside its words, whatever the column it stands in puts between its children.

## How much room the perforation takes in its column at the least.
const HEIGHT := 14.0

var _pane: PanelContainer


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_notify_transform(true)
	_fit()
	_tell.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_RESIZED:
		_tell()


func _exit_tree() -> void:
	var style := _style()
	if style != null:
		style.perforations = PackedFloat32Array()
	_pane = null


## Tall enough that the gap either side of it is the pane's own, see the class description.
func _fit() -> void:
	var style := _style()
	var gap := MenuTheme.PANE_GAP
	var bite := 10.0
	if style != null:
		gap = style.content_margin_left - style.frame_inset
		bite = style.bite
	var between := 0.0
	var column := get_parent() as BoxContainer
	if column != null:
		between = float(column.get_theme_constant(&"separation"))
	custom_minimum_size.y = maxf((gap + bite + TicketStyle.FRAME_GAP - between) * 2.0, HEIGHT)


## How far down from its own top the hairline round the header over it runs, see
## [method TicketStyle._frames]: the line a scroll over it reaches down to.
func line_over() -> float:
	var style := _style()
	var bite := style.bite if style != null else 10.0
	return maxf(size.y, custom_minimum_size.y) * 0.5 - bite - TicketStyle.FRAME_GAP


## The ticket of the nearest pane this stands in, or null in anything else.
func _style() -> TicketStyle:
	if _pane == null or not is_instance_valid(_pane):
		_pane = null
		var up := get_parent()
		while up != null:
			var panel := up as PanelContainer
			if panel != null and panel.get_theme_stylebox(&"panel") is TicketStyle:
				_pane = panel
				break
			up = up.get_parent()
	if _pane == null:
		return null
	return _pane.get_theme_stylebox(&"panel") as TicketStyle


func _tell() -> void:
	if not is_inside_tree():
		return
	var style := _style()
	if style == null:
		return
	var middle := get_global_transform() * (size * 0.5)
	var down := (_pane.get_global_transform().affine_inverse() * middle).y
	style.perforations = PackedFloat32Array([roundf(down)])
