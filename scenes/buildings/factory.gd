class_name Factory
extends Building
## Destination of a rail line. Always has one order: `order_amount` loads of its ore within
## `rounds_left` rounds. Delivered loads pay coins; a finished order pays item cards and
## starts the next one. An expired order puts a curse card into the deck.
## Every new factory wants more than the one before (GameRules.order_base / order_growth).

const ORE_COLORS := {"gold": Color(0.95, 0.75, 0.2), "silver": Color(0.78, 0.8, 0.86)}

## Ore it wants ("gold" / "silver" = served by that mine type). Set by the island.
var ore := "gold"
## 0 = first factory; later ones want more.
var factory_index := 0
var order_amount := 0
var delivered := 0
var rounds_left := 0


func _ready() -> void:
	_build_model()
	if not is_preview:
		new_order()


## Called by the island right after spawning (before _ready finished building the model).
func setup(ore_type: String, index: int) -> void:
	ore = ore_type
	factory_index = index


func new_order() -> void:
	var rules := GameState.rules
	order_amount = rules.order_base + rules.order_growth * factory_index
	delivered = 0
	rounds_left = rules.order_deadline
	_update_info()


func missing() -> int:
	return maxi(order_amount - delivered, 0)


func receive(train: Train) -> void:
	var rules := GameState.rules
	var amount := mini(train.load_count, missing())
	if amount <= 0:
		return
	delivered += amount
	GameState.coins += amount * rules.coins_per_load
	if missing() == 0:
		GameState.coins += rules.coins_per_order
		var reward := GameState.deliver_items(rules.items_per_order)
		Events.items_delivered.emit(reward, self)
		GameState.add_stat("orders_done")
		Events.order_done.emit(self)
		new_order()
	_pulse()
	_update_info()


func on_round_end() -> void:
	rounds_left -= 1
	if rounds_left <= 0:
		GameState.add_curse()
		GameState.add_stat("orders_missed")
		Events.order_expired.emit(self)
		new_order()
	_update_info()


func _update_info() -> void:
	var color := Color(1, 0.5, 0.4) if rounds_left <= 1 else Color.WHITE
	set_info("%s %d/%d · %d R" % [GameData.item_name(ore), delivered, order_amount, rounds_left], color)


## Placeholder model: a hall in the ore's color with a chimney.
func _build_model() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = ORE_COLORS.get(ore, Color.GRAY)
	var hall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.85, 0.5, 0.85)
	box.material = material
	hall.mesh = box
	hall.position.y = 0.25
	add_child(hall)
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.45, 0.25, 0.2)
	var chimney := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.12
	cylinder.height = 0.6
	cylinder.material = roof_material
	chimney.mesh = cylinder
	chimney.position = Vector3(0.22, 0.75, 0.22)
	add_child(chimney)


func _pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.12, 0.9, 1.12), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.25)
