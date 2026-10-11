class_name StarRating
extends Control
## Deret bintang (digambar sendiri agar tidak tergantung glyph font).

var max_stars := 3
var stars := 0:
	set(value):
		stars = clampi(value, 0, max_stars)
		queue_redraw()


func _init(p_max_stars: int = 3) -> void:
	max_stars = p_max_stars
	custom_minimum_size = Vector2(max_stars * 28.0, 28.0)


func _draw() -> void:
	var radius := 11.0
	for i in max_stars:
		var center := Vector2(14.0 + i * 28.0, 14.0)
		var color := Color("#f1c40f") if i < stars else Color(1.0, 1.0, 1.0, 0.22)
		_draw_star(center, radius, color)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var ang := -PI / 2.0 + k * (PI / 5.0)
		var r := radius if k % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, color)
