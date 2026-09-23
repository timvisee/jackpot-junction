extends SceneTree
## Development aid: runs [KartMotor] headless against a scripted driving program and prints a
## CSV trace of the motor and [KartRev] state, so sound models can be prototyped offline against
## the real handling and checked against what the game will actually play.
## Usage: tools/godot --headless --path . -s tools/trace_drive.gd ++ --out=trace.csv

const STEP := 1.0 / 60.0


func _initialize() -> void:
	var out := "trace.csv"
	var program := "lap"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
		elif arg.begins_with("--program="):
			program = arg.get_slice("=", 1)
	var stats: KartStats = load("res://data/kart/default.tres")
	var sound: KartSoundStats = load("res://data/kart/sound.tres")
	var motor := KartMotor.new(stats)
	var rev := KartRev.new(sound)
	var input := KartInput.new()
	var lines: PackedStringArray = [
		(
			"t,speed,forward,fraction,throttle,brake,handbrake,steer,drift,slip,nitro,spin,"
			+ "boost,turbo,rev,pitch,load,engine_db"
		)
	]
	var script := _program(program)
	var duration: float = script[script.size() - 1]["until"]
	var t := 0.0
	while t < duration:
		var entry := _at(script, t)
		input.throttle = entry.get("throttle", 0.0)
		input.brake = entry.get("brake", 0.0)
		input.steer = entry.get("steer", 0.0)
		input.handbrake = entry.get("handbrake", false)
		input.nitro = entry.get("nitro", false)
		if entry.get("spin", false) and not motor.spinning():
			motor.apply_spin_out(1.0)
		if entry.get("turbo", false) and not motor.turboing():
			motor.apply_turbo(motor.forward_vector())
		motor.nitro_bonus = stats.nitro_speed_multiplier if input.nitro else 1.0
		motor.step(input, STEP)
		rev.step(motor, input, STEP)
		lines.append(
			(
				"%.4f,%.4f,%.4f,%.4f,%.3f,%.3f,%d,%.3f,%d,%.4f,%d,%d,%d,%d,%.4f,%.4f,%.4f,%.2f"
				% [
					t,
					motor.speed(),
					motor.forward_speed,
					motor.speed() / stats.top_speed,
					input.throttle,
					input.brake,
					1 if input.handbrake else 0,
					motor.steer,
					1 if motor.drifting else 0,
					motor.slip_angle(),
					1 if input.nitro else 0,
					1 if motor.spinning() else 0,
					1 if motor.boosting() else 0,
					1 if motor.turboing() else 0,
					rev.rev,
					rev.pitch(),
					rev.load,
					rev.volume_db(),
				]
			)
		)
		t += STEP
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("wrote %s, %d rows" % [out, lines.size() - 1])
	quit()


## The entry in force at [param t]: the first whose "until" has not passed yet.
func _at(script: Array, t: float) -> Dictionary:
	for entry: Dictionary in script:
		if t < float(entry["until"]):
			return entry
	return script[script.size() - 1]


func _program(name: String) -> Array:
	match name:
		"launch":
			# Sitting still, a blip of throttle, then a standing start to the limiter and back.
			return [
				{"until": 1.0},
				{"until": 1.4, "throttle": 1.0},
				{"until": 2.2},
				{"until": 7.0, "throttle": 1.0},
				{"until": 9.0},
				{"until": 11.0, "brake": 1.0},
			]
		"drift":
			# Up to speed, then a long handbrake drift and out of it.
			return [
				{"until": 3.0, "throttle": 1.0},
				{"until": 5.5, "throttle": 1.0, "steer": 1.0, "handbrake": true},
				{"until": 8.0, "throttle": 1.0},
				{"until": 10.0, "brake": 1.0},
			]
		"nitro":
			return [
				{"until": 2.5, "throttle": 1.0},
				{"until": 4.5, "throttle": 1.0, "nitro": true},
				{"until": 7.0, "throttle": 1.0},
				{"until": 9.0},
			]
		_:
			# A lap: standing start, corner on the handbrake, nitro down the straight, heavy
			# braking, a spin on oil, reverse out of it and away again.
			return [
				{"until": 0.8},
				{"until": 4.0, "throttle": 1.0},
				{"until": 6.0, "throttle": 1.0, "steer": 0.9, "handbrake": true},
				{"until": 7.0, "throttle": 1.0, "steer": 0.4},
				{"until": 9.0, "throttle": 1.0, "nitro": true},
				{"until": 10.0, "throttle": 1.0},
				{"until": 11.5, "brake": 1.0},
				{"until": 12.0, "throttle": 1.0},
				{"until": 12.1, "throttle": 1.0, "spin": true},
				{"until": 14.0},
				{"until": 15.5, "brake": 1.0},
				{"until": 19.0, "throttle": 1.0},
				{"until": 20.0, "throttle": 1.0, "turbo": true},
				{"until": 23.0, "throttle": 1.0},
				{"until": 25.0},
			]
