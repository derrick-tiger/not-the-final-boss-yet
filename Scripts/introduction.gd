extends Node2D

@onready var cam : = $Camera2D
@onready var adventurer : = $Adventurer
@onready var slime : = $Slime
@onready var label : = $CanvasLayer/Label

@export_file("*.tscn") var combat_scene: String

signal finished_moving

func _ready() -> void:
	await get_tree().create_timer(2).timeout
	var tween = type_text(label,"This, is you . . .")
	await tween.finished
	moving = true
	await finished_moving
	tween = tween_camera()
	await tween.finished
	tween = type_text(label,"a level 1 slime.")
	await  tween.finished
	await get_tree().create_timer(2).timeout
	tween = type_text(label,". . .")
	await  tween.finished
	await get_tree().create_timer(2).timeout
	moving = true
	move_speed = 6
	tween = type_text(label,"Good luck.")
	adventurer.play("move")
	await  tween.finished
	await get_tree().create_timer(2).timeout
	SceneLoader.load_scene(combat_scene)

var move_speed : float = 30
var x_cap : float = 150

var distanced_moved : float = 0
var moving : bool = false

var _tween : Tween
var chars_per_second : float = 15

func tween_camera() -> Tween:
	var newtween : Tween = create_tween()
	newtween.tween_property(cam,"position",Vector2(slime.position.x,cam.position.y),1)
	return newtween

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

func _physics_process(delta: float) -> void:
	if moving == false : return
	distanced_moved += delta*move_speed
	cam.position += Vector2(delta*move_speed,0)
	adventurer.position += Vector2(delta*move_speed,0)
	if distanced_moved >= x_cap:
		adventurer.play("idle")
		moving = false
		finished_moving.emit()
		distanced_moved = 0
