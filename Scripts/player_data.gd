extends Node

var equipped_attacks : Array[AttackResource]
var current_slime : CombatantResource
var current_enemy : CombatantResource
var next_evolution : Array[CardData]
var atk_bonus : int = 0
var def_bonus : int = 0

var defenses : Array[DefenseData]
var unlocked_defenses : Array[DefenseData]
var defense_plots : int = 2
var gold : int = 0

func spend_gold(amount:int) -> bool:
	var after = gold - amount
	if after < 0:
		return false
	else:
		gold -= amount
		return true
