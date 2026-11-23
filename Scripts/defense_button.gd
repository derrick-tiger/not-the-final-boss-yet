extends Button

var defense : DefenseData
var root : Node

func setup(set_to:DefenseData,rt):
	defense = set_to
	root = rt
	icon = set_to.frames.get_frame_texture(&"activated", 0)

func _on_pressed() -> void:
	root.equip_defense(defense)
