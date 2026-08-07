import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/deck.dart';

class DeckService {
  static Future<Directory> _getDecksDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final decksDir = Directory('${docDir.path}/decks');
    if (!await decksDir.exists()) {
      await decksDir.create(recursive: true);
    }
    return decksDir;
  }

  static Future<List<Deck>> getDecks() async {
    final decksDir = await _getDecksDirectory();
    final List<Deck> decks = [];

    final files = decksDir.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          decks.add(Deck.fromJson(json));
        } catch (e) {
          debugPrint('Erro ao carregar deck: $e');
        }
      }
    }
    
    return decks;
  }

  static Future<void> saveDeck(Deck deck) async {
    final decksDir = await _getDecksDirectory();
    final file = File('${decksDir.path}/${deck.id}.json');
    final jsonString = jsonEncode(deck.toJson());
    await file.writeAsString(jsonString);
  }

  static Future<void> deleteDeck(String id) async {
    final decksDir = await _getDecksDirectory();
    final file = File('${decksDir.path}/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
