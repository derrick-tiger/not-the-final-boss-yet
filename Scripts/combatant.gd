extends Node2D

var max_health : int
var health : int

var shield : int

var display : Node
var root : Node
var resource : CombatantResource
var animated : AnimatedSprite2D

signal finished_anim(atk:AttackResource,target:Node2D,attacker:Node)

@export var damage_popup : PackedScene

func setup(healthdisplay, combatant : CombatantResource, rt,animate):
	display = healthdisplay
	resource = combatant
	root = rt
	health = resource.max_health - resource.pretaken_damage
	display.setup(resource)
	max_health = resource.max_health
	animated = animate

func die():
	if is_instance_valid(display):
		display.queue_free()
	queue_free()

func attack_anim(atk_resource:AttackResource,targ:Node2D):
	var original_pos = global_position
	var target_pos = original_pos.lerp(targ.position,0.8)
	var newtween : Tween = create_tween()
	newtween.tween_property(self,"global_position",target_pos,0.2)
	await newtween.finished
	if animated.sprite_frames.has_animation("attack"):
		animated.play("attack")
	finished_anim.emit(atk_resource,targ,self)
	await get_tree().create_timer(0.5).timeout
	animated.play("idle")
	newtween = create_tween()
	newtween.tween_property(self,"global_position",original_pos,0.2)


func take_damage(attack : AttackResource):
	var final_damage = 0
	final_damage += attack.damage
	final_damage += resource.atk
	final_damage -= resource.def
	if final_damage < 0:
		final_damage = 0
	var reduced = final_damage - shield
	shield -= final_damage
	if reduced >= 0:	
		health -= reduced
	var popup = damage_popup.instantiate()
	add_child(popup)
	popup.position += Vector2(0,-32)
	popup.play(final_damage)
	display.update_health(health)
	display.update_shield(shield)
	var fatal = (health <= 0)
	root.receive_damage_result(attack.name, self, final_damage,fatal)
	if attack.fx_frames != null:
		var hit_effect : AnimatedSprite2D = AnimatedSprite2D.new()
		add_child(hit_effect)
		hit_effect.z_index = 3
		hit_effect.sprite_frames = attack.fx_frames
		hit_effect.play("default")
		hit_effect.position += Vector2(0,-32)
		await hit_effect.animation_finished
		hit_effect.queue_free()

func add_shield(amount : int):
	shield += amount
	display.update_shield(shield)

func heal(amount : int):
	var before : int = health
	health += amount
	if health > max_health:
		health = max_health
	var final_amount : int = health-before
	display.update_health(health)
	root.receive_heal_result(resource.combatant_name,final_amount)
