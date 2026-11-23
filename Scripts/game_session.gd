extends Node

@export var main_menu_scene : PackedScene

@export var starting_moves : Array[AttackResource]

@export var starting_slime : CombatantResource
@export var starting_enemy : CombatantResource
@export var starting_defenses : Array[DefenseData]

@export var starting_evolutions : Array[CardData]
@export var starting_gold : int = 100

func _ready() -> void:
	add_child(main_menu_scene.instantiate())
	PlayerData.equipped_attacks = starting_moves
	PlayerData.current_slime = starting_slime
	PlayerData.current_enemy = starting_enemy
	PlayerData.next_evolution = starting_evolutions
	PlayerData.unlocked_defenses = starting_defenses
	PlayerData.gold = starting_gold
