## HomeChest
## Infinite shared home storage — opens StorageUI with GameState.home_storage.
## Satisfies LINV-008 / HOME-001 / INV-003.
extends StaticBody3D


func interact(player: Node) -> void:
	var ui := get_tree().get_first_node_in_group("storage_ui")
	if ui == null:
		push_warning("[HomeChest] StorageUI not found in group 'storage_ui'")
		return
	ui.open(GameState.home_storage, player.inventory)
