class_name Halt
extends Building
## Automation for trains: when the round starts, a halt next to a rail sends a train from a
## station whose area covers that rail cell, without costing an action (see Main.end_round).


## Rail cells next to the halt, nearest first.
func rail_neighbours() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir_vector in GridUtil.DIR_VECTORS:
		if island.buildings.get(cell + dir_vector) is Rail:
			result.append(cell + dir_vector)
	return result
