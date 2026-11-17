class_name Flag
extends Building
## Claims land: when built, every water cell in its area becomes new ground (dirt).

enum AreaShape { DIAMOND, LONG_CROSS }

## DIAMOND = all cells within 2 steps (normal flag), LONG_CROSS = 4 cells in each direction (pointy flag).
@export var area_shape := AreaShape.DIAMOND


func area_offsets() -> Array[Vector2i]:
	return GridUtil.area_offsets("diamond" if area_shape == AreaShape.DIAMOND else "long_cross")
