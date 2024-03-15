extends Node3D

@export var emulate_tracking_from_mouse: bool = false
var emulate_angles := Vector3.ZERO

@onready var player = $Player
@onready var headset = $Player/CameraHDK2
@onready var head_tracking = $HeadTrackingHDK2

const HALF_PI = PI/2.0


func _ready():
	headset.interaction_fired.connect(_on_interaction_fired)
	headset.flip_180 = emulate_tracking_from_mouse
	head_tracking.tracker_data_received.connect(_on_tracker_data_received)
	get_window().focus_entered.connect(_on_window_focus_entered)
	get_window().focus_exited.connect(_on_window_focus_exited)
	AppSidePopup.panel.aim_alignment_changed.connect(_on_aim_alignment_changed)
	AppSidePopup.panel.side_rotate_changed.connect(_on_side_rotate_changed)

# Captures the mouse on focus if we are emulating head movement from mouse
func _on_window_focus_entered():
	#if emulate_tracking_from_mouse:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _on_window_focus_exited():
	#if emulate_tracking_from_mouse:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event):
	if Input.is_action_just_pressed("interact"):
		headset.start_holding()
	elif Input.is_action_just_released("interact"):
		headset.stop_holding()
	
	if emulate_tracking_from_mouse and get_window().has_focus():
		if event is InputEventMouseMotion:
			emulate_angles.y -= event.relative.x*0.003
			emulate_angles.x = clamp(emulate_angles.x - event.relative.y*0.003, -HALF_PI, HALF_PI)
			#print(emulate_angles.y)
			
			head_tracking.emit_signal("tracker_data_received", emulate_angles)
			#headset.rotation = emulate_angles


func _on_tracker_data_received(euler_angles: Vector3):
	headset.rotation.x = euler_angles.x
	headset.rotation.z = euler_angles.z
	
	player.set_headset_rotation_y(euler_angles.y)

func _on_aim_alignment_changed(value):
	headset.set_aim_alignment(value)

func _on_side_rotate_changed(value):
	player.side_rotate_instead_of_strafe = value

func _on_interaction_fired(target_object: Area3D):
	print("Fired object: " + str(target_object))
	pass


func _on_interactable_object_3_activated():
	$Objects/Popup/Label3D/AnimationPlayer.play("Popup")
