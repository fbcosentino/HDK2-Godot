extends ReferenceRect

signal aim_alignment_changed(value)
signal side_rotate_changed(value)

@onready var btn_screen_number  = $BtnScreenNumber


func _ready():
	var screen_count = DisplayServer.get_screen_count()
	btn_screen_number.clear()
	
	var found_hdk2_index = -1
	for i in range(screen_count):
		if (found_hdk2_index == -1) and (DisplayServer.screen_get_size(i) == Vector2i(2160, 1200)):
			found_hdk2_index = i
		btn_screen_number.add_item("Screen " + str(i), i)
	print("HDK2 screen: "+str(found_hdk2_index))
	
	btn_screen_number.selected = found_hdk2_index
	
	if found_hdk2_index > -1:
		move_to_screen(found_hdk2_index)
	
	await get_tree().create_timer(0.3).timeout
	emit_signal("aim_alignment_changed", $AimAlignment.value)


func _on_btn_screen_number_item_selected(index):
	move_to_screen(index)


func move_to_screen(screen_index: int):
		DisplayServer.window_set_current_screen(screen_index)


func _on_btn_half_size_toggled(toggled_on):
	var full_size = Vector2i(2160, 1200)
	if toggled_on:
		DisplayServer.window_set_size(full_size/2)
	else:
		DisplayServer.window_set_size(full_size)


func _on_aim_alignment_value_changed(value):
	emit_signal("aim_alignment_changed", value)


func _on_btn_turn_rotate_toggled(toggled_on):
	emit_signal("side_rotate_changed", toggled_on)
