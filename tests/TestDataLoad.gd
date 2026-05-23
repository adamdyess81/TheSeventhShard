extends Node

func _ready() -> void:
 var loader = GameDataLoader.new()

 loader.build_card_registry()

 var starter_deck = loader.load_deck("res://data/decks/starter_knight_deck.json")
 var resolved_player_cards = loader.resolve_deck_cards(starter_deck)

 print("\nRESOLVED STARTER DECK CARD COUNT:")
 print(resolved_player_cards.size())

 var monster_deck = loader.load_deck("res://data/decks/ossaran_lich_deck.json")
 var resolved_monster_cards = loader.resolve_monster_deck(monster_deck)

 print("\nRESOLVED MONSTER DECK CARD COUNT:")
 print(resolved_monster_cards.size())

 var shared_deck = loader.build_shared_deck(resolved_player_cards, resolved_monster_cards)

 print("\nSHARED DECK CARD COUNT:")
 print(shared_deck.size())

 print("\nFIRST 10 SHARED DECK CARDS:")
 for i in range(min(10, shared_deck.size())):
  print(shared_deck[i]["id"])
