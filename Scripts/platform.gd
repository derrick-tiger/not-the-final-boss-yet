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
			if animated.sprite_frames.has_animation("activated"):
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

func activate_trap(victim:CombatantResource):
	var before : int = victim.pretaken_damage
	var p_damage = defense.p_damage
	p_damage -= victim.def
	if p_damage < 0:
		p_damage = 0
	victim.pretaken_damage += p_damage
	if victim.pretaken_damage > victim.max_health - 1:
		victim.pretaken_damage = victim.max_health - 1
	var final = victim.pretaken_damage - before
	if animated.sprite_frames.has_animation("activated"):
		animated.play("activated")
	root.display_damage(victim.combatant_name,final,defense.name)

func deactivate():
	if animated.sprite_frames.has_animation("default"):
		animated.play("default")

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
