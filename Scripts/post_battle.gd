extends CanvasLayer

@onready var label : = $Label
@onready var waiting_label : = $Awaiting
@onready var character_holder : = $Node2D

@export var chars_per_second: float = 30.0

@onready var card_hbox : = $CardHbox

@onready var big_label : = $BigLabel
@onready var confirm_button : = $Confirm

@export var card_scene : PackedScene

@export_file("*.tscn") var prep_scene : String

var waiting : bool = false

var _tween: Tween

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
	play_defeat_sequence()

var queue : Array[String]

func play_defeat_sequence():
	queue.append("You lost the battle . . .")
	queue.append("But somehow you returned.")
	queue.append("This time you will come prepared . . .")
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
		var new_card = card_scene.instantiate()
		card_hbox.add_child(new_card)
		new_card.setup_card(i)
		new_card.selected.connect(confirm_select)
	big_label.visible = true
	type_text(big_label,"Pick one")

func confirm_select(card:CardData):
	big_label.visible = false
	if card.slime != null:
		PlayerData.current_slime = card.slime
	PlayerData.atk_bonus += card.atk_bonus
	PlayerData.def_bonus += card.def_bonus
	confirm_button.visible = true

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

func _input(event: InputEvent) -> void:
	if waiting == false : return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			waiting = false
			waiting_label.visible = false
			cont.emit()

func _on_confirm_pressed() -> void:
	SceneLoader.load_scene(prep_scene)
