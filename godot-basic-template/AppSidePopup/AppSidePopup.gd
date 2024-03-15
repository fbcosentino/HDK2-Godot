extends Window

@onready var panel = $AppSidePopupPanel

func _ready():
	popup()
	DisplayServer.window_set_current_screen(0, get_window_id())




func _on_close_requested():
	get_tree().quit()
