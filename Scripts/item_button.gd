extends Button

var root : Node
var count : int
var data : ItemData


func setup(item_data : ItemData,quantity : int, rt):
	text = item_data.name + " ( " +str(quantity) + "x )"
	icon = item_data.image
	count = quantity
	data = item_data
	root = rt

func _on_pressed() -> void:
	root.confirm_item_use(data)
