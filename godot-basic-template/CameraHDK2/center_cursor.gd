extends Control

const COLOR_SHOW = Color.WHITE
const COLOR_HIDE = Color(1.0, 1.0, 1.0, 0.0)

@onready var aim_circle = $Aim
@onready var progress = $Progress

var tween

func _ready():
	aim_circle.modulate.a = 0.0

func tween_aim(target_color: Color):
	# Stop a previous tween in case it's still going
	if tween:
		tween.kill()
		
	# Create a new tween for showing
	tween = create_tween()
	tween.tween_property($Aim, "modulate", target_color, 0.15)


func show_aim():
	tween_aim(COLOR_SHOW)

func hide_aim():
	tween_aim(COLOR_HIDE)

func set_progress(normalized_value: float):
	progress.value = normalized_value

func set_progress_dim(dimmed: bool = false):
	progress.modulate.a = 0.5 if dimmed else 1.0
