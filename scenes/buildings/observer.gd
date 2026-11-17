class_name Observer
extends Building
## Mines inside its area load trains on purpose instead of randomly:
## the train closest to full gets the item (Unity: inObeservationArea).


func area_offsets() -> Array[Vector2i]:
	return GridUtil.area_offsets("square")


func observes(target_cell: Vector2i) -> bool:
	return area_offsets().has(target_cell - cell)
