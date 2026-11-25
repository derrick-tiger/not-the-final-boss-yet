extends Button

var target : Node2D
var root : Node

@onready var label = $NameLabel

var mode : bool = false

func setup_target(targ : Node2D, rt : Node, md:bool) -> void:
	target = targ
	root = rt
	icon = null
	mode = md
	label.text = target.resource.combatant_name
	if not is_instance_valid(target):
		return
	var container : = target.get_child(0)
	if container == null : return
	var sprite := container.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames := sprite.sprite_frames
	if frames.has_animation(&"idle") and frames.get_frame_count(&"idle") > 0:
		icon = frames.get_frame_texture(&"idle", 0)
	
func _on_pressed() -> void:
	if mode == true:
		root.confirm_target(target)
	elif mode == false:
		root.confirm_observation(target)
