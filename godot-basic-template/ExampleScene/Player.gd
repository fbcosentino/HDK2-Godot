extends CharacterBody3D

signal turn_angle_changed

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var side_rotate_instead_of_strafe := false
var turn_angle := 0.0
var headset_angle := 0.0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir_y = Input.get_axis("ui_up", "ui_down") 
	var input_dir_x := 0.0
	#Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if side_rotate_instead_of_strafe:
		if Input.is_action_just_pressed("ui_left"):
			turn_angle += PI/2.0
			if turn_angle > TAU:
				turn_angle -= TAU
			rotation.y = headset_angle + turn_angle
		
		if Input.is_action_just_pressed("ui_right"):
			turn_angle -= PI/2.0
			if turn_angle < 0:
				turn_angle += TAU
			rotation.y = headset_angle + turn_angle
	
	else:
		input_dir_x = Input.get_axis("ui_left", "ui_right") 
	
	var direction = (transform.basis * Vector3(input_dir_x, 0, input_dir_y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func set_headset_rotation_y(angle):
	headset_angle = angle
	rotation.y = headset_angle + turn_angle
