class_name Flag
extends Building
## Claims land: when built, every water cell in its area becomes new ground (dirt).
## Area: "diamond" (normal flag) or "long_cross" (pointy flag), set in the scene.


func on_placed() -> void:
	island.claim_land(cell, area_offsets())
