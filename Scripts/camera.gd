extends Camera2D

# Camera movement bounds in world coordinates
@export var min_x: float = 0.0
@export var max_x: float = 2000.0
@export var min_y: float = 0.0
@export var max_y: float = 1200.0

@export var keep_screen_inside_bounds: bool = true

# Maximum mouse look distance in world units, measured from the base camera position.
@export var mouse_offset_enabled: bool = true
@export var mouse_offset_distance: Vector2 = Vector2(15.0, 10.0)
@export_range(0.0, 30.0, 0.1) var mouse_offset_smoothing: float = 8.0

var _mouse_offset := Vector2.ZERO
var _shake_remaining: float = 0.0
var _shake_duration: float = 0.18
var _shake_strength: float = 0.0

func _ready() -> void:
	_clamp_camera_to_bounds()
	_clamp_mouse_offset()
	_mouse_offset = offset


func shake(strength: float = 1.5, duration: float = 0.18) -> void:
	if duration <= 0.0 or strength <= 0.0:
		return
	# Refresh repeated hits without adding their strengths together.
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_remaining, duration)
	_shake_remaining = _shake_duration


func _process(delta: float) -> void:
	_clamp_camera_to_bounds()
	var target_offset := Vector2.ZERO
	var viewport_rect := get_viewport_rect()
	var mouse_position := get_viewport().get_mouse_position()
	if mouse_offset_enabled and get_window().has_focus() and viewport_rect.has_point(mouse_position):
		# -1 at the left/top, 0 at the center, +1 at the right/bottom.
		var mouse_direction := (mouse_position - viewport_rect.get_center()) / (viewport_rect.size * 0.5)
		target_offset = mouse_direction * mouse_offset_distance

	if mouse_offset_smoothing <= 0.0:
		_mouse_offset = target_offset
	else:
		_mouse_offset = _mouse_offset.lerp(target_offset, 1.0 - exp(-mouse_offset_smoothing * delta))
	offset = _mouse_offset
	_clamp_mouse_offset()
	_mouse_offset = offset
	if _shake_remaining > 0.0:
		_shake_remaining = maxf(0.0, _shake_remaining - delta)
		var decay := pow(_shake_remaining / _shake_duration, 2.0)
		offset += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * decay / zoom
		_clamp_mouse_offset()
		if _shake_remaining == 0.0:
			_shake_strength = 0.0


func _clamp_camera_to_bounds() -> void:
	global_position = _get_clamped_position_for_zoom(global_position, zoom)


func _clamp_mouse_offset() -> void:
	# Camera2D.offset can bypass built-in limits, so clamp the displayed center too.
	offset = _get_clamped_position_for_zoom(global_position + offset, zoom) - global_position


func _get_clamped_position_for_zoom(camera_position: Vector2, camera_zoom: Vector2) -> Vector2:
	if keep_screen_inside_bounds:
		var half_screen_size := get_viewport_rect().size * 0.5 / camera_zoom

		var left_limit := min_x + half_screen_size.x
		var right_limit := max_x - half_screen_size.x
		var top_limit := min_y + half_screen_size.y
		var bottom_limit := max_y - half_screen_size.y

		var clamped_position := camera_position

		if left_limit > right_limit:
			clamped_position.x = (min_x + max_x) * 0.5
		else:
			clamped_position.x = clampf(camera_position.x, left_limit, right_limit)

		if top_limit > bottom_limit:
			clamped_position.y = (min_y + max_y) * 0.5
		else:
			clamped_position.y = clampf(camera_position.y, top_limit, bottom_limit)

		return clamped_position

	else:
		return Vector2(
			clampf(camera_position.x, min_x, max_x),
			clampf(camera_position.y, min_y, max_y)
		)
