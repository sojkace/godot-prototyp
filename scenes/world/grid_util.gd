class_name GridUtil
## Helpers for the square island grid.
## 1 cell = 1 m. Cell (x, y) is centered at world (x, 0, y); the top of a tile is at y = 0.

## Directions in rotation order: a +90° rotation around Y turns each direction into the next one.
const NORTH := 0  # -Z
const WEST := 1   # -X
const SOUTH := 2  # +Z
const EAST := 3   # +X
const DIR_VECTORS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]


static func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x, 0.0, cell.y)


## Direction from one cell to an adjacent cell, or -1 if not adjacent.
static func dir_between(from: Vector2i, to: Vector2i) -> int:
	return DIR_VECTORS.find(to - from)


static func opposite(dir: int) -> int:
	return (dir + 2) % 4


## Number of 90° steps that turn a model with openings `base_dirs` into one with `target_dirs`.
static func steps_for(base_dirs: Array, target_dirs: Array) -> int:
	var target := target_dirs.duplicate()
	target.sort()
	for steps in 4:
		var rotated := []
		for d in base_dirs:
			rotated.append((int(d) + steps) % 4)
		rotated.sort()
		if rotated == target:
			return steps
	push_warning("No rotation found for %s -> %s" % [base_dirs, target_dirs])
	return 0


## Area patterns (offsets around a building), matching the grid_* models from Blender.
## "square": 8 neighbours (gold mine), "cross": 4 direct neighbours (silver mine),
## "diamond": all cells within 2 steps (flag), "long_cross": 4 cells in each direction (pointy flag).
static func area_offsets(shape: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(-4, 5):
		for y in range(-4, 5):
			if x == 0 and y == 0:
				continue
			var keep := false
			match shape:
				"square":
					keep = absi(x) <= 1 and absi(y) <= 1
				"cross":
					keep = absi(x) + absi(y) == 1
				"diamond":
					keep = absi(x) + absi(y) <= 2
				"long_cross":
					keep = x == 0 or y == 0
			if keep:
				result.append(Vector2i(x, y))
	return result
