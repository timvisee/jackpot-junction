class_name TeamPennant
extends RefCounted
## The pennant a kart flies in team play, GAME.md 3.14: a little card of cream stock on a whip at
## the kart's back corner, its team's suit printed on it in the team's color, so the side a kart is
## on reads in shape as well as in color, for a player who cannot tell the colors apart. It leans
## back off the whip with its face turned up to the camera over the table: a flag hanging straight
## shows a camera looking down on it nothing but its edge.

const NAME := "TeamPennant"
## Where the whip stands on the body, how tall it is, and how thick.
const AT := Vector3(-0.36, 0.5, 0.56)
const WHIP := 0.72
const WHIP_RADIUS := 0.03
## The card it flies, how far it leans back from flat, and how much of it the suit fills.
const CARD := Vector2(0.46, 0.56)
const LEAN := 28.0
const SUIT := 0.84
const PIXELS := 96
const CREAM := Color(0.97, 0.95, 0.9)
const WHIP_COLOR := Color(0.16, 0.16, 0.18)

## A white suit on nothing for each suit, made the first time it is asked for and tinted by the
## material that wears it, so the four of them serve every team in every palette.
static var _masks: Dictionary[int, ImageTexture] = {}


## Puts [param team]'s pennant on [param body], a kart's, in place of any it flew; none with no
## team.
static func dress(body: Node3D, team: int) -> void:
	if body == null:
		return
	var old := body.get_node_or_null(NAME)
	if old != null:
		body.remove_child(old)
		old.queue_free()
	if team >= 0:
		body.add_child(make(team))


## The pennant for [param team].
static func make(team: int) -> Node3D:
	var pennant := Node3D.new()
	pennant.name = NAME
	pennant.position = AT
	var whip := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = WHIP_RADIUS
	rod.bottom_radius = WHIP_RADIUS
	rod.height = WHIP
	whip.mesh = rod
	whip.material_override = _paint(WHIP_COLOR)
	whip.position = Vector3(0.0, WHIP * 0.5, 0.0)
	whip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pennant.add_child(whip)
	# The card off the top of the whip, trailing back over the kart's tail, face up and tipped a
	# little toward the back.
	var card := Node3D.new()
	card.name = "Card"
	card.position = Vector3(0.0, WHIP, CARD.y * 0.5)
	card.rotation_degrees = Vector3(-90.0 + LEAN, 0.0, 0.0)
	pennant.add_child(card)
	var stock := MeshInstance3D.new()
	var board := BoxMesh.new()
	board.size = Vector3(CARD.x, CARD.y, 0.012)
	stock.mesh = board
	stock.material_override = _paint(CREAM)
	card.add_child(stock)
	var printed := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * minf(CARD.x, CARD.y) * SUIT
	printed.mesh = quad
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Teams.color(team)
	ink.albedo_texture = mask(TeamArt.suit_of(team))
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	ink.alpha_scissor_threshold = 0.5
	ink.roughness = 0.62
	printed.material_override = ink
	printed.position = Vector3(0.0, 0.0, 0.008)
	printed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.add_child(printed)
	return pennant


## A white [param suit] on nothing, for a material to tint, made once a suit and kept.
static func mask(suit: int) -> ImageTexture:
	if _masks.has(suit):
		return _masks[suit]
	var image := Image.create_empty(PIXELS, PIXELS, false, Image.FORMAT_RGBA8)
	for y: int in PIXELS:
		for x: int in PIXELS:
			var at := (Vector2(x, y) + Vector2.ONE * 0.5) / float(PIXELS)
			var inked := KartStickers.in_suit(suit, at)
			image.set_pixel(x, y, Color.WHITE if inked else Color(1.0, 1.0, 1.0, 0.0))
	image.generate_mipmaps()
	_masks[suit] = ImageTexture.create_from_image(image)
	return _masks[suit]


static func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	return material
