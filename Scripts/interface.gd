extends CanvasLayer

@onready var DisplayLabel : = $Panel/DisplayLabel
@onready var Actions : = $Panel/Actions
@onready var Attack : = $Panel/Actions/Attack
@onready var AttacksFlow : = $Panel/Attacks
@onready var ReturnButton : = $Panel/Attacks/Return
@onready var Targets : = $Panel/Targets
@onready var CancelButton : = $Panel/Targets/Cancel
@onready var ResultLabel : = $Panel/ResultLabel
@onready var ContinueLabel : = $Panel/ContinueLabel
@onready var InventoryPanel : = $InventoryPanel
@onready var InventoryGrid : = $InventoryPanel/GridContainer
@onready var MainPanel : = $Panel

@export var subaction_button : PackedScene
@export var target_button : PackedScene
@export var inventory_button : PackedScene

var root : Node2D

var selected_attack : AttackResource

var awaiting_continue : bool
var selected_ally : Node2D

func display_actions():
	Actions.visible = true
	DisplayLabel.text = "Select action"

func _on_attack_pressed() -> void:
	Actions.visible = false
	display_attacks()

func display_attacks():
	DisplayLabel.text = "Select attack"
	AttacksFlow.visible = true
	for i in selected_ally.resource.attacks:
		var new_button = subaction_button.instantiate()
		new_button.text = i.name
		new_button.setup_attack(i,self)
		AttacksFlow.add_child(new_button)
	AttacksFlow.move_child(ReturnButton,-1)

func display_targets():
	DisplayLabel.text = "Choose target"
	Targets.visible = true
	for i in root.enemies:
		var new_targetbutton = target_button.instantiate()
		new_targetbutton.setup_target(i, self)
		Targets.add_child(new_targetbutton)
	Targets.move_child(CancelButton,-1)

func confirm_target(target):
	root.process_attack(selected_attack,target,root.all_combatants[root.turn_index])
	clean_targets()
	Targets.visible = false

func receive_attack(attack : AttackResource):
	selected_attack = attack
	clean_attacks()
	AttacksFlow.visible = false
	display_targets()

func clean_attacks():
	for i in AttacksFlow.get_children():
		if i.name != "Return":
			i.queue_free()

func clean_targets():
	for i in Targets.get_children():
		if i.name != "Cancel":
			i.queue_free()

@export var chars_per_second: float = 30.0

var _tween: Tween

func type_text(label : Label, text: String) -> Tween:
	DisplayLabel.text = ""
	label.text = text
	label.visible_characters = 0
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	var total_chars := label.get_total_character_count()
	var duration = total_chars / max(chars_per_second, 0.01)
	
	_tween = create_tween()
	_tween.tween_property(label, "visible_characters", total_chars, duration)
	return _tween

func display_one():
	ResultLabel.visible = true
	ContinueLabel.visible = false
	var tween = type_text(ResultLabel,root.display_queue[0])
	root.display_queue.pop_at(0)
	await tween.finished
	ContinueLabel.visible = true
	awaiting_continue = true

func _on_return_pressed() -> void:
	clean_attacks()
	AttacksFlow.visible = false
	display_actions()

func display_inventory():
	InventoryPanel.visible = true
	MainPanel.visible = false
	for i in PlayerData.inventory:
		var new_button = inventory_button.instantiate()
		new_button.setup(i,PlayerData.inventory[i],self)
		InventoryGrid.add_child(new_button)

func clean_inventory():
	for i in InventoryGrid.get_children():
		i.queue_free()
	InventoryPanel.visible = false
	MainPanel.visible = true

func confirm_item_use(data : ItemData):
	PlayerData.inventory[data] -= 1
	if PlayerData.inventory[data] <= 0:
		PlayerData.inventory.erase(data)
	root.process_item_use(data)
	Actions.visible = false
	clean_inventory()

func _unhandled_input(event: InputEvent) -> void:
	if awaiting_continue == false : return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			ResultLabel.visible = false
			ContinueLabel.visible = false
			root.cont()
			awaiting_continue = false

func _on_cancel_pressed() -> void:
	clean_targets()
	Targets.visible = false
	display_attacks()

func _on_item_pressed() -> void:
	display_inventory()

func _on_inventory_close_pressed() -> void:
	clean_inventory()

func _on_defend_pressed() -> void:
	root.request_shield()
