import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/flashcard.dart';
import '../models/csv_file.dart';

class FlashcardService {
  static Future<List<Flashcard>> loadFlashcardsFromFile(CsvFile csvFile) async {
    try {
      String data;

      if (csvFile.isAsset) {
        data = await rootBundle.loadString(csvFile.path);
      } else {
        final file = File(csvFile.path);
        data = await file.readAsString();
      }

      return parseFlashcardsFromText(data);
    } catch (e) {
      throw Exception('Erro ao carregar flashcards: $e');
    }
  }

  static List<Flashcard> parseFlashcardsFromText(String data) {
    final List<String> lines = const LineSplitter().convert(data);
    final List<Flashcard> flashcards = [];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final List<String> parts = parseCsvLine(line);

      if (parts.length >= 2) {
        flashcards.add(
          Flashcard(question: parts[0].trim(), answer: parts[1].trim()),
        );
      }
    }

    return flashcards;
  }

  static List<String> parseCsvLine(String line) {
    final List<String> result = [];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current);
    return result;
  }
}
