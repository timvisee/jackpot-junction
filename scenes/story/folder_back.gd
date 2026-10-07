class_name FolderBack
extends RefCounted
## What the player keeps at the back of the folder after the ending, STORY.md 7.2, 8.1 and 8.7: the
## House's invitation and its golden ticket, ADMIT ONE torn off, laid on their pages as they are,
## see [method lay]; the Final Hand's payout slip with its evaluation as it was stamped, from what
## the profile kept of it; and the card of Terms Accepted, license-sized, the House's paper with its
## APPROVED stamp across it and TERMS ACCEPTED under it, with the date. Drawn onto a [NotePage] as a
## note is.

const SLIP := Vector2(380.0, 300.0)
const CARD := Vector2(340.0, 214.0)
const SIZE := 9
## The invitation and the ticket, which draw themselves, laid on their page and tilted a little.
const INVITATION_TILT := -0.03
const TICKET_TILT := -0.06
## The room kept round them on the page, under its title.
const ROOM := 30.0


## The back page [param number] of [param profile]'s folder on [param page].
static func draw(page: NotePage, number: int, profile: Profile) -> void:
	var kept: Dictionary = profile.story.evaluation if profile != null else {}
	var date := str(kept.get("date", profile.story.final_hand if profile != null else ""))
	if number == StoryNotes.FINAL_SLIP:
		_slip(page, kept, date)
	elif number == StoryNotes.TERMS_CARD:
		_card(page, date)


## The invitation or the torn ticket laid on [param page], if it is the page for one: each draws
## itself, scaled to the page, for [param profile]'s player.
static func lay(page: NotePage, number: int, profile: Profile) -> void:
	if number != StoryNotes.INVITATION and number != StoryNotes.TICKET:
		return
	var named := profile.license_holder if profile != null else ""
	if named.is_empty():
		named = FinalHandPane.holder_name()
	var room := Rect2(
		ROOM,
		NotePage.TITLE_ROOM,
		NotePage.SIZE.x - ROOM * 2.0,
		NotePage.SIZE.y - NotePage.TITLE_ROOM - ROOM * 2.0
	)
	var kept: Control
	var drawn: Vector2
	var tilt: float
	if number == StoryNotes.INVITATION:
		var card := InvitationCard.new()
		card.holder = named
		card.face_up = true
		kept = card
		drawn = InvitationCard.SIZE
		tilt = INVITATION_TILT
	else:
		var ticket := GoldenTicket.make(named, profile.license_number if profile != null else "")
		ticket.ready.connect(ticket.show_torn)
		kept = ticket
		# Only the ticket short of its stub is left to fit.
		drawn = GoldenTicket.SIZE - Vector2(GoldenTicket.STUB, 0.0)
		tilt = TICKET_TILT
	var fit := minf(room.size.x / drawn.x, room.size.y / drawn.y)
	var whole: Vector2 = InvitationCard.SIZE if kept is InvitationCard else GoldenTicket.SIZE
	# Scaled and turned about its middle; the ticket's middle sits half a stub right of what is
	# left of it.
	var middle := room.get_center()
	if kept is GoldenTicket:
		middle.x += GoldenTicket.STUB * 0.5 * fit
	kept.name = "Kept"
	kept.scale = Vector2.ONE * fit
	kept.rotation = tilt
	kept.position = middle - whole * 0.5
	page.add_child(kept)


static func _slip(page: NotePage, kept: Dictionary, date: String) -> void:
	var rect := Rect2(Vector2((NotePage.SIZE.x - SLIP.x) * 0.5, NotePage.TITLE_ROOM), SLIP)
	page.draw_rect(Rect2(rect.position + Vector2(3.0, 4.0), rect.size), Color(0.0, 0.0, 0.0, 0.12))
	page.draw_colored_polygon(NotePaper.torn(rect, 5.0, true, true), HouseTheme.PAPER)
	var font := NotePage.TYPED
	var ink := HouseTheme.INK
	var x := rect.position.x + 16.0
	var width := rect.size.x - 32.0
	var y := rect.position.y + 24.0
	var title := StoryLines.EVALUATION_TITLE
	var wide := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE + 1).x
	page.draw_string(
		font,
		Vector2(rect.get_center().x - wide * 0.5, y),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		SIZE + 1,
		ink
	)
	y += 12.0
	var status := Vector2.ZERO
	for line: Array in kept.get("lines", []):
		var label := str(line[0])
		var value := str(line[1])
		if label == "STATUS":
			status = Vector2(x + width * 0.62, y + 8.0)
		y = page.leader_line(
			label, value if not value.is_empty() else " ", font, SIZE, ink, x, y, width
		)
	if status != Vector2.ZERO:
		ApprovedStamp.draw_on(page, status, 30.0, date, ApprovedStamp.TILT)


static func _card(page: NotePage, date: String) -> void:
	var rect := Rect2(Vector2((NotePage.SIZE.x - CARD.x) * 0.5, NotePage.TITLE_ROOM + 60.0), CARD)
	page.draw_rect(Rect2(rect.position + Vector2(3.0, 4.0), rect.size), Color(0.0, 0.0, 0.0, 0.12))
	var paper := StyleBoxFlat.new()
	paper.bg_color = HouseTheme.PAPER
	paper.set_corner_radius_all(10)
	paper.set_border_width_all(2)
	paper.border_color = HouseTheme.FOIL
	page.draw_style_box(paper, rect)
	ApprovedStamp.draw_on(page, rect.get_center() + Vector2(0.0, -14.0), 62.0, "", -0.12)
	var font := Type.display_font()
	var words := StoryLines.TERMS_ACCEPTED_CARD
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var at := Vector2(rect.get_center().x - wide * 0.5, rect.end.y - 30.0)
	page.draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, HouseTheme.INK)
	var when := NotePage.TYPED.get_string_size(date, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	page.draw_string(
		NotePage.TYPED,
		Vector2(rect.get_center().x - when * 0.5, rect.end.y - 12.0),
		date,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		HouseTheme.INK_FAINT
	)
