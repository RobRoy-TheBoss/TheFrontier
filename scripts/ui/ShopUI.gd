## ShopUI
## Generic shop interface used by settlement NPCs.
## Filters items by settlement tier and player inventory.
extends Control

@onready var shop_title: Label = $Panel/ShopTitle
@onready var shop_list: VBoxContainer = $Panel/ShopScroll/ShopList
@onready var player_currency_label: Label = $Panel/PlayerCurrency
@onready var buy_button: Button = $Panel/BuyButton
@onready var sell_button: Button = $Panel/SellButton
@onready var close_button: Button = $Panel/CloseButton

var _settlement_id: String = ""
var _shop_type: String = "general"  # general, weapons, armor, alchemy, hirelings
var _selected_item_id: String = ""
var _player: Node = null


func _ready() -> void:
	add_to_group("shop_ui")
	visible = false
	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if close_button:
		close_button.pressed.connect(_close)
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")


func open_shop(settlement_id: String, shop_type: String) -> void:
	_settlement_id = settlement_id
	_shop_type = shop_type
	_selected_item_id = ""
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()


func _refresh() -> void:
	var s := SettlementManager.get_settlement(_settlement_id)
	if s == null or _player == null:
		return
	if shop_title:
		shop_title.text = _shop_type.capitalize().replace("_", " ") + " — " + _settlement_id.capitalize()
	if player_currency_label:
		player_currency_label.text = "Silver: %d" % _player.inventory.currency
	_populate_shop_list(s)


func _populate_shop_list(s: SettlementManager.SettlementData) -> void:
	if shop_list == null:
		return
	for child in shop_list.get_children():
		child.queue_free()
	var items_to_show := _get_available_items(s)
	for item_entry in items_to_show:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = item_entry.get("name", item_entry.get("id", "?"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var price_lbl := Label.new()
		price_lbl.text = "%d silver" % _get_buy_price(item_entry)
		var weight_lbl := Label.new()
		weight_lbl.text = "%.1fkg" % item_entry.get("weight", 0.0)
		var select_btn := Button.new()
		select_btn.text = "Select"
		var captured_id: String = item_entry.get("id", "")
		select_btn.pressed.connect(func(): _select_item(captured_id))
		row.add_child(name_lbl)
		row.add_child(weight_lbl)
		row.add_child(price_lbl)
		row.add_child(select_btn)
		shop_list.add_child(row)


func _get_available_items(s: SettlementManager.SettlementData) -> Array:
	var result := []
	var tier_id := s.get_tier_id()
	match _shop_type:
		"weapons":
			for wid in GameData.weapons:
				var w: Dictionary = GameData.weapons[wid]
				if _tier_index(w.get("min_settlement_tier", "trading_post")) <= s.tier_index:
					result.append(w)
		"armor":
			for aid in GameData.armor:
				var a: Dictionary = GameData.armor[aid]
				if _tier_index(a.get("min_settlement_tier", "trading_post")) <= s.tier_index:
					if not a.get("requires_warrior", false) or DisciplineManager.has_passive("ironclad"):
						result.append(a)
		"general":
			for iid in GameData.items:
				var item: Dictionary = GameData.items[iid]
				var min_tier: String = item.get("min_purchase_tier", "trading_post")
				if min_tier != "" and _tier_index(min_tier) <= s.tier_index:
					result.append(item)
		"reagents":
			for rid in GameData.reagents:
				var r: Dictionary = GameData.reagents[rid]
				if _tier_index(r.get("min_purchase_tier", "town")) <= s.tier_index:
					result.append(r)
	return result


func _get_buy_price(item: Dictionary) -> int:
	return item.get("value", item.get("base_price", 10))


func _select_item(item_id: String) -> void:
	_selected_item_id = item_id
	if buy_button:
		buy_button.disabled = false


func _on_buy_pressed() -> void:
	if _selected_item_id == "" or _player == null:
		return
	var item_def := GameData.get_item(_selected_item_id)
	if item_def.is_empty():
		item_def = GameData.get_weapon(_selected_item_id)
	if item_def.is_empty():
		item_def = GameData.get_armor(_selected_item_id)
	if item_def.is_empty():
		item_def = GameData.reagents.get(_selected_item_id, {})
	var price := _get_buy_price(item_def)
	if _player.inventory.currency < price:
		return
	_player.inventory.currency -= price
	_player.inventory.add_item(_selected_item_id, 1)
	_refresh()


func _on_sell_pressed() -> void:
	if _selected_item_id == "" or _player == null:
		return
	if not _player.inventory.has_item(_selected_item_id):
		return
	var item_def := GameData.get_item(_selected_item_id)
	if item_def.is_empty():
		item_def = GameData.get_weapon(_selected_item_id)
	if item_def.is_empty():
		item_def = GameData.get_armor(_selected_item_id)
	var sell_price := int(_get_buy_price(item_def) * 0.5)
	_player.inventory.remove_item(_selected_item_id, 1)
	_player.inventory.currency += sell_price
	EconomyManager.player_sell_item(_selected_item_id, 1, _settlement_id)
	_refresh()


func _close() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _tier_index(tier_id: String) -> int:
	var order := ["trading_post", "village", "town", "city"]
	return order.find(tier_id)
