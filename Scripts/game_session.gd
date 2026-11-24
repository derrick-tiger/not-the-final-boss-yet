extends Node

@export var main_menu_scene : PackedScene

@export var starting_moves : Array[AttackResource]

@export var starting_slime : CombatantResource
@export var starting_enemies : Array[CombatantResource]
@export var starting_defenses : Array[DefenseData]

@export_file("*.res","*.tres") var starting_evolutions : Array[String]
@export var starting_gold : int = 100

@export var starting_inventory : Dictionary[ItemData,int]

func _ready() -> void:
	add_child(main_menu_scene.instantiate())
	PlayerData.equipped_attacks = starting_moves
	PlayerData.current_slime = starting_slime
	PlayerData.current_enemies = starting_enemies
	PlayerData.next_evolution = starting_evolutions
	PlayerData.unlocked_defenses = starting_defenses
	PlayerData.gold = starting_gold
	PlayerData.inventory = starting_inventory
