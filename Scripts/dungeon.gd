extends Node2D


@onready var notif : Label = $CanvasLayer/Control/Notif
@onready var gold_room := $GoldRoom
@onready var entrance : = $Entrance
@onready var path : = $Path
@onready var camera : = $Camera2D
@onready var result_panel : = $CanvasLayer/Control/Panel
@onready var result_label : = $CanvasLayer/Control/Panel/ResultLabel
@onready var cont_label : = $CanvasLayer/Control/Panel/ContinueLabel

var adventurers : Array[Node2D]
var adventurer_res : Array[CombatantResource]

@export var platform : PackedScene
@export var shadow : Texture2D

var _tween : Tween
var chars_per_second : float = 15

var defense_nodes : Array[Node2D]

@export_file("*.tscn") var combat_scene: String

signal finished_moving

func type_text(text_label : Label, text: String, custom_cps : float = 15) -> Tween:
	text_label.text = text
	text_label.visible_characters = 0
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	var total_chars := text_label.get_total_character_count()
	var duration = total_chars / max(custom_cps, 0.01)
	
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_characters", total_chars, duration)
	return _tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in PlayerData.current_enemies:
		i.pretaken_damage = 0
	idle_all()
	setup()
	await get_tree().create_timer(1).timeout
	moving = true
	move_all()
	notif.visible = true
	var tween = type_text(notif,"The adventurer returns.")
	await tween.finished
	await get_tree().create_timer(1).timeout
	tween = create_tween()
	tween.tween_property(notif,"modulate:a",0.0,0.5)
	await tween.finished
	notif.visible = false

func setup():
	for i in range(0,PlayerData.defense_plots):
		var new_plot = platform.instantiate()
		add_child(new_plot)
		new_plot.position = Vector2(-133+(i+1)*256,0)
		var existing_defense = null
		if len(PlayerData.defenses) > i:
			existing_defense = PlayerData.defenses[i] 
		new_plot.setup(existing_defense,false,self,i)
		defense_nodes.append(new_plot)
	gold_room.position = Vector2(-133+(PlayerData.defense_plots+1)*256,0)
	path.scale = Vector2(12*PlayerData.defense_plots,1)
	path.position = Vector2((gold_room.position.x-133)/2,0)
	for i in PlayerData.current_enemies:
		var new_adventurer = AnimatedSprite2D.new()
		add_child(new_adventurer)
		new_adventurer.position = entrance.position + Vector2(len(adventurers)*-10,-16)
		new_adventurer.sprite_frames = i.simplified_frames
		new_adventurer.play("idle")
		var new_shadow = Sprite2D.new()
		new_shadow.texture = shadow
		new_shadow.position += Vector2(0,16)
		new_adventurer.z_index = 1
		new_adventurer.add_child(new_shadow)
		adventurers.append(new_adventurer)
		adventurer_res.append(i)

var move_speed : float = 45
var x_cap : float = 256

var distanced_moved : float = 0
var moving : bool = false

var defense_index : int = 0

func finished_step():
	if defense_index == PlayerData.defense_plots:
		idle_all()
		await  get_tree().create_timer(1).timeout
		SceneLoader.load_scene(combat_scene)
		return
	if PlayerData.defenses[defense_index] != null:
		idle_all()
		defense_nodes[defense_index].activate_trap(adventurer_res[0])
	else:
		moving = true
		defense_index += 1
	
func display_damage(victim,damage,defense):
	result_panel.visible = true
	var set_text = victim + " took " + str(damage) + " damage from " + defense
	var tween = type_text(result_label,set_text,30)
	await tween.finished
	awaiting_cont = true
	cont_label.visible = true

var awaiting_cont : bool = false

func confirm_cont():
	awaiting_cont = false
	moving = true
	defense_nodes[defense_index].deactivate()
	move_all()
	cont_label.visible = false
	result_panel.visible = false
	defense_index += 1

func _unhandled_input(event: InputEvent) -> void:
	if awaiting_cont == false : return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			confirm_cont()

func idle_all():
	for i in adventurers:
		i.play("idle")
func move_all():
	for i in adventurers:
		i.play("move")
func set_position_all(x):
	for i in adventurers:
		i.position += Vector2(x,0)

func _physics_process(delta: float) -> void:
	if moving == false : return
	distanced_moved += delta*move_speed
	if camera.position.x < gold_room.position.x:
		camera.position += Vector2(delta*move_speed,0)
	set_position_all(delta*move_speed)
	if distanced_moved >= x_cap:
		moving = false
		finished_moving.emit()
		finished_step()
		distanced_moved -= 256
