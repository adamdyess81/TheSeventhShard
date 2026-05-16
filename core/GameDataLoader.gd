extends Node
class_name GameDataLoader

var card_registry: Dictionary = {}

func load_json(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):
  push_error("JSON file not found: " + path)
  return {}

 var file := FileAccess.open(path, FileAccess.READ)
 if file == null:
  push_error("Failed to open file: " + path)
  return {}

 var content := file.get_as_text()
 file.close()

 var json := JSON.new()
 var parse_result := json.parse(content)

 if parse_result != OK:
  push_error("Failed to parse JSON: %s | Line: %d | Message: %s" % [
   path,
   json.get_error_line(),
   json.get_error_message()
  ])
  return {}

 var data = json.data

 if typeof(data) != TYPE_DICTIONARY:
  push_error("JSON root is not a Dictionary: " + path)
  return {}

 return data

func build_card_registry() -> void:
 card_registry.clear()
 _scan_card_folder("res://data/cards")

func _scan_card_folder(path: String) -> void:
 var dir := DirAccess.open(path)
 if dir == null:
  push_error("Could not open directory: " + path)
  return

 dir.list_dir_begin()
 var file_name := dir.get_next()

 while file_name != "":
  if file_name.begins_with("."):
   file_name = dir.get_next()
   continue

  var full_path := path + "/" + file_name

  if dir.current_is_dir():
   _scan_card_folder(full_path)
  elif file_name.ends_with(".json"):
   var card_data := load_json(full_path)
   if card_data.has("id"):
    var card_id = card_data["id"]
    card_registry[card_id] = card_data
   else:
    push_error("Card JSON missing 'id': " + full_path)



  file_name = dir.get_next()

 dir.list_dir_end()

func get_card(card_id: String) -> Dictionary:
 if not card_registry.has(card_id):
  push_error("Card ID not found in registry: " + card_id)
  return {}

 return card_registry[card_id]

func load_deck(path: String) -> Dictionary:
 return load_json(path)

func resolve_deck_cards(deck_data: Dictionary) -> Array:
 var resolved_cards: Array = []

 if not deck_data.has("cards"):
  push_error("Deck is missing 'cards' array: " + str(deck_data))
  return resolved_cards

 for entry in deck_data["cards"]:
  if not entry.has("card_id") or not entry.has("quantity"):
   push_error("Deck entry missing card_id or quantity: " + str(entry))
   continue

  var card_id: String = str(entry["card_id"])
  var quantity: int = int(entry["quantity"])

  var card_data := get_card(card_id)
  if card_data.is_empty():
   push_error("Could not resolve card in deck: " + card_id)
   continue

  for i in range(quantity):
   resolved_cards.append(card_data.duplicate(true))

 return resolved_cards
func resolve_monster_deck(deck_data: Dictionary) -> Array:
 var resolved_cards: Array = []

 if not deck_data.has("entries"):
  push_error("Monster deck is missing 'entries' array: " + str(deck_data))
  return resolved_cards

 for entry in deck_data["entries"]:
  if not entry.has("card_id") or not entry.has("quantity"):
   push_error("Monster deck entry missing card_id or quantity: " + str(entry))
   continue

  var card_id: String = str(entry["card_id"])
  var quantity: int = int(entry["quantity"])

  var card_data := get_card(card_id)
  if card_data.is_empty():
   push_error("Could not resolve monster deck card: " + card_id)
   continue

  for i in range(quantity):
   resolved_cards.append(card_data.duplicate(true))

 return resolved_cards
func build_shared_deck(player_cards: Array, monster_cards: Array) -> Array:
 var shared_deck: Array = []

 for card in player_cards:
  shared_deck.append(card.duplicate(true))

 for card in monster_cards:
  shared_deck.append(card.duplicate(true))

 shared_deck.shuffle()
 return shared_deck
