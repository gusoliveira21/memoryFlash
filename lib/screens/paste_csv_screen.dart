import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import '../services/flashcard_service.dart';

class PasteCsvScreen extends StatefulWidget {
  const PasteCsvScreen({super.key});

  @override
  State<PasteCsvScreen> createState() => _PasteCsvScreenState();
}

class _PasteCsvScreenState extends State<PasteCsvScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _csvController = TextEditingController();

  Future<void> _saveDeck() async {
    final name = _nameController.text.trim();
    final csvContent = _csvController.text.trim();

    if (name.isEmpty || csvContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha o nome e cole o texto.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final flashcards = FlashcardService.parseFlashcardsFromText(csvContent);
      
      if (flashcards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum flashcard válido encontrado no texto.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final deck = Deck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        cards: flashcards,
      );

      await DeckService.saveDeck(deck);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar texto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colar Texto CSV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDeck,
            tooltip: 'Salvar Baralho',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Novo Baralho',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _csvController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Cole aqui o texto gerado pela IA',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
