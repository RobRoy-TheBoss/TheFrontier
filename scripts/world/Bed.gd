## Bed
## Interactable that triggers the player sleep/auto-save cycle.
extends StaticBody3D


func interact(_player: Node) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_message("Resting...", 1.5)
	BatchProcessor.run_sleep_batch()
