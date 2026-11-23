extends Camera2D


@export var drag_speed: float = 1.0
@export var drag_mouse_button: MouseButton = MOUSE_BUTTON_LEFT

# Bounds for the camera center, in world coordinates.
@export var min_x: float = -500.0
@export var max_x: float = 500.0
@export var min_y: float = -500.0
@export var max_y: float = 500.0

var _dragging := false


func _ready() -> void:
	_clamp_to_bounds()


func _unhandled_input(event: InputEvent) -> void:
	# Start only when the click wasn't consumed by a UI control.
	if event is InputEventMouseButton and event.button_index == drag_mouse_button:
		_dragging = event.pressed


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == drag_mouse_button and not event.pressed:
		_dragging = false
	elif _dragging and event is InputEventMouseMotion:
		# Convert screen movement to world movement, then move against the drag.
		var world_drag := get_viewport().get_canvas_transform().affine_inverse().basis_xform(event.relative)
		global_position -= world_drag * drag_speed
		_clamp_to_bounds()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_dragging = false


func _clamp_to_bounds() -> void:
	global_position = Vector2(
		clampf(global_position.x, min_x, max_x),
		clampf(global_position.y, min_y, max_y)
	)
