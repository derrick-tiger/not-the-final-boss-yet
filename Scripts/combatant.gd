extends Node2D

var max_health : int
var health : int

var display : Node
var root : Node
var resource : CombatantResource

func setup(healthdisplay, combatant : CombatantResource, rt):
	display = healthdisplay
	resource = combatant
	root = rt
	display.setup(resource)
	health = resource.max_health
	max_health = resource.max_health

func die():
	display.queue_free()
	queue_free()

func take_damage(attack : AttackResource):
	var final_damage = 0
	final_damage += attack.damage
	final_damage += resource.atk
	final_damage -= resource.def
	if final_damage < 0:
		final_damage = 0
	health -= final_damage
	display.update_health(health)
	var fatal = (health <= 0)
	root.receive_damage_result(attack.name, self, final_damage,fatal)
