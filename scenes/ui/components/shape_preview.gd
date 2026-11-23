class_name ShapePreview
extends Control
## Small top-down sketch of a card's piece: one colored square per cell.
## Rails are drawn as if the track continues upwards from the bottom.

const COLORS := {
	"rail_straight": Color(0.55, 0.42, 0.3),
	"rail_curve": Color(0.55, 0.42, 0.3),
	"water": Color(0.25, 0.55, 0.9),
	"mine_gold": Color(0.95, 0.78, 0.2),
	"mine_silver": Color(0.8, 0.82, 0.86),
	"itemcrafter": Color(0.9, 0.5, 0.25),
	"observer": Color(0.65, 0.45, 0.85),
	"marketplace": Color(0.35, 0.75, 0.4),
	"flag_normal": Color(0.9, 0.3, 0.3),
	"flag_pointy": Color(0.9, 0.3, 0.3),
	"station": Color(0.3, 0.35, 0.45),
	"halt": Color(0.5, 0.4, 0.7),
}
const UPGRADE_COLOR := Color(1.0, 0.8, 0.2)
const ENTRY_COLOR := Color(1, 1, 1, 0.35)

var card_id := "":
	set(value):
		card_id = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if card_id == "":
		return
	var def := CardShape.definition(card_id)
	if CardShape.is_upgrade(def) or CardShape.is_tool_card(def):
		var side := minf(size.x, size.y) * 0.6
		draw_circle(size / 2.0, side / 2.0, UPGRADE_COLOR)
		draw_circle(size / 2.0, side / 5.0, Color(0.2, 0.2, 0.2))
		return
	var cells := {}  # Vector2i -> building id
	var entry := Vector2i(999, 999)
	if CardShape.is_rail(def):
		for e in CardShape.rail_layout(def["rail"], Vector2i.ZERO, GridUtil.NORTH):
			cells[e["cell"]] = e["id"]
		entry = Vector2i(0, 1)  # the existing track the piece connects to
	else:
		for e: Array in def["cells"]:
			cells[Vector2i(int(e[0]), int(e[1]))] = e[2]

	var all: Array = cells.keys()
	if entry.x != 999:
		all.append(entry)
	var min_c: Vector2i = all[0]
	var max_c: Vector2i = all[0]
	for c: Vector2i in all:
		min_c = min_c.min(c)
		max_c = max_c.max(c)
	var span := max_c - min_c + Vector2i.ONE
	var cell_size := minf(size.x / span.x, size.y / span.y)
	var origin := (size - Vector2(span) * cell_size) / 2.0
	for c: Vector2i in all:
		var rect := Rect2(origin + Vector2(c - min_c) * cell_size, Vector2.ONE * cell_size).grow(-1.5)
		var color: Color = ENTRY_COLOR if not cells.has(c) else COLORS.get(cells[c], Color.GRAY)
		draw_rect(rect, color)
