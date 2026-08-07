import 'flashcard.dart';

class Deck {
  final String id;
  final String name;
  final List<Flashcard> cards;

  Deck({
    required this.id,
    required this.name,
    required this.cards,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cards: (json['cards'] as List<dynamic>?)
              ?.map((item) => Flashcard.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
