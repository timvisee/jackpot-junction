class_name FolderBack
extends RefCounted
## What the player keeps in the folder that is not a note, STORY.md 7.2: at its front the invitation
## that brought them to the tables, its stub torn off, 6.1a, and the loyalty program's letter, its
## card torn off it, 6.6b; and at its back after the ending, 8.1
## and 8.7, the House's invitation and its golden ticket, ADMIT ONE torn off, laid on their pages as
## they are,
## see [method lay]; the Final Hand's payout slip with its evaluation as it was stamped, from what
## the profile kept of it; and the card of Terms Accepted, license-sized, the House's paper with its
## APPROVED stamp across it and TERMS ACCEPTED under it, with the date. And from the first time it
## was torn off, the strip off the foot of the House's page, ragged along its top where it was torn
## across, STATUS blank on it, 8.4. Each
## lies on its [NotePage] as a note does, askew under a clip, tape or a staple, see [constant HELD].

const SLIP := Vector2(380.0, 300.0)
## The strip torn off the foot of the House's page, STATUS blank on it.
const STRIP := Vector2(380.0, 112.0)
const CARD := Vector2(340.0, 214.0)
const SIZE := 9
## The room kept round the invitation and the ticket on the page, under its title.
const ROOM := 30.0
## What holds each on its page, as Kit held the notes, see [NoteOnPage].
const HELD := {
	StoryNotes.OPENING: &"tapes",
	StoryNotes.WELCOME_LETTER: &"clip",
	StoryNotes.INVITATION: &"clip",
	StoryNotes.TICKET: &"tape",
	StoryNotes.FINAL_SLIP: &"staple",
	StoryNotes.TORN_SLIP: &"clip",
	StoryNotes.TERMS_CARD: &"tapes",
	# The House's letters, STORY.md 6.11, clipped as the program's is, and the duties' card taped.
	-7: &"clip",
	-8: &"clip",
	-9: &"clip",
	-10: &"tapes",
	# Kit's cards in the pocket, each taped in by a corner, STORY.md 7.2.
	-21: &"tape",
	-22: &"tape",
	-23: &"tape",
	-24: &"tape",
	-25: &"tape",
}
## How big one of Kit's cards is drawn in the folder, as a share of its size in a hand: about as a
## playing card would lie on a page.
const KIT_SCALE := 1.15


## The back page [param number] of [param profile]'s folder on [param page].
static func draw(page: NotePage, number: int, profile: Profile) -> void:
	var kept: Dictionary = profile.story.evaluation if profile != null else {}
	var date := str(kept.get("date", profile.story.final_hand if profile != null else ""))
	if number == StoryNotes.FINAL_SLIP:
		_slip(page, kept, date)
	elif number == StoryNotes.TORN_SLIP and profile != null:
		_strip(page)
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
		StoryNotes.TORN_SLIP:
			return Rect2(
				Vector2((NotePage.SIZE.x - STRIP.x) * 0.5, NotePage.TITLE_ROOM + 70.0), STRIP
			)
		StoryNotes.TERMS_CARD:
			return Rect2(
				Vector2((NotePage.SIZE.x - CARD.x) * 0.5, NotePage.TITLE_ROOM + 60.0), CARD
			)
		StoryNotes.INVITATION, StoryNotes.TICKET, StoryNotes.OPENING, StoryNotes.WELCOME_LETTER:
			wide = _drawn(number)
		_ when StoryLetters.is_letter(number) or KitCards.is_page(number):
			wide = _drawn(number)
	return Rect2(room.get_center() - wide * 0.5, wide)


## Where back page [param number]'s thing lies on the folder's page before it is laid askew, see
## [NoteOnPage]: the slip, the card and Kit's cards where they are drawn, and the invitation and the
## ticket, short of its stub, scaled down to the page under its title.
static func lying_rect(number: int) -> Rect2:
	if not _is_card(number) or KitCards.is_page(number):
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


## Whether back page [param number] is a card that draws itself: an invitation, the ticket or one
## of the House's letters.
static func _is_card(number: int) -> bool:
	return (
		(
			number
			in [
				StoryNotes.INVITATION,
				StoryNotes.TICKET,
				StoryNotes.OPENING,
				StoryNotes.WELCOME_LETTER
			]
		)
		or StoryLetters.is_letter(number)
		or KitCards.is_page(number)
	)


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
	if number == StoryNotes.WELCOME_LETTER:
		return LoyaltyLetter.SIZE
	if StoryLetters.is_letter(number):
		return HouseLetter.size_of(StoryLetters.key_of(number))
	if KitCards.is_page(number):
		return JokerCard.SIZE * KIT_SCALE
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
	if KitCards.is_page(number):
		_lay_kit_card(page, number)
		return
	if StoryLetters.is_letter(number):
		var mail := HouseLetter.of(StoryLetters.key_of(number), profile)
		mail.face_down = face_down
		kept = mail
		whole = mail.size
	elif number == StoryNotes.WELCOME_LETTER:
		var letter := LoyaltyLetter.to_profile(profile) if profile != null else LoyaltyLetter.new()
		letter.taken = true
		letter.face_down = face_down
		kept = letter
		whole = LoyaltyLetter.SIZE
	elif number == StoryNotes.OPENING:
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


## One of Kit's cards on [param page], its face as it was dealt, or turned over, its back painted
## over as its face was and Kit's longer line on it; nothing where it shines, being pencil.
static func _lay_kit_card(page: NotePage, number: int) -> void:
	var card := KitCards.card_of(number)
	if card == null or page.layer == &"shine" or page.layer == &"shine_back":
		return
	var kept: Control
	if page.layer == &"back":
		kept = KitCardBack.of(card)
	else:
		kept = JokerCard.create(card)
	kept.name = "Kept"
	var lies := lying_rect(number) if page.layer == &"lying" else paper_rect(number)
	kept.pivot_offset = Vector2.ZERO
	kept.scale = Vector2.ONE * (lies.size.x / JokerCard.SIZE.x)
	kept.position = lies.position
	page.add_child(kept)


## The back of back page [param number] on [param page], turned over in a closer look: the slip's
## bare paper, and the card's back, the House's seal in foil on its paper. The invitation and the
## ticket draw their own backs, see [method lay].
static func draw_back(page: NotePage, number: int) -> void:
	var rect := paper_rect(number)
	if number == StoryNotes.FINAL_SLIP:
		page.draw_colored_polygon(NotePaper.torn(rect, 5.0, true, true), HouseTheme.PAPER)
	elif number == StoryNotes.TORN_SLIP:
		page.draw_colored_polygon(TornPage.shape_of(rect), HouseTheme.PAPER)
	elif number == StoryNotes.TERMS_CARD:
		var paper := StyleBoxFlat.new()
		paper.bg_color = HouseTheme.PAPER
		paper.set_corner_radius_all(10)
		paper.set_border_width_all(2)
		paper.border_color = HouseTheme.FOIL
		page.draw_style_box(paper, rect)
		var middle := rect.get_center()
		for ring: float in [40.0, 31.0, 15.0]:
			NoteCharts.arc(page, middle, ring, HouseTheme.FOIL, 1.8)
		var star := PackedVector2Array()
		for i: int in 10:
			var reach := 9.0 if i % 2 == 0 else 4.0
			star.append(middle + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
		page.draw_colored_polygon(star, HouseTheme.FOIL)


## The evaluation [param kept], on its slip, stamped APPROVED over STATUS on [param date].
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


## The strip torn off the foot of the House's page, STORY.md 8.4: its top torn straight across by
## hand, STATUS blank on it, the House's line on how to stamp it, and Kit's pencil under that.
static func _strip(page: NotePage) -> void:
	var rect := paper_rect(StoryNotes.TORN_SLIP)
	page.draw_rect(Rect2(rect.position + Vector2(3.0, 4.0), rect.size), Color(0.0, 0.0, 0.0, 0.12))
	page.draw_colored_polygon(TornPage.shape_of(rect), HouseTheme.PAPER)
	var font := NotePage.TYPED
	var x := rect.position.x + 16.0
	var width := rect.size.x - 32.0
	var y := rect.position.y + 20.0
	page.leader_line("STATUS", " ", font, SIZE + 1, HouseTheme.INK, x, y, width * 0.55)
	var blank := Vector2(x + width * 0.58, y + 12.0)
	page.draw_line(blank, blank + Vector2(width * 0.42, 0.0), HouseTheme.INK, 1.2)
	var how := LicenseScreen.STAMP_LINE % "Click"
	var wide := font.get_string_size(how, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var faint := HouseTheme.INK_FAINT
	var how_at := Vector2(x + width - wide, y + 40.0)
	page.draw_string(font, how_at, how, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, faint)
	var hand := NotePage.HAND
	var said := StoryLines.KIT_TEAR
	var long := hand.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	page.draw_set_transform(Vector2(x + width - long, y + 64.0), KitPencil.TILT, Vector2.ONE)
	page.draw_string(hand, Vector2.ZERO, said, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, KitCards.PENCIL)
	page.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
