extends Node2D


@onready var notif : Label = $CanvasLayer/Control/Notif
@onready var gold_room := $GoldRoom
@onready var path : = $Path
@onready var camera : = $Camera2D

@export var platform : PackedScene

var _tween : Tween
var chars_per_second : float = 15

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
	for i in range(0,PlayerData.defense_plots):
		var new_plot = platform.instantiate()
		add_child(new_plot)
		new_plot.position = Vector2(-133+(i+1)*256,0)
		var existing_defense = null
		if len(PlayerData.defenses) > i:
			existing_defense = PlayerData.defenses[i] 
		new_plot.setup(existing_defense,false,self,i)
	gold_room.position = Vector2(-133+(PlayerData.defense_plots+1)*256,0)
	path.scale = Vector2(12*PlayerData.defense_plots,1)
	path.position = Vector2((gold_room.position.x-133)/2,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
