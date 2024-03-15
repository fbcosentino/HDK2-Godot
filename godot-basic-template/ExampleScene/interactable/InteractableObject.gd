extends Area3D

signal activated
signal grab_started
signal grab_ended

enum InteractionTypes {
	ACTIVATE,
	GRAB
}
## Activate emits a signal when interacted, but cannot be grabbed.
## Grab can be moved around, and emits a signal when the movement started
## and another one when ended.
@export var interaction_type: InteractionTypes = InteractionTypes.ACTIVATE
# This behaviour does not take place in this script. This variable is only
# used as a storage, and is read externally.

## The node to show or hide when highlighting this object
## If this is an AnimationPlayer, the "show" and "hide" animations
## will be played. If it's a MeshInstance, the Geometry `transparency`
## property will be tweened. If it's anything else, the `visible`
## property will just be set to a boolean.
@export var HighlightNode: Node

var tween

func _ready():
	if HighlightNode:
		if HighlightNode is AnimationPlayer:
			# Force last state of animation
			HighlightNode.play("hide", -1, 1.0, true)
			HighlightNode.advance(0)
			
		elif HighlightNode is MeshInstance3D:
			HighlightNode.transparency = 1.0
		
		else:
			HighlightNode.visible = false


func set_highlight(is_highlighted: bool = false):
	if HighlightNode:
		if HighlightNode is AnimationPlayer:
			HighlightNode.play("show" if is_highlighted else "hide")
		
		elif HighlightNode is MeshInstance3D:
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(HighlightNode, "transparency", 0.0 if is_highlighted else 1.0, 0.15)
		
		else:
			HighlightNode.visible = is_highlighted


