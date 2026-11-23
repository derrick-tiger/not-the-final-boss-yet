extends Control

@onready var name_label : = $Panel/NameLabel
@onready var health_label : = $Panel/HealthLabel
@onready var health : = $Panel/HealthBar

func _ready() -> void:
	pass # Replace with function body.

func setup(resource):
	health.max_value = resource.max_health
	health.value = resource.max_health
	name_label.text = "lvl " + str(resource.level) + " " + resource.combatant_name
	health_label.text = str(resource.max_health)+"/"+str(resource.max_health)

func update_health(value : int):
	health.value = value
	health_label.text = str(int(health.value))+"/"+str(int(health.max_value))
