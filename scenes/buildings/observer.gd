class_name Observer
extends Building
## Mines inside its area load trains on purpose instead of randomly:
## the train closest to full gets the item (Unity: inObeservationArea).


func choose_train(source: Building, candidates: Array[Train]) -> Train:
	if not source is Mine or not covers(source.cell):
		return null
	var best: Train = candidates[0]
	for train in candidates:
		if train.load_count > best.load_count:
			best = train
	return best
