class_name LandmarkIcons
extends RefCounted
## Each landmark's own picture, GAME.md 8.9: what the place is, on its sign on the map and on its
## row of the list, so no two of the map's signs look alike. The pane says what it pays with the
## picture of that, see [method LoyaltyArt.draw_reward].
##
## Drawn as the other pictures of GAME.md 8.3a are, a file for each landmark in
## assets/icons/landmarks, and printed flat in the one ink it is handed with whatever is under it
## showing through, so a picture serves a sign's gold, white or pencil as it serves the list's.


## The picture of [param landmark] into [param box] on [param on] in [param ink]; what it pays for
## a landmark with no picture of its own.
static func draw_into(on: CanvasItem, box: Rect2, landmark: LoyaltyLandmark, ink: Color) -> void:
	if not IconPress.draw(on, box, drawing_of(landmark), ink, IconPress.Ground.PAPER):
		LoyaltyArt.draw_reward(on, box, landmark, ink)


## The name of [param landmark]'s drawing.
static func drawing_of(landmark: LoyaltyLandmark) -> StringName:
	return StringName("landmark_%s" % landmark.id)
