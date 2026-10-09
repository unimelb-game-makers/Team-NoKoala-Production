class_name ItemFilter
extends ConveyorBelt

var allowed_items: Array[FactoryItemDefinition] = []
var waiting_items: Array[FactoryItem] = []

func add_item(item: FactoryItem, progress: float = 0.5) -> void:
	if item.stack.item_definition not in allowed_items: 
		waiting_items.append(item)
		return
	if items_on_belt.is_empty():
		register_active(faith_drain_rate)
	items_on_belt.append({"item": item, "progress": progress, "waiting": false})

func has_allowed_item(item: FactoryItemDefinition) -> bool:
	if item in allowed_items: return true
	return false

func _detect_indexed_items(factory_manager: FactoryManager) -> void:
	if not block.block_data.is_placed or factory_manager == null:
		return

	for processable in factory_manager.get_processables_at(block.block_data.root_cell):
		var item := processable as FactoryItem
		if item != null and item.try_claim(self):
			add_item(item)
	
	for processable in waiting_items:
		var item := processable as FactoryItem
		if item != null and item.release_claim(): 
			if item.try_claim(self):
				waiting_items.erase(item)
				add_item(item)
