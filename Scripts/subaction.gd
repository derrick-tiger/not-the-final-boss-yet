extends Button

var attack_resource : AttackResource
var root

func setup_attack(resource: AttackResource, rt : Node):
	attack_resource = resource
	root = rt

func _on_pressed() -> void:
	root.receive_attack(attack_resource)
