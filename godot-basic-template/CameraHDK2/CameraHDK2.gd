@tool
extends Node3D

# This project uses last collision layer (bit 31, layer 32) for the
# interactables you can select with your aim and holding click
# The real aim raycast is fired from the right eye (that will only
# be relevant for objects really _reeeally_ close to the camera)


signal interaction_fired(target_object: Area3D)

@export var interpupillary_distance: float = 0.063:
	set(new_value):
		interpupillary_distance = new_value
		_update_interpupillary_distance()

@export var cam_left: Camera3D
@export var cam_right: Camera3D
@export var flip_180: bool = false:
	set(new_value):
		flip_180 = new_value
		_update_flip_180()

@export var cursor_raycast_length: float = 3.0:
	set(new_value):
		cursor_raycast_length = new_value
		_update_raycast_length()

## The time the player has to hold the cursor to activate it
@export var cursor_hold_time := 1.0
var cursor_hold_speed = 1.0/cursor_hold_time

enum GrabModes {
	AUTOMATIC_TRANSFORM,
	AUTOMATIC_POSITION_ONLY,
	CUSTOM_CODE
}
@export var grab_mode: GrabModes = GrabModes.AUTOMATIC_TRANSFORM

@onready var display: Control = $Display
@onready var cursor_left = $Display/LeftEye/CenterCursor
@onready var cursor_right = $Display/RightEye/CenterCursor
@onready var cursor_raycast: RayCast3D = $Display/RightEye/RightEyeRender/SubViewport/CameraRight/CursorRaycast
@onready var grab_reference: Node3D = $GrabReference
@onready var aim_left = $Display/LeftEye/CenterCursor
@onready var aim_right = $Display/RightEye/CenterCursor

var is_cursor_visible := false
var is_loading_cursor_progress := false
var current_cursor_progress := 0.0
var last_object_at_aim = null
var current_grab_object = null

func _ready():
	_update_interpupillary_distance()
	_update_raycast_length()
	_update_flip_180()


func _update_raycast_length():
	# It's possible this is called before the node is ready, in that case
	# cursor_raycast will be null and we must not touch it
	if cursor_raycast:
		cursor_raycast.target_position = Vector3.FORWARD * cursor_raycast_length


func _update_flip_180():
	if display:
		display.rotation = PI if flip_180 else 0.0

func _update_interpupillary_distance():
	if cam_left:
		var tf_left: Transform3D = global_transform
		tf_left.origin += (-0.5)*tf_left.basis.x*interpupillary_distance
		cam_left.global_transform = tf_left
	if cam_right:
		var tf_right: Transform3D = global_transform
		tf_right.origin += (0.5)*tf_right.basis.x*interpupillary_distance
		cam_right.global_transform = tf_right


func set_aim_alignment(value):
	aim_left.position.x = int(540 - value)
	aim_right.position.x = int(540 + value)

func _process(_delta):
	_update_interpupillary_distance()
	


func _physics_process(delta):
	# Get current object under aim
	var current_object_at_aim: Area3D = null
	
	# If we are grabbing something, don't go through any of the pick logic
	# Just update the object transform
	if current_grab_object != null:
		match grab_mode:
			GrabModes.AUTOMATIC_TRANSFORM:
				current_grab_object.global_transform = grab_reference.global_transform
			GrabModes.AUTOMATIC_POSITION_ONLY:
				current_grab_object.global_transform.origin = grab_reference.global_transform.origin

	
	else:
		# It's possible this is called before the node is ready, in that case
		# cursor_raycast will be null and we must not touch it
		if cursor_raycast:
			if cursor_raycast.is_colliding():
				var collider = cursor_raycast.get_collider()
				if collider is Area3D:
					current_object_at_aim = collider
		# We only bother if it has changed:
		if current_object_at_aim != last_object_at_aim:
			if last_object_at_aim != null:
				# Lost focus of a previous object -> note this might not only
				# happen when moving to empty space, but also moving to a new object
				stop_holding() # in case it was being held
				if last_object_at_aim.has_method("set_highlight"):
					last_object_at_aim.set_highlight(false) # un-highlight previous object 
			
			if current_object_at_aim != null:
				# We just aimed at a new one -> either coming from empty space
				# or from a different previous object
				if current_object_at_aim.has_method("set_highlight"):
					current_object_at_aim.set_highlight(true)
				
				# Regardless of previous state, aim is controlled by current state only
				# show_cursors_aim() and hide_cursors_aim() are safe to be called 
				# multiple times as they have internal IF
				# (ut this section only runs on target change anyways)
				_show_cursors_aim()
			else:
				_hide_cursors_aim()
			
			last_object_at_aim = current_object_at_aim
			
		
		# If currently holding down, do the thing with the wheel
		if is_loading_cursor_progress and (current_cursor_progress < 1.0):
			current_cursor_progress += (cursor_hold_speed * delta)
			_set_cursor_progress(current_cursor_progress)
			
			if (current_cursor_progress >= 1.0):
				# Finished loading/holding
				match last_object_at_aim.interaction_type:
					last_object_at_aim.InteractionTypes.ACTIVATE:
						_fire_interaction()
						stop_holding()
					last_object_at_aim.InteractionTypes.GRAB:
						start_grabbing()

func start_holding():
	if (not is_loading_cursor_progress): # makes it safe to double-call
		if last_object_at_aim:
			current_cursor_progress = 0.0
			_set_cursor_progress(0.0)
			set_cursor_progress_dim(false)
			is_loading_cursor_progress = true

func stop_holding():
	if current_grab_object:
		stop_grabbing()
	if current_grab_object or is_loading_cursor_progress: # makes it safe to double-call
		current_cursor_progress = 0.0
		_set_cursor_progress(0.0)
		is_loading_cursor_progress = false


func start_grabbing():
	if not current_grab_object: # avoids multiple grabs
		current_grab_object = last_object_at_aim
		set_cursor_progress_dim(true)
		current_grab_object.emit_signal("grab_started")
		if grab_mode in [GrabModes.AUTOMATIC_TRANSFORM, GrabModes.AUTOMATIC_POSITION_ONLY]:
			grab_reference.global_transform = current_grab_object.global_transform 
		print("started grabbing: "+str(current_grab_object))

func stop_grabbing():
	current_grab_object.emit_signal("grab_ended")
	current_grab_object = null
	set_cursor_progress_dim(false)
	grab_reference.global_transform = Transform3D()
	print("stopped grabbing")

# Duplicate (to both eyes) the calls to show, hide and progress:
func _show_cursors_aim():
	if not is_cursor_visible: # makes it safe to double-call
		is_cursor_visible = true
		cursor_left.show_aim()
		cursor_right.show_aim()
func _hide_cursors_aim():
	if is_cursor_visible: # makes it safe to double-call
		is_cursor_visible = false
		cursor_left.hide_aim()
		cursor_right.hide_aim()
func _set_cursor_progress(normalized_progress: float):
	cursor_left.set_progress(normalized_progress)
	cursor_right.set_progress(normalized_progress)
func set_cursor_progress_dim(dimmed: bool = false):
	cursor_left.set_progress_dim(dimmed)
	cursor_right.set_progress_dim(dimmed)
	


func _fire_interaction():
	if last_object_at_aim != null:
		emit_signal("interaction_fired", last_object_at_aim)
		last_object_at_aim.emit_signal("activated")
