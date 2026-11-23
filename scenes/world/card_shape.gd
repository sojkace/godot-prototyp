class_name CardShape
## Turns a card definition (see GameRules.cards) into a "layout": the list of cells it
## would occupy, each {"cell": Vector2i, "id": building id, "steps": rotation 0..3}.
## Rail cells also carry "out": the direction the track leaves that cell.
##
## Building cards: offsets from the anchor cell, turned as a whole in 90° steps.
## Rail cards: a path string read in driving direction from the anchor cell:
## F = straight, L = curve left, R = curve right. A rail block is rigid: turning it only
## rotates the whole block (4 headings) or starts it from its other end (rail_variants),
## single pieces never change. Lines may start anywhere; a block connects to a line when
## its openings meet an open end.
## Upgrade cards ({"upgrade": "auto" | "halt", "targets": [...]}) act on one existing building.
## Tool cards ({"tool": "bomb" | "bridge", "coins": cost}) are bought with coins and act on
## one cell; see PlacementRules for where they work.

const RAIL_STRAIGHT := "rail_straight"
const RAIL_CURVE := "rail_curve"
## Openings of the unrotated rail models (see Rail.base_openings).
const RAIL_OPENINGS := {
	RAIL_STRAIGHT: [GridUtil.NORTH, GridUtil.SOUTH],
	RAIL_CURVE: [GridUtil.NORTH, GridUtil.WEST],
}


static func definition(card_id: String) -> Dictionary:
	var cards: Dictionary = GameState.rules.cards
	if cards.has(card_id):
		return cards[card_id]
	# Fallback: a plain building id is a one-cell card.
	return {"name": GameData.building_name(card_id), "cells": [[0, 0, card_id]]}


static func card_name(card_id: String) -> String:
	return definition(card_id).get("name", card_id)


static func icon_id(card_id: String) -> String:
	var def := definition(card_id)
	if def.has("icon"):
		return def["icon"]
	if is_tool_card(def):
		return def["tool"]
	if is_upgrade(def):
		return "auto"
	if is_rail(def):
		return RAIL_STRAIGHT if (def["rail"] as String).begins_with("F") else RAIL_CURVE
	for entry: Array in def["cells"]:
		if entry[2] != "water":
			return entry[2]
	return "water"


static func is_rail(def: Dictionary) -> bool:
	return def.has("rail")


static func is_tool_card(def: Dictionary) -> bool:
	return def.has("tool")


static func is_upgrade(def: Dictionary) -> bool:
	return def.has("upgrade")


## True if the rotate button changes anything for this card.
static func can_turn(def: Dictionary) -> bool:
	return step_count(def) > 1


## Number of different `steps` values worth trying.
static func step_count(def: Dictionary) -> int:
	if is_tool_card(def) or is_upgrade(def):
		return 1
	if is_rail(def):
		return rail_variants(def["rail"]).size() * 4
	return 4 if (def["cells"] as Array).size() > 1 else 1


## The two ways to start the rigid block: with its first end (as drawn) or turned around
## with its other end first. Driving the same track backwards reverses the
## moves and swaps left/right: "FL" -> FL, RF; "L" -> L, R; "LR" (S-curve) only LR.
## No mirroring - that would change the block's shape.
static func rail_variants(path: String) -> Array[String]:
	var reversed := ""
	for i in range(path.length() - 1, -1, -1):
		reversed += path[i]
	var result: Array[String] = [path]
	var turned := _mirror(reversed)
	if turned != path:
		result.append(turned)
	return result


static func _mirror(path: String) -> String:
	return path.replace("L", "x").replace("R", "L").replace("x", "R")


## Rotates a cell offset by 90° steps (same sense as Building.set_rotation_steps).
static func rotate_offset(offset: Vector2i, steps: int) -> Vector2i:
	var result := offset
	for i in posmod(steps, 4):
		result = Vector2i(result.y, -result.x)
	return result


static func layout(def: Dictionary, island: Island, anchor: Vector2i, steps: int) -> Array[Dictionary]:
	if is_rail(def):
		# steps = heading * variant count + variant
		var variants := rail_variants(def["rail"])
		var s := posmod(steps, variants.size() * 4)
		return rail_layout(variants[s % variants.size()], anchor, floori(float(s) / variants.size()))
	if is_upgrade(def):
		var target := island.buildings.get(anchor) as Building
		return [{"cell": anchor, "id": target.type_id() if target else "dirt",
			"steps": target.rotation_steps if target else 0, "upgrade": def["upgrade"]}]
	if is_tool_card(def):
		var tool: String = def["tool"]
		return [{"cell": anchor, "id": "bridge" if tool == "bridge" else "dirt", "steps": 0, "tool": tool}]
	var result: Array[Dictionary] = []
	for entry: Array in def["cells"]:
		result.append({
			"cell": anchor + rotate_offset(Vector2i(int(entry[0]), int(entry[1])), steps),
			"id": entry[2],
			"steps": posmod(steps, 4),
		})
	return result


## Follows the path string from `start` (entered while driving in direction `heading`).
static func rail_layout(path: String, start: Vector2i, heading: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pos := start
	for move in path:
		var back := GridUtil.opposite(heading)
		var out := heading
		if move == "L":
			out = (heading + 1) % 4
		elif move == "R":
			out = (heading + 3) % 4
		var id := RAIL_STRAIGHT if out == heading else RAIL_CURVE
		result.append({
			"cell": pos,
			"id": id,
			"steps": GridUtil.steps_for(RAIL_OPENINGS[id], [back, out]),
			"in": back,
			"out": out,
		})
		pos += GridUtil.DIR_VECTORS[out]
		heading = out
	return result
