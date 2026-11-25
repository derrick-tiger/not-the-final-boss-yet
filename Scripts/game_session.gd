extends Node

@export var main_menu_scene : PackedScene

@export var starting_moves : Array[AttackResource]

@export var starting_slime : CombatantResource
@export var starting_defenses : Array[DefenseData]

@export_file("*.res","*.tres") var starting_evolutions : Array[String]
@export var starting_gold : int = 100

@export var starting_inventory : Dictionary[ItemData,int]

@export var enemy_waves : Array[EnemyWaveData]

@export var starting_allies : Array[CombatantResource]

func _ready() -> void:
	add_child(main_menu_scene.instantiate())
	PlayerData.equipped_attacks = starting_moves
	PlayerData.current_slime = starting_slime
	PlayerData.next_evolution = starting_evolutions
	PlayerData.unlocked_defenses = starting_defenses
	PlayerData.gold = starting_gold
	PlayerData.inventory = starting_inventory
	PlayerData.enemy_evolution = enemy_waves
	PlayerData.current_enemies = enemy_waves[0].wave
	PlayerData.allies = starting_allies
