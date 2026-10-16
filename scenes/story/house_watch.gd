class_name HouseWatch
extends Node
## What the House shows at the Final Hand, STORY.md 8.2, at this screen and for its own candidate:
## each act announced as an amendment to the terms, see [HouseAmendment]; from observation the crowd
## turned to watch, the monitors on the racks showing the candidate's kart, the gold line of the
## forecast ahead of it, see [ForecastLine], and APPROVED · {name} over the Junction at every
## cash-out; and at convergence the room the Count Room's full green. It keeps the House's count of
## its forecasts for the evaluation, 8.4, see [FinalHand]: the racks raised at the candidate and the
## ones they got past, and how far off the forecasts were. The racks and the turret themselves, and
## the models, are the host's, see [HouseForecast].

## How often the House checks a forecast of the candidate against where they got to.
const SAMPLE_EVERY := 0.5
## How close the candidate's kart has to come to a rack's sides to have driven into it.
const HIT_REACH := 0.75
## The green the room goes at convergence, and how long it takes to.
const GREEN_KEY := Color(0.55, 1.0, 0.66)
const GREEN_LAMP := Color(0.68, 1.0, 0.76)
const GREEN_AIR := Color(0.04, 0.16, 0.08)
const GREEN_TAKES := 4.0
## The Junction's stamp: how high over the pad, how long it lasts, and how far it rises meanwhile.
const STAMP_OVER := 3.4
const STAMP_FOR := 1.8
const STAMP_RISE := 0.9

var match_node: Match
var forecast: HouseForecast
## Whether the amendments accepted count, the Final Hand due for the profile playing here.
var due := false
## The act this screen last showed.
var act := HouseForecast.Act.NONE
var line: ForecastLine
## How many amendments were accepted here.
var accepted := 0

var _monitors: Array[ShaderMaterial] = []
var _looked_for_monitors := false
var _watched: Kart
## The racks raised at the candidate as this screen saw them, by instance: whether each rose, and
## whether the candidate drove into it.
var _racks: Dictionary[int, HouseRack] = {}
var _rose: Dictionary[int, bool] = {}
var _hit: Dictionary[int, bool] = {}
var _samples: Array[Array] = []
var _sample_left := 0.0
var _clock := 0.0
var _greened := false
var _over := false
var _notice: HouseAmendment


## This screen's part in [param in_match], from [param with_forecast]; [param counts] whether its
## amendments count for the profile playing.
static func add_to(in_match: Match, with_forecast: HouseForecast, counts: bool) -> HouseWatch:
	var watch := HouseWatch.new()
	watch.name = "HouseWatch"
	watch.match_node = in_match
	watch.forecast = with_forecast
	watch.due = counts
	in_match.add_child(watch)
	return watch


func _ready() -> void:
	line = ForecastLine.new()
	line.name = "ForecastLine"
	match_node.add_child(line)
	Events.bank_completed.connect(_on_banked)


func _exit_tree() -> void:
	if Events.bank_completed.is_connected(_on_banked):
		Events.bank_completed.disconnect(_on_banked)
	if is_instance_valid(line):
		line.queue_free()


func _physics_process(delta: float) -> void:
	if match_node == null or match_node.arena == null or _over:
		return
	var candidate := FinalHand.candidate(match_node)
	var kart := candidate.kart if candidate != null else null
	var now := HouseForecast.act_of(match_node)
	if now > act:
		_begin(now)
	act = now
	if act >= HouseForecast.Act.OBSERVATION and kart != null:
		_watch(kart)
		_show_monitors(kart)
	if act >= HouseForecast.Act.OBSERVATION and kart != null and kart.is_active():
		line.show_forecast(forecast.line_of(kart), delta)
	else:
		line.clear()
	if candidate != null and kart != null and match_node.is_running():
		_sample(candidate, delta)
		_count_racks(candidate)


## An act begun: its amendment over the HUD, and at convergence the green.
func _begin(next: int) -> void:
	var hud := match_node.hud
	if hud != null:
		var notice := HouseAmendment.over(hud, next)
		notice.accepted.connect(_on_accepted)
		_notice = notice
	if next >= HouseForecast.Act.CONVERGENCE and not _greened:
		_greened = true
		_go_green()


## The amendment's stamp down, the candidate playing on: TERMS ACCEPTED, counted where it is due.
func _on_accepted() -> void:
	accepted += 1
	if due:
		Game.settings.profile.story.amendments += 1


func _process(_delta: float) -> void:
	if not is_instance_valid(_notice):
		return
	var candidate := FinalHand.candidate(match_node)
	_notice.driving = candidate != null and candidate.kart != null and candidate.kart.is_active()


## The crowd turned to watch [param kart], as it comes back after a death as well.
func _watch(kart: Kart) -> void:
	if kart == _watched or match_node.arena.crowd == null:
		return
	_watched = kart
	match_node.arena.crowd.watch(kart)


## The monitors on the racks showing [param kart] on a plan of the table, its forecast ahead of it.
func _show_monitors(kart: Kart) -> void:
	if not _looked_for_monitors:
		_looked_for_monitors = true
		_monitors = monitors_of(match_node.arena)
	if _monitors.is_empty():
		return
	var half := match_node.arena.world_size() * 0.5
	var at := Vector2(kart.global_position.x, kart.global_position.z)
	var ahead := forecast.ahead_of(kart, HouseForecast.AHEAD)
	var then := Vector2(ahead.x, ahead.z) if ahead.is_finite() else at
	var mark := (at + half) / (half * 2.0)
	var next := (then + half) / (half * 2.0)
	for screen: ShaderMaterial in _monitors:
		screen.set_shader_parameter(&"watching", 1.0)
		screen.set_shader_parameter(&"mark", mark)
		screen.set_shader_parameter(&"ahead", next)


## The Count Room's monitors in [param arena], each one's screen.
static func monitors_of(arena: Arena) -> Array[ShaderMaterial]:
	var found: Array[ShaderMaterial] = []
	for node: Node in arena.find_children("*", "MeshInstance3D", true, false):
		var screen := (node as MeshInstance3D).material_override as ShaderMaterial
		if screen != null and screen.shader == CountKit.MONITOR and not screen in found:
			found.append(screen)
	return found


## Now and then a forecast of the candidate taken, and each one checked a second and a half on
## against where they got to, unless they died in between: how far off it was, as a share of how far
## it had them going, kept for the evaluation's deviation.
func _sample(candidate: PlayerSlot, delta: float) -> void:
	_clock += delta
	var kart := candidate.kart
	_sample_left -= delta
	if _sample_left <= 0.0 and kart.is_active():
		_sample_left = SAMPLE_EVERY
		var ahead := forecast.line_of(kart)
		if ahead.size() >= 2:
			var reach := ahead[0].distance_to(ahead[ahead.size() - 1])
			_samples.append(
				[_clock + HouseForecast.AHEAD, ahead[ahead.size() - 1], reach, candidate.deaths]
			)
	while not _samples.is_empty() and float(_samples[0][0]) <= _clock:
		var taken: Array = _samples.pop_front()
		if not kart.is_active() or int(taken[3]) != candidate.deaths:
			continue
		var at := Vector3(kart.global_position.x, 0.0, kart.global_position.z)
		var off := at.distance_to(taken[1]) / maxf(float(taken[2]), 2.0)
		FinalHand.off_by += off
		FinalHand.forecasts += 1


## The racks raised at the candidate: each one noted as it rises, whether the candidate drove into
## it while it stood, and once it has gone, counted, see [method finish].
func _count_racks(candidate: PlayerSlot) -> void:
	var kart := candidate.kart
	for node: Node in MatchSnapshot.own_nodes(match_node, HouseRack.GROUP):
		var rack := node as HouseRack
		if rack == null or rack.target != candidate.index or rack.is_queued_for_deletion():
			continue
		var id := rack.get_instance_id()
		_racks[id] = rack
		_rose[id] = _rose.get(id, false) or rack.has_risen()
		if rack.is_solid() and kart.is_active() and rack.touches(kart.global_position, HIT_REACH):
			_hit[id] = true
	for id: int in _racks.keys():
		var rack: Variant = _racks[id]
		if not is_instance_valid(rack) or (rack as HouseRack).is_queued_for_deletion():
			_settle(id)


## Rack [param id] gone: counted as raised if it rose, and as beaten if the candidate got past it.
func _settle(id: int) -> void:
	if _rose.get(id, false):
		FinalHand.raised += 1
		if not _hit.get(id, false):
			FinalHand.beaten += 1
	_racks.erase(id)
	_rose.erase(id)
	_hit.erase(id)


## The whistle: every rack still standing counted as it is, the line put away, and nothing more
## shown, 8.3.
func finish() -> void:
	if _over:
		return
	_over = true
	for id: int in _racks.keys():
		_settle(id)
	line.clear()


## The room the Count Room's full green, over a few seconds: its sun, its lamp and its air.
func _go_green() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"arena_environment"):
		var lighting := node as ArenaEnvironment
		if lighting == null or lighting.key == null:
			continue
		var green := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
		green.tween_property(lighting.key, ^"light_color", GREEN_KEY, GREEN_TAKES)
		green.tween_property(lighting.lamp, ^"light_color", GREEN_LAMP, GREEN_TAKES)
		var air := lighting.world.environment
		green.tween_property(air, ^"ambient_light_color", GREEN_AIR, GREEN_TAKES)


## APPROVED and [param named] in the House's gold, standing up over the floor facing the camera.
static func approved(named: String) -> Label3D:
	var stamp := Label3D.new()
	stamp.name = "Approved"
	stamp.text = StoryLines.JUNCTION_APPROVED % named
	stamp.font = Type.display_font()
	stamp.font_size = 72
	stamp.pixel_size = 0.009
	stamp.outline_size = 14
	stamp.outline_modulate = Color(HouseTheme.ON_FOIL, 0.85)
	stamp.modulate = HouseTheme.FOIL
	stamp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stamp.no_depth_test = true
	return stamp


## A cash-out at the Junction, from observation on: APPROVED and the candidate's name stamped in
## gold over the pad, whoever's it was, every one of them approved in that name.
func _on_banked(slot: int, _coins: int, _mult: float, _total: int) -> void:
	if act < HouseForecast.Act.OBSERVATION or _over or match_node.arena == null:
		return
	var kart := match_node.kart_of(slot)
	if kart == null:
		return
	var pad := match_node.arena.junction_near(kart.global_position)
	var stamp := approved(StoryFill.name_of(Game.settings.profile))
	match_node.add_child(stamp)
	stamp.global_position = pad + Vector3(0.0, STAMP_OVER, 0.0)
	stamp.scale = Vector3.ONE * 1.5
	var landing := stamp.create_tween()
	landing.tween_property(stamp, ^"scale", Vector3.ONE, 0.16).set_ease(Tween.EASE_IN)
	landing.tween_interval(STAMP_FOR * 0.5)
	landing.set_parallel(true)
	landing.tween_property(stamp, ^"modulate:a", 0.0, STAMP_FOR * 0.5)
	landing.tween_property(stamp, ^"position:y", stamp.position.y + STAMP_RISE, STAMP_FOR * 0.5)
	landing.chain().tween_callback(stamp.queue_free)
