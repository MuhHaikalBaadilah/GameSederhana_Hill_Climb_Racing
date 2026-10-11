class_name Coin
extends Area2D

signal collected(value: int)

const VALUE := 1

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta * 3.0
	position.y = _base_y + sin(_time) * 5.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("car"):
		collected.emit(VALUE)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color("#e6b422"))
	draw_circle(Vector2.ZERO, 11.0, Color("#f9e076"))
	draw_arc(Vector2.ZERO, 13.5, 0.0, TAU, 32, Color("#c99a1e"), 2.0)
