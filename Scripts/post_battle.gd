extends CanvasLayer

@onready var label : = $Label
@onready var waiting_label : = $Awaiting
@onready var character_holder : = $Node2D

@export var chars_per_second: float = 30.0
# 1.0 = normal speed; 2.0 = twice as fast; 0.5 = half speed.
@export_range(0.1, 5.0, 0.1, "or_greater") var card_burn_speed: float = 1.0

@onready var card_hbox : = $CardHbox

@onready var big_label : = $BigLabel
@onready var confirm_button : = $Confirm
@onready var retry_button : = $Retry

@export var card_scene : PackedScene

@export_file("*.tscn") var prep_scene : String

const CARD_BURN_SHADER: Shader = preload("res://Shaders/card_burn.gdshader")

var waiting : bool = false

var _tween: Tween

var card_burn_orb_texture: GradientTexture2D
var card_burn_process_material: ParticleProcessMaterial
var card_burn_material_template: ShaderMaterial
var _card_selected: bool = false

signal cont

func type_text(label : Label, text: String) -> Tween:
	label.text = text
	label.visible_characters = 0
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	var total_chars := label.get_total_character_count()
	var duration = total_chars / max(chars_per_second, 0.01)
	
	_tween = create_tween()
	_tween.tween_property(label, "visible_characters", total_chars, duration)
	return _tween

func tween_character():
	var original_pos : Vector2 = character_holder.position
	character_holder.position = Vector2(160,260)
	var newtween : Tween
	newtween = create_tween()
	newtween.tween_property(character_holder,"position",original_pos,1.5)

func _ready() -> void:
	_initialize_card_burn()

	if PlayerData.outcome_victory:
		queue.append("You won this time.")
		queue.append("Keep adapting.")
		queue.append("You won't be the only one getting stronger.")
		PlayerData.current_enemies = PlayerData.enemy_evolution[PlayerData.encounter_ind].wave
		for i in PlayerData.enemy_evolution[PlayerData.encounter_ind].trap_unlocks:
			PlayerData.unlocked_defenses.append(i)
		play_sequence()
	else:
		if PlayerData.encounter_ind == 0:
			queue.append("You lost the battle . . .")
			queue.append("But somehow you returned.")
			queue.append("This time you will come prepared . . .")
			play_sequence()
		else:
			queue.append("Retry?")
			next()
			await cont
			retry_button.visible = true
			
	PlayerData.encounter_ind += 1

var queue : Array[String]
	
func play_sequence():
	next()
	await cont
	var new_player_scene = load(PlayerData.current_slime.scene).instantiate()
	character_holder.add_child(new_player_scene)
	tween_character()
	next()
	await cont
	next()
	await cont
	var tween : Tween = create_tween()
	tween.tween_property(label,"modulate:a",0.0,0.5)
	await tween.finished
	await get_tree().create_timer(1).timeout
	label.visible = false
	card_hbox.visible = true
	for i in PlayerData.next_evolution:
		var card = load(i)
		var new_card = card_scene.instantiate()
		card_hbox.add_child(new_card)
		new_card.setup_card(card)
		new_card.selected.connect(confirm_select)
	big_label.visible = true
	type_text(big_label,"Pick one")

func confirm_select(card:CardData,node):
	if _card_selected:
		return
	_card_selected = true
	for choice in card_hbox.get_children():
		choice.get_node("Button").disabled = true
		choice.get_node("Outline").hide()
	_dismiss_unpicked_cards(node)
	big_label.visible = false
	if card.slime != null:
		PlayerData.current_slime = card.slime
	if !card.moves.is_empty():
		for i in card.moves:
			PlayerData.equipped_attacks.append(i)
	PlayerData.atk_bonus += card.atk_bonus
	PlayerData.def_bonus += card.def_bonus
	PlayerData.next_evolution = card.evolutions
	if !card.ally_list.is_empty():
		PlayerData.allies = card.ally_list
	await _run_card_burn(node)
	confirm_button.visible = true


func _dismiss_unpicked_cards(selected: Control) -> void:
	var choices := card_hbox.get_children()
	var positions: Array[Vector2] = []
	for choice: Control in choices:
		positions.append(choice.global_position)
	for index in range(choices.size()):
		var choice := choices[index] as Control
		# Free the cards from HBox layout so it cannot reset the tween or shift
		# the selected card when another card disappears.
		choice.reparent(self, true)
		choice.global_position = positions[index]
		if choice == selected:
			continue
		var exit_y := get_viewport().get_visible_rect().position.y - choice.get_global_rect().size.y - 16.0
		var exit_tween := create_tween()
		exit_tween.tween_property(choice, "global_position:y", exit_y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		exit_tween.tween_callback(choice.queue_free)
	card_hbox.hide()

func next():
	var text = type_text(label,queue[0])
	queue.pop_at(0)
	await text.finished
	await  get_tree().create_timer(0.5).timeout
	if !queue.is_empty():
		waiting_label.visible = true
		waiting = true
	else:
		cont.emit()

func _initialize_card_burn() -> void:
	card_burn_material_template = ShaderMaterial.new()
	card_burn_material_template.shader = CARD_BURN_SHADER
	card_burn_material_template.set_shader_parameter("flash_amount", 0.0)
	card_burn_material_template.set_shader_parameter("burn_progress", 0.0)
	# A radial 2D texture replaces the imported SphereMesh draw pass.
	var orb_gradient := Gradient.new()
	orb_gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	orb_gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	card_burn_orb_texture = GradientTexture2D.new()
	card_burn_orb_texture.width = 8
	card_burn_orb_texture.height = 8
	card_burn_orb_texture.fill = GradientTexture2D.FILL_RADIAL
	card_burn_orb_texture.fill_from = Vector2(0.5, 0.5)
	card_burn_orb_texture.fill_to = Vector2(1.0, 0.5)
	card_burn_orb_texture.gradient = orb_gradient
	card_burn_process_material = ParticleProcessMaterial.new()
	card_burn_process_material.particle_flag_disable_z = true
	card_burn_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	card_burn_process_material.direction = Vector3(0, -1, 0)
	card_burn_process_material.spread = 42.0
	card_burn_process_material.initial_velocity_min = 12.0
	card_burn_process_material.initial_velocity_max = 32.0
	card_burn_process_material.gravity = Vector3(0, -12, 0)
	card_burn_process_material.scale_min = 0.3
	card_burn_process_material.scale_max = 0.7
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	card_burn_process_material.color_ramp = fade_texture


func _run_card_burn(display: Control) -> void:
	var burn_speed := maxf(card_burn_speed, 0.01)
	if card_burn_material_template == null:
		_initialize_card_burn()
	display.get_node("Button").hide()
	display.get_node("Outline").hide()
	var materials: Array[ShaderMaterial] = []
	# Each TextureRect keeps its own texture; both use one card-space burn edge.
	for item in display.find_children("*", "TextureRect", true, false):
		var material := card_burn_material_template.duplicate() as ShaderMaterial
		var local: Transform2D = display.get_global_transform().affine_inverse() * item.get_global_transform()
		material.set_shader_parameter("card_size", display.size)
		material.set_shader_parameter("element_origin", local.origin)
		material.set_shader_parameter("element_x", local.x)
		material.set_shader_parameter("element_y", local.y)
		item.use_parent_material = false
		item.material = material
		materials.append(material)
	var flash := create_tween().set_parallel(true)
	flash.set_speed_scale(burn_speed)
	for material in materials:
		flash.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.1)
	# Printed text disappears into the white flash rather than remaining over the ash.
	for item in display.find_children("*", "Label", true, false):
		flash.tween_property(item, "modulate:a", 0.0, 0.1)
	await flash.finished
	var particles := _create_card_burn_particles()
	particles.speed_scale = burn_speed
	var process_material := card_burn_process_material.duplicate() as ParticleProcessMaterial
	process_material.emission_box_extents = Vector3(display.size.x * 0.5, display.size.y * 0.025, 0)
	particles.process_material = process_material
	display.add_child(particles)
	_update_card_burn(0.0, materials, particles, display.size)
	particles.emitting = true
	var burn := create_tween()
	burn.set_speed_scale(burn_speed)
	burn.tween_method(_update_card_burn.bind(materials, particles, display.size), 0.0, 1.0, 1.0)
	await burn.finished
	particles.emitting = false
	# Let already-emitted orbs finish before hiding the card and cleaning up.
	await get_tree().create_timer(particles.lifetime / burn_speed).timeout
	particles.queue_free()
	display.hide()


func _update_card_burn(value: float, materials: Array[ShaderMaterial], particles: GPUParticles2D, size: Vector2) -> void:
	for material in materials:
		material.set_shader_parameter("burn_progress", value)
	particles.position = Vector2(size.x * 0.5, (1.055 - value * 1.16) * size.y)

func _create_card_burn_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = "BurnOrbs"
	particles.amount = 24
	particles.lifetime = 0.42
	particles.randomness = 0.72
	particles.emitting = false
	particles.visibility_rect = Rect2(-160, -160, 320, 320)
	particles.local_coords = false
	particles.process_material = card_burn_process_material
	particles.texture = card_burn_orb_texture
	return particles


func _input(event: InputEvent) -> void:
	if waiting == false : return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			waiting = false
			waiting_label.visible = false
			cont.emit()

func _on_confirm_pressed() -> void:
	SceneLoader.load_scene(prep_scene)

func _on_retry_pressed() -> void:
	SceneLoader.load_scene(prep_scene)
