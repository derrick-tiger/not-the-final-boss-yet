extends Node2D

@export var lifetime : float = 0.7

@onready var label : = $Label

func play(amount:int):
	label.text = str(amount)

func _process(delta: float) -> void:
	lifetime -= delta
	position -= Vector2(0,delta*80)
	modulate.a = lifetime/0.7
	if lifetime <= 0:
		queue_free()
