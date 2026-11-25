extends Node2D


@onready var notif : Label = $CanvasLayer/Control/Notif
@onready var hotbar : = $CanvasLayer/Control/Hotbar/HBoxContainer
@onready var gold_room := $GoldRoom
@onready var path : = $Path
@onready var camera : = $Camera2D
@onready var gold_label : = $CanvasLayer/Control/MoneyLabel
@onready var sell_button : = $CanvasLayer/Control/Sell


@export var platform : PackedScene
@export var defense_button : PackedScene

var _tween : Tween
var chars_per_second : float = 15

var selected_defense : DefenseData

var sell_mode : bool

@export_file("*.tscn") var dungeon_scene : String

func type_text(text_label : Label, text: String) -> Tween:
	text_label.text = text
	text_label.visible_characters = 0
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	var total_chars := text_label.get_total_character_count()
	var duration = total_chars / max(chars_per_second, 0.01)
	
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_characters", total_chars, duration)
	return _tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gold_label.text = str(PlayerData.gold)
	setup()
	await get_tree().create_timer(1).timeout
	notif.visible = true
	var tween = type_text(notif,"The adventurer is back. prepare defenses.")
	await tween.finished
	await get_tree().create_timer(1).timeout
	tween = create_tween()
	tween.tween_property(notif,"modulate:a",0.0,0.5)
	await tween.finished
	notif.visible = false

func setup():
	if len(PlayerData.defenses) < PlayerData.defense_plots:
		PlayerData.defenses.resize(PlayerData.defense_plots-len(PlayerData.defenses))
	for i in PlayerData.unlocked_defenses:
		var new_button = defense_button.instantiate()
		hotbar.add_child(new_button)
		new_button.setup(i,self)
	for i in range(0,PlayerData.defense_plots):
		var new_plot = platform.instantiate()
		add_child(new_plot)
		new_plot.position = Vector2(-133+(i+1)*256,0)
		var existing_defense = null
		if len(PlayerData.defenses) > i:
			existing_defense = PlayerData.defenses[i] 
		new_plot.setup(existing_defense,true,self,i)
	gold_room.position = Vector2(-133+(PlayerData.defense_plots+1)*256,0)
	path.scale = Vector2(12*PlayerData.defense_plots,1)
	path.position = Vector2((gold_room.position.x-133)/2,0)
	camera.max_x = gold_room.position.x + 200

func equip_defense(defense:DefenseData):
	for i in hotbar.get_children():
		if i is Button and i.defense != defense:
			i.button_pressed = false
	if selected_defense == defense:
		selected_defense = null
	else:
		selected_defense = defense

func confirm_building(node:Node2D,id):
	if selected_defense == null or PlayerData.defenses[id] == selected_defense:return
	if PlayerData.spend_gold(selected_defense.cost):
		gold_label.text = str(PlayerData.gold)
		node.set_defense(selected_defense)
		PlayerData.defenses[id] = selected_defense

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_done_pressed() -> void:
	SceneLoader.load_scene(dungeon_scene)

func _on_sell_pressed() -> void:
	sell_mode = not sell_mode
	if sell_mode == true:
		sell_button.text = "Sell mode : on"
	else:
		sell_button.text = "Sell mode : off"
