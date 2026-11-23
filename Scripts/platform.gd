extends Sprite2D

var defense : DefenseData

var build_mode : bool = false

signal clicked(node:Node2D)

@onready var animated : = $Animated
@onready var preview : = $Preview

var root : Node

var id : int = -1

func setup(set_to :DefenseData,mode:bool,rt,identification):
	defense = set_to
	build_mode = mode
	if set_to != null:
		animated.sprite_frames = set_to.frames
		if mode == true:
			animated.play("activated")
		else:
			preview.visible = false
	root = rt
	id = identification

func set_defense(set_to:DefenseData):
	defense = set_to
	if set_to != null:
		animated.sprite_frames = set_to.frames

func _on_click_box_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if build_mode == false:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self,id)

func _on_click_box_mouse_entered() -> void:
	if build_mode:
		preview.visible = true
	else:
		return
	var selected : DefenseData = root.selected_defense
	if selected == null:
		preview.visible = false
		return
	var frames = selected.frames
	preview.sprite_frames = frames

func _on_click_box_mouse_exited() -> void:
	preview.visible = false
