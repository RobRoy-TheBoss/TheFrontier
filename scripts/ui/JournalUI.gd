## JournalUI
## Field journal display. Shows all recorded entries organized by category.
extends Control

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var note_input: TextEdit = $Panel/NoteInput
@onready var note_title_input: LineEdit = $Panel/NoteTitleInput
@onready var add_note_button: Button = $Panel/AddNoteButton

var _journal: FieldJournal = null


func _ready() -> void:
	add_to_group("journal_ui")
	visible = false
	await get_tree().process_frame
	_journal = get_tree().get_first_node_in_group("field_journal")
	if _journal:
		_journal.entry_added.connect(_on_entry_added)
	if add_note_button:
		add_note_button.pressed.connect(_on_add_note_pressed)


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	if not visible or _journal == null:
		return
	_populate_tabs()


func _populate_tabs() -> void:
	if tab_container == null:
		return
	for child in tab_container.get_children():
		child.queue_free()

	var categories := [
		{ "name": "Creatures", "type": FieldJournal.EntryType.CREATURE },
		{ "name": "Ingredients", "type": FieldJournal.EntryType.INGREDIENT },
		{ "name": "Sites", "type": FieldJournal.EntryType.PRECURSOR_SITE },
		{ "name": "Places of Power", "type": FieldJournal.EntryType.PLACE_OF_POWER },
		{ "name": "Resources", "type": FieldJournal.EntryType.RESOURCE },
		{ "name": "Landmarks", "type": FieldJournal.EntryType.LANDMARK },
		{ "name": "Notes", "type": FieldJournal.EntryType.NOTE }
	]

	for cat in categories:
		var scroll := ScrollContainer.new()
		scroll.name = cat["name"]
		var vbox := VBoxContainer.new()
		scroll.add_child(vbox)

		var entries := _journal.get_entries_of_type(cat["type"])
		if entries.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "No entries yet."
			vbox.add_child(empty_lbl)
		else:
			for entry in entries:
				var panel := PanelContainer.new()
				var content := VBoxContainer.new()
				var title := Label.new()
				title.text = entry.get("name", entry.get("title", entry.get("id", "Unknown")))
				title.add_theme_font_size_override("font_size", 14)
				content.add_child(title)

				var details := Label.new()
				details.text = entry.get("description", entry.get("body", entry.get("notes", "")))
				details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				content.add_child(details)

				var day_lbl := Label.new()
				day_lbl.text = "Day %d" % entry.get("day", 1)
				day_lbl.add_theme_color_override("font_color", Color.GRAY)
				content.add_child(day_lbl)

				panel.add_child(content)
				vbox.add_child(panel)

		tab_container.add_child(scroll)


func _on_add_note_pressed() -> void:
	if _journal == null:
		return
	var title := note_title_input.text.strip_edges() if note_title_input else "Note"
	var body := note_input.text.strip_edges() if note_input else ""
	if body == "":
		return
	_journal.add_note(title, body)
	if note_input:
		note_input.text = ""
	if note_title_input:
		note_title_input.text = ""


func _on_entry_added(_entry: Dictionary) -> void:
	if visible:
		_refresh()
