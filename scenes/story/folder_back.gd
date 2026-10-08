class_name FolderBack
extends RefCounted
## What the player keeps in the folder that is not a note, STORY.md 7.2: at its front the invitation
## that brought them to the tables, its stub torn off, 6.1a; and at its back after the ending, 8.1
## and 8.7, the House's invitation and its golden ticket, ADMIT ONE torn off, laid on their pages as
## they are,
## see [method lay]; the Final Hand's payout slip with its evaluation as it was stamped, from what
## the profile kept of it; and the card of Terms Accepted, license-sized, the House's paper with its
## APPROVED stamp across it and TERMS ACCEPTED under it, with the date. Each lies on its [NotePage]
## as a note does, askew under a clip, tape or a staple, see [constant HELD].

const SLIP := Vector2(380.0, 300.0)
const CARD := Vector2(340.0, 214.0)
const SIZE := 9
## The room kept round the invitation and the ticket on the page, under its title.
const ROOM := 30.0
## What holds each on its page, as Kit held the notes, see [NoteOnPage].
const HELD := {
	StoryNotes.OPENING: &"tapes",
	StoryNotes.INVITATION: &"clip",
	StoryNotes.TICKET: &"tape",
	StoryNotes.FINAL_SLIP: &"staple",
	StoryNotes.TERMS_CARD: &"tapes",
}


## The back page [param number] of [param profile]'s folder on [param page].
static func draw(page: NotePage, number: int, profile: Profile) -> void:
	var kept: Dictionary = profile.story.evaluation if profile != null else {}
	var date := str(kept.get("date", profile.story.final_hand if profile != null else ""))
	if number == StoryNotes.FINAL_SLIP:
		_slip(page, kept, date)
	elif number == StoryNotes.TERMS_CARD:
		_card(page, date)


## Where back page [param number]'s thing lies, as a note's paper does: the slip and the card where
## they are drawn, the invitation and the ticket, short of its stub, at their own size in the middle
## of the page, as they are looked at closer.
static func paper_rect(number: int) -> Rect2:
	var room := Rect2(
		0.0,
		NotePage.TITLE_ROOM,
		NotePage.SIZE.x,
		NotePage.SIZE.y - NotePage.TITLE_ROOM - NotePage.MARGIN * 0.5
	)
	var wide := SLIP
	match number:
		StoryNotes.FINAL_SLIP:
			return Rect2(Vector2((NotePage.SIZE.x - SLIP.x) * 0.5, NotePage.TITLE_ROOM), SLIP)
		StoryNotes.TERMS_CARD:
			return Rect2(
				Vector2((NotePage.SIZE.x - CARD.x) * 0.5, NotePage.TITLE_ROOM + 60.0), CARD
			)
		StoryNotes.INVITATION, StoryNotes.TICKET, StoryNotes.OPENING:
			wide = _drawn(number)
	return Rect2(room.get_center() - wide * 0.5, wide)


## Where back page [param number]'s thing lies on the folder's page before it is laid askew, see
## [NoteOnPage]: the slip and the card where they are drawn, and the invitation and the ticket,
## short of its stub, scaled down to the page under its title.
static func lying_rect(number: int) -> Rect2:
	if not _is_card(number):
		return paper_rect(number)
	var room := Rect2(
		ROOM,
		NotePage.TITLE_ROOM,
		NotePage.SIZE.x - ROOM * 2.0,
		NotePage.SIZE.y - NotePage.TITLE_ROOM - ROOM * 2.0
	)
	var drawn := _drawn(number)
	var fit := minf(room.size.x / drawn.x, room.size.y / drawn.y)
	return Rect2(room.get_center() - drawn * fit * 0.5, drawn * fit)


## Whether back page [param number] is a card that draws itself: an invitation or the ticket.
static func _is_card(number: int) -> bool:
	return number in [StoryNotes.INVITATION, StoryNotes.TICKET, StoryNotes.OPENING]


## The middle of what shows of back page [param number]'s card, an invitation, or the ticket or
## the first invitation short of its stub, where it draws itself: what a closer look goes up from
## and back down onto, see [method NotesFolder.lift_of].
static func middle_of(number: int) -> Vector2:
	return _drawn(number) * 0.5


## How big an invitation, or the ticket or the first invitation short of its stub, is drawn.
static func _drawn(number: int) -> Vector2:
	if number == StoryNotes.INVITATION:
		return InvitationCard.SIZE
	if number == StoryNotes.OPENING:
		return Vector2(OpeningCard.SIZE.x, OpeningCard.PERFORATION + OpeningCard.RAGGED)
	return GoldenTicket.SIZE - Vector2(GoldenTicket.STUB, 0.0)


## An invitation or the torn ticket laid on [param page], if it is the page for one, for
## [param profile]'s player, each drawing itself: lying on the folder's page, scaled to it, see
## [method lying_rect]; looked at closer, at its own size where its paper lies, face up or, on the
## back, face down; or, for the first invitation, as where it shines, see
## [member OpeningCard.shine_only].
static func lay(page: NotePage, number: int, profile: Profile) -> void:
	if not _is_card(number):
		return
	var named := profile.license_holder if profile != null else ""
	if named.is_empty():
		named = FinalHandPane.holder_name()
	var kept: Control
	var whole: Vector2
	var face_down := page.layer == &"back" or page.layer == &"shine_back"
	if number == StoryNotes.OPENING:
		var opening := OpeningCard.new()
		opening.number = profile.story.invitation if profile != null else ""
		opening.torn = true
		opening.shows_stub = false
		opening.face_down = face_down
		opening.shine_only = page.layer == &"shine" or page.layer == &"shine_back"
		kept = opening
		whole = OpeningCard.SIZE
	elif number == StoryNotes.INVITATION:
		var card := InvitationCard.new()
		card.holder = named
		card.face_up = not face_down
		kept = card
		whole = InvitationCard.SIZE
	else:
		var ticket := GoldenTicket.make(named, profile.license_number if profile != null else "")
		ticket.face_down = face_down
		ticket.ready.connect(ticket.show_torn)
		kept = ticket
		whole = GoldenTicket.SIZE
	kept.name = "Kept"
	if page.layer != &"lying":
		kept.position = paper_rect(number).position
		page.add_child(kept)
		return
	var lies := lying_rect(number)
	var fit := lies.size.x / _drawn(number).x
	# Scaled about its middle; the ticket's middle sits half a stub right of what is left of it, and
	# the first invitation's half a stub under it.
	var middle := lies.get_center()
	if kept is GoldenTicket:
		middle.x += GoldenTicket.STUB * 0.5 * fit
	elif kept is OpeningCard:
		middle.y += (OpeningCard.SIZE.y - _drawn(number).y) * 0.5 * fit
	kept.scale = Vector2.ONE * fit
	kept.position = middle - whole * 0.5
	page.add_child(kept)


## The back of back page [param number] on [param page], turned over in a closer look: the slip's
## bare paper, and the card's back, the House's seal in foil on its paper. The invitation and the
## ticket draw their own backs, see [method lay].
static func draw_back(page: NotePage, number: int) -> void:
	var rect := paper_rect(number)
	if number == StoryNotes.FINAL_SLIP:
		page.draw_colored_polygon(NotePaper.torn(rect, 5.0, true, true), HouseTheme.PAPER)
	elif number == StoryNotes.TERMS_CARD:
		var paper := StyleBoxFlat.new()
		paper.bg_color = HouseTheme.PAPER
		paper.set_corner_radius_all(10)
		paper.set_border_width_all(2)
		paper.border_color = HouseTheme.FOIL
		page.draw_style_box(paper, rect)
		var middle := rect.get_center()
		for ring: float in [40.0, 31.0, 15.0]:
			page.draw_arc(middle, ring, 0.0, TAU, 48, HouseTheme.FOIL, 1.8, true)
		var star := PackedVector2Array()
		for i: int in 10:
			var reach := 9.0 if i % 2 == 0 else 4.0
			star.append(middle + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
		page.draw_colored_polygon(star, HouseTheme.FOIL)


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
