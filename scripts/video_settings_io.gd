extends RefCounted
## Reads and writes the video settings, GAME.md 8.5, in the "video" section of the settings file.
## Kept out of [Settings] so that file stays within its length, and loaded at runtime with no class
## name of its own, so it draws no compile-time edge back into Settings, as lobby_settings_io.gd.


## Reads every video setting from [param file] into [param settings], each falling back to what the
## settings already hold when the file has nothing to say, or something no longer offered.
static func load_into(settings: Settings, file: ConfigFile) -> void:
	settings.fullscreen = file.get_value("video", "fullscreen", settings.fullscreen)
	settings.vsync = file.get_value("video", "vsync", settings.vsync)
	settings.window_size = file.get_value("video", "window_size", settings.window_size)
	settings.monitor = maxi(int(file.get_value("video", "monitor", settings.monitor)), -1)
	var limit := int(file.get_value("video", "frame_limit", settings.frame_limit))
	settings.frame_limit = limit if limit in Settings.FRAME_LIMITS else settings.frame_limit
	settings.show_fps = file.get_value("video", "show_fps", settings.show_fps)
	settings.render_scale = file.get_value("video", "render_scale", settings.render_scale)
	settings.camera_distance = clampf(
		file.get_value("video", "camera_distance", settings.camera_distance), 0.0, 1.4
	)
	settings.screen = str(file.get_value("video", "screen", settings.screen))
	if settings.screen not in ViewChoices.SCREENS:
		settings.screen = ViewChoices.default_screen()
	settings.camera_follows = str(
		file.get_value("video", "camera_follows", settings.camera_follows)
	)
	if settings.camera_follows not in ViewChoices.FOLLOWS:
		settings.camera_follows = ViewChoices.FOLLOW_AUTO
	var upscaled := str(file.get_value("video", "upscaler", settings.upscaler))
	settings.upscaler = upscaled if upscaled in Settings.UPSCALERS else settings.upscaler
	var looked := str(file.get_value("video", "look", settings.look))
	settings.look = looked if looked in RenderLook.ids() else settings.look
	settings.show_looks = bool(file.get_value("video", "show_looks", false))
	var shadowed := str(file.get_value("video", "shadows", settings.shadows))
	settings.shadows = shadowed if shadowed in Settings.SHADOW_LEVELS else settings.shadows
	var detail := str(file.get_value("video", "texture_detail", settings.texture_detail))
	settings.texture_detail = (
		detail if detail in Settings.TEXTURE_DETAILS else settings.texture_detail
	)
	settings.ui_scale = clampf(
		file.get_value("video", "ui_scale", settings.ui_scale),
		Settings.UI_SCALES[0],
		Settings.UI_SCALES[-1]
	)
	settings.bloom = clampf(float(file.get_value("video", "bloom", settings.bloom)), 0.0, 1.5)
	settings.occlusion = clampf(
		float(file.get_value("video", "occlusion", settings.occlusion)), 0.0, 1.0
	)
	settings.brightness = clampf(
		float(file.get_value("video", "brightness", settings.brightness)), 0.5, 2.0
	)
	# Kept as one switch, Edge smoothing, until the multisampling and the pass over the picture
	# could each be picked: on was the multisampling, off the pass.
	if file.has_section_key("video", "antialiasing"):
		var smoothed: bool = file.get_value("video", "antialiasing")
		settings.msaa = 2 if smoothed else 0
		settings.screen_smoothing = Settings.SMOOTH_OFF if smoothed else Settings.SMOOTH_FXAA
	var samples := int(file.get_value("video", "msaa", settings.msaa))
	settings.msaa = samples if samples in Settings.MSAA_SAMPLES else settings.msaa
	var smoothing := str(file.get_value("video", "screen_smoothing", settings.screen_smoothing))
	settings.screen_smoothing = (
		smoothing if smoothing in Settings.SMOOTHINGS else settings.screen_smoothing
	)
	# On or off, before there was a choice of how many.
	var marked: Variant = file.get_value("video", "tire_marks", settings.tire_marks)
	if marked is bool:
		settings.tire_marks = Settings.MARKS_FULL if marked else Settings.MARKS_OFF
	elif marked is int and int(marked) >= 0 and int(marked) < Settings.MARKS_NAMES.size():
		settings.tire_marks = marked
	var housed := float(file.get_value("video", "crowd_size", settings.crowd_size))
	settings.crowd_size = housed if housed in Settings.CROWD_SIZES else settings.crowd_size
	# The crowd was a switch of its own before it was a size, and a crowd switched off stays off.
	if not bool(file.get_value("accessibility", "crowd", true)):
		settings.crowd_size = 0.0


## Writes every video setting from [param settings] into [param file].
static func save_from(settings: Settings, file: ConfigFile) -> void:
	file.set_value("video", "fullscreen", settings.fullscreen)
	file.set_value("video", "vsync", settings.vsync)
	file.set_value("video", "window_size", settings.window_size)
	file.set_value("video", "monitor", settings.monitor)
	file.set_value("video", "frame_limit", settings.frame_limit)
	file.set_value("video", "show_fps", settings.show_fps)
	file.set_value("video", "render_scale", settings.render_scale)
	file.set_value("video", "camera_distance", settings.camera_distance)
	file.set_value("video", "screen", settings.screen)
	file.set_value("video", "camera_follows", settings.camera_follows)
	file.set_value("video", "upscaler", settings.upscaler)
	file.set_value("video", "shadows", settings.shadows)
	file.set_value("video", "texture_detail", settings.texture_detail)
	file.set_value("video", "look", settings.look)
	file.set_value("video", "show_looks", settings.show_looks)
	file.set_value("video", "ui_scale", settings.ui_scale)
	file.set_value("video", "bloom", settings.bloom)
	file.set_value("video", "occlusion", settings.occlusion)
	file.set_value("video", "brightness", settings.brightness)
	file.set_value("video", "msaa", settings.msaa)
	file.set_value("video", "screen_smoothing", settings.screen_smoothing)
	file.set_value("video", "tire_marks", settings.tire_marks)
	file.set_value("video", "crowd_size", settings.crowd_size)
