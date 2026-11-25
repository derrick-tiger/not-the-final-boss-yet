extends Camera2D

var _base_offset := Vector2.ZERO
var _shake_remaining: float = 0.0
var _shake_duration: float = 0.18
var _shake_strength: float = 0.0


func _ready() -> void:
	_base_offset = offset
	set_process(false)


func shake(strength: float = 1.5, duration: float = 0.18) -> void:
	if strength <= 0.0 or duration <= 0.0:
		return
	if _shake_remaining == 0.0:
		_base_offset = offset
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_remaining, duration)
	_shake_remaining = _shake_duration
	set_process(true)


func _process(delta: float) -> void:
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	var decay := pow(_shake_remaining / _shake_duration, 2.0)
	offset = _base_offset + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * decay / zoom
	if _shake_remaining == 0.0:
		offset = _base_offset
		_shake_strength = 0.0
		set_process(false)
