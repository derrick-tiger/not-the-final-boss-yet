extends Node2D


@onready var player_pos = $PlayerPos
@onready var enemy_pos = $EnemyPos
@onready var interface = $Interface

@export var health_display : PackedScene
@export var shadow_texture : Texture2D
@export var combatant_scene : PackedScene

var enemies : Array[Node2D]
var allies : Array[Node2D]

var turn_index : int = 0

var all_combatants : Array[Node2D]

var display_queue : Array[String]

var battle_status : int
# 0 in combat ; 1 lose ; 2 victory

@export_file("*.tscn") var post_battle_scene: String

func _ready() -> void:
	begin_combat();
	interface.visible = true
	interface.root = self
	assign_turn()

func cont():
	if !display_queue.is_empty():
		interface.display_one()
		return
	if battle_status != 0:
		interface.visible = false
		if battle_status == 1:
			SceneLoader.load_scene(post_battle_scene)
			return
		elif battle_status == 2:
			return
	turn_index += 1
	if turn_index > len(all_combatants)-1:
		turn_index = 0
	assign_turn()

func assign_turn():
	if all_combatants[turn_index].resource.is_enemy == true:
		enemy_action(all_combatants[turn_index])
	else:
		interface.selected_ally = all_combatants[turn_index]
		interface.display_actions()

func begin_combat():
	generate_player()
	generate_enemy()

func enemy_action(enemy:Node2D):
	var randomIndex = randi_range(0,len(enemy.resource.attacks)-1) 
	var randomAttack = enemy.resource.attacks[randomIndex]
	var randomTargetIndex = randi_range(0,len(allies)-1)
	var randomTarget = allies[randomTargetIndex]
	randomTarget.take_damage(randomAttack)

func generate_enemy():
	var new_combatant = combatant_scene.instantiate()
	self.add_child(new_combatant)
	var newenemy = load(PlayerData.current_enemy.scene).instantiate()
	new_combatant.add_child(newenemy)
	new_combatant.position = enemy_pos.position
	var new_display = health_display.instantiate()
	self.add_child(new_display)
	new_display.position = new_combatant.position + Vector2(0,20)
	add_shadow(newenemy)
	new_combatant.setup(new_display,PlayerData.current_enemy,self)
	enemies.append(new_combatant)
	all_combatants.append(new_combatant)

func generate_player():
	var new_combatant = combatant_scene.instantiate()
	self.add_child(new_combatant)
	var newplayer = load(PlayerData.current_slime.scene).instantiate()
	new_combatant.add_child(newplayer)
	new_combatant.position = player_pos.position
	var new_display = health_display.instantiate()
	self.add_child(new_display)
	new_display.position = new_combatant.position + Vector2(0,20)
	var slime_resource : CombatantResource = PlayerData.current_slime.duplicate()
	slime_resource.attacks = PlayerData.equipped_attacks
	slime_resource.atk += PlayerData.atk_bonus
	slime_resource.def += PlayerData.def_bonus
	new_combatant.setup(new_display,slime_resource,self)
	add_shadow(newplayer)
	allies.append(new_combatant)
	all_combatants.append(new_combatant)

func add_shadow(node):
	var new_shadow = Sprite2D.new()
	new_shadow.texture = shadow_texture
	node.add_child(new_shadow)
	new_shadow.position += Vector2(0,-3)
	new_shadow.z_index = -1

func receive_damage_result(attack,target,damage,fatal):
	var set_text = attack + " dealt " + str(damage) + " damage to " + target.resource.combatant_name
	display_queue.append(set_text)
	if fatal:
		display_queue.append(target.resource.combatant_name + " fell in battle to " + attack)
		target.die()
		process_death(target)
	interface.display_one()

func process_death(died):
	if allies.has(died):
		allies.erase(died)
	elif enemies.has(died):
		enemies.erase(died)
	if allies.is_empty():
		display_queue.append("You lost the battle...")
		battle_status = 1
	elif enemies.is_empty():
		display_queue.append("You win this encounter!")
		battle_status = 2

func process_attack(resource, target):
	target.take_damage(resource)
