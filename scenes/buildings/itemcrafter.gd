class_name ItemCrafter
extends Building
## Workshop: delivers GameRules.items_per_crafter random items after every round.


func on_round_end() -> void:
	var delivered := GameState.deliver_items(GameState.rules.items_per_crafter)
	if not delivered.is_empty():
		Events.items_delivered.emit(delivered, self)
		_bounce()


func _bounce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 0.9, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.2)
