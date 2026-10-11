class_name FuelCan
extends Area2D

signal collected(amount: float)

const FUEL_AMOUNT := 35.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("car"):
		collected.emit(FUEL_AMOUNT)
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-14.0, -18.0, 28.0, 36.0), Color("#c0392b"))
	draw_rect(Rect2(-14.0, -18.0, 28.0, 36.0), Color("#7d1f16"), false, 2.0)
	draw_rect(Rect2(-5.0, -22.0, 10.0, 5.0), Color("#7d1f16"))
	draw_rect(Rect2(-9.0, -13.0, 18.0, 26.0), Color("#f5f0e6"), false, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-6.0, 7.0),
		"F",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		18,
		Color("#f5f0e6")
	)
