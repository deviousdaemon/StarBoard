extends Label
class_name ActionLabel

var display_time: float = 2.0
var fade_time: float = 0.3

enum STATES{
	FADE_IN=0,
	MAIN=1,
	FADE_OUT=2
}

var tick: float = 0.0
var state: int = STATES.FADE_IN
var displaying_action: bool = false
#var current_action: String = ""


func display_action(action: String) -> void:
#	current_action = action
	state = STATES.FADE_IN
	modulate.a = 0.0
	tick = 0.0
	text = action
	displaying_action = true
	pass

func _process(delta: float) -> void:
	if displaying_action:
		match state:
			STATES.FADE_IN:
				if modulate.a < 1.0:
					modulate.a += delta / fade_time
				else:
					state = STATES.MAIN
					return
			STATES.MAIN:
				if tick < display_time: tick += delta
				else:
					state = STATES.FADE_OUT
					tick = 0.0
					return
			STATES.FADE_OUT:
				if modulate.a > 0:
					modulate.a -= delta / (fade_time * 2)
				else:
					displaying_action = false
					text = ""
	pass
