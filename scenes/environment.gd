extends StaticBody2D

func _ready() -> void:
	$Polygon2D.polygon = $CollisionPolygon2D.polygon
