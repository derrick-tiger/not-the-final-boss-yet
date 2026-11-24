extends Control

@onready var name_label : = $Panel/NameLabel
@onready var health_label : = $Panel/HealthLabel
@onready var health : = $Panel/HealthBar
@onready var shield : = $Panel/ShieldBar

func _ready() -> void:
	pass # Replace with function body.

func setup(resource:CombatantResource):
	health.max_value = resource.max_health
	health.value = resource.max_health - resource.pretaken_damage
	name_label.text = "lvl " + str(resource.level) + " " + resource.combatant_name
	health_label.text = str(resource.max_health - resource.pretaken_damage)+"/"+str(resource.max_health)
	shield.max_value = health.max_value
	shield.value = 0

func update_shield(value : int):
	shield.value = value

func update_health(value : int):
	health.value = value
	health_label.text = str(int(health.value))+"/"+str(int(health.max_value))
