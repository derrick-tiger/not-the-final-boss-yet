extends Node

var equipped_attacks : Array[AttackResource]
var current_slime : CombatantResource
var current_enemies : Array[CombatantResource]
var next_evolution : Array[String]
var atk_bonus : int = 0
var def_bonus : int = 0
var allies : Array[CombatantResource]

var defenses : Array[DefenseData]
var unlocked_defenses : Array[DefenseData]
var defense_plots : int = 2
var gold : int = 0

var inventory : Dictionary[ItemData,int]

var enemy_evolution : Array[EnemyWaveData]

var outcome_victory : bool = false
#give the player a free upgrade at the start of the game
var encounter_ind : int = 0

func spend_gold(amount:int) -> bool:
	var after = gold - amount
	if after < 0:
		return false
	else:
		gold -= amount
		return true
