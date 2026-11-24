extends Node2D

const DEATH_SHADER: Shader = preload("res://Shaders/death_dissolve.gdshader")
@export_range(0.1, 3.0, 0.05) var death_effect_duration: float = 1.2
@export_range(1, 8, 1) var death_chunk_size: int = 2

signal death_effects_finished
var _pending_deaths: int = 0


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

var enemycount : int

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
		if _pending_deaths > 0:
			await death_effects_finished
		SceneLoader.load_scene(post_battle_scene)
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
	for i in PlayerData.current_enemies:
		generate_enemy(i)

func enemy_action(enemy:Node2D):
	var randomIndex = randi_range(0,len(enemy.resource.attacks)-1) 
	var randomAttack = enemy.resource.attacks[randomIndex]
	var randomTargetIndex = randi_range(0,len(allies)-1)
	var randomTarget = allies[randomTargetIndex]
	process_attack(randomAttack,randomTarget,enemy)

func generate_enemy(index):
	var new_combatant = combatant_scene.instantiate()
	self.add_child(new_combatant)
	var newenemy = load(index.scene).instantiate()
	new_combatant.add_child(newenemy)
	new_combatant.position = enemy_pos.position
	new_combatant.position += Vector2(enemycount*70,enemycount*-5)
	var new_display = health_display.instantiate()
	new_display.z_index = -2
	self.add_child(new_display)
	new_display.position = new_combatant.position + Vector2(0,20)
	add_shadow(newenemy)
	new_combatant.setup(new_display,index,self,newenemy.get_node("AnimatedSprite2D"))
	enemies.append(new_combatant)
	all_combatants.append(new_combatant)
	enemycount += 1

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
	new_combatant.setup(new_display,slime_resource,self,newplayer.get_node("AnimatedSprite2D"))
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
		process_death(target)
	interface.display_one()

func process_death(died):
	if not allies.has(died) and not enemies.has(died):
		return
	if allies.has(died):
		allies.erase(died)
	elif enemies.has(died):
		enemies.erase(died)
	# Remove it now so no later turn can select a dying/freed combatant.
	var dead_index: int = all_combatants.find(died)
	if dead_index >= 0:
		all_combatants.remove_at(dead_index)
		if dead_index <= turn_index:
			turn_index -= 1
	if allies.is_empty():
		display_queue.append("You lost the battle...")
		PlayerData.outcome_victory = false
		battle_status = 1
	elif enemies.is_empty():
		display_queue.append("You win this encounter!")
		PlayerData.outcome_victory = true
		battle_status = 2

	_pending_deaths += 1
	if is_instance_valid(died.display):
		died.display.queue_free()
	var death_tween := create_tween().set_parallel(true)
	# Give each sprite its own material so living combatants are unaffected.
	for node in died.find_children("*", "AnimatedSprite2D", true, false):
		var sprite := node as AnimatedSprite2D
		sprite.stop()
		var death_material := ShaderMaterial.new()
		death_material.shader = DEATH_SHADER
		death_material.set_shader_parameter("progress", 0.0)
		_create_death_flakes(sprite, death_material)
		death_tween.tween_property(death_material, "shader_parameter/progress", 1.0, death_effect_duration)
	# Fade shadows too, and provide a fallback for combatants without animated sprites.
	for node in died.find_children("*", "Sprite2D", true, false):
		death_tween.tween_property(node, "modulate:a", 0.0, death_effect_duration)
	death_tween.tween_interval(death_effect_duration)
	await death_tween.finished
	if is_instance_valid(died):
		died.die()
	_pending_deaths -= 1
	if _pending_deaths == 0:
		death_effects_finished.emit()


func _create_death_flakes(sprite: AnimatedSprite2D, material: ShaderMaterial) -> void:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var size := texture.get_size()
	var texture_origin := Vector2.ZERO
	# Resolve atlas frames to sheet UVs without sampling adjacent animation frames.
	while texture is AtlasTexture:
		texture_origin += (texture as AtlasTexture).region.position
		texture = (texture as AtlasTexture).atlas
	var origin := sprite.offset - (size * 0.5 if sprite.centered else Vector2.ZERO)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var row_count := ceili(size.y / death_chunk_size)
	for y in range(0, int(size.y), death_chunk_size):
		for x in range(0, int(size.x), death_chunk_size):
			var end := Vector2(minf(x + death_chunk_size, size.x), minf(y + death_chunk_size, size.y))
			var corners := [Vector2(x, y), Vector2(end.x, y), end, Vector2(x, end.y)]
			var center := (Vector2(x, y) + end) * 0.5 / size
			if sprite.flip_h:
				center.x = 1.0 - center.x
			if sprite.flip_v:
				center.y = 1.0 - center.y
			var row := row_count - 1 - y / death_chunk_size if sprite.flip_v else y / death_chunk_size
			var metadata := Color(center.x, center.y, float(row) / row_count, 1.0)
			var first := vertices.size()
			for corner: Vector2 in corners:
				uvs.append((texture_origin + corner) / texture.get_size())
				var point := corner
				if sprite.flip_h:
					point.x = size.x - point.x
				if sprite.flip_v:
					point.y = size.y - point.y
				point += origin
				vertices.append(Vector3(point.x, point.y, 0.0))
				colors.append(metadata)
			indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Moving flakes need a larger culling rectangle than the original sprite.
	mesh.custom_aabb = AABB(Vector3(origin.x - 80, origin.y - 80, -1), Vector3(size.x + 160, size.y + 160, 2))
	var flakes := MeshInstance2D.new()
	flakes.name = "DeathFlakes"
	flakes.mesh = mesh
	flakes.texture = texture
	flakes.material = material
	flakes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flakes.z_index = sprite.z_index
	flakes.transform = sprite.transform
	material.set_shader_parameter("frame_size", size)
	material.set_shader_parameter("frame_origin", origin)
	material.set_shader_parameter("rows", float(row_count))
	material.set_shader_parameter("sprite_tint", sprite.modulate * sprite.self_modulate)
	sprite.get_parent().add_child(flakes)
	sprite.hide()

func process_attack(resource, target,attacker):
	attacker.attack_anim(resource,target)
	attacker.finished_anim.connect(follow_through_attack)
	
func follow_through_attack(resource,target,attacker):
	if attacker.finished_anim.is_connected(follow_through_attack):
		attacker.finished_anim.disconnect(follow_through_attack)
	target.take_damage(resource)

func process_item_use(resource : ItemData):
	if resource.health_gain > 0:
		all_combatants[turn_index].heal(resource.health_gain)

func request_shield():
	var amount = all_combatants[turn_index].resource.def+1
	all_combatants[turn_index].add_shield(amount)
	var set_text = all_combatants[turn_index].resource.combatant_name + " gained " + str(amount) + " shield"
	display_queue.append(set_text)
	interface.Actions.visible = false
	interface.display_one()

func receive_heal_result(combat_name,amount):
	var set_text = combat_name + " healed for " + str(amount) + " health"
	display_queue.append(set_text)
	interface.display_one()
