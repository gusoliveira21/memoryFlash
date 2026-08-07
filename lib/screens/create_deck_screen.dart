import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/deck_service.dart';

class CreateDeckScreen extends StatefulWidget {
  final Deck? deckToEdit;

  const CreateDeckScreen({super.key, this.deckToEdit});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _nameController = TextEditingController();
  final List<Map<String, TextEditingController>> _cardControllers = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.deckToEdit != null) {
      _nameController.text = widget.deckToEdit!.name;
      for (var card in widget.deckToEdit!.cards) {
        _cardControllers.add({
          'question': TextEditingController(text: card.question),
          'answer': TextEditingController(text: card.answer),
        });
      }
      if (_cardControllers.isEmpty) {
        _addCardField();
      }
    } else {
      _addCardField();
    }
  }

  void _addCardField() {
    setState(() {
      _cardControllers.add({
        'question': TextEditingController(),
        'answer': TextEditingController(),
      });
    });
  }

  void _removeCardField(int index) {
    setState(() {
      _cardControllers[index]['question']?.dispose();
      _cardControllers[index]['answer']?.dispose();
      _cardControllers.removeAt(index);
    });
  }

  Future<void> _saveDeck() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome para o baralho.')),
      );
      return;
    }

    final cards = <Flashcard>[];
    for (var controllers in _cardControllers) {
      final q = controllers['question']!.text.trim();
      final a = controllers['answer']!.text.trim();
      if (q.isNotEmpty && a.isNotEmpty) {
        cards.add(Flashcard(question: q, answer: a));
      }
    }

    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um flashcard válido.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final deck = Deck(
      id: widget.deckToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      cards: cards,
    );

    await DeckService.saveDeck(deck);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controllers in _cardControllers) {
      controllers['question']?.dispose();
      controllers['answer']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckToEdit != null ? 'Editar Baralho' : 'Novo Baralho'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveDeck,
                  tooltip: 'Salvar',
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Baralho',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _cardControllers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_cardControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeCardField(index),
                          ),
                        TextField(
                          controller: _cardControllers[index]['question'],
                          decoration: InputDecoration(
                            labelText: 'Pergunta ${index + 1}',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cardControllers[index]['answer'],
                          decoration: InputDecoration(
                            labelText: 'Resposta ${index + 1}',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCardField,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Carta'),
      ),
    );
  }
}
