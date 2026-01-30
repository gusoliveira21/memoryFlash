import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../models/csv_file.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class FlipCardScreen extends StatefulWidget {
  final CsvFile csvFile;

  const FlipCardScreen({super.key, required this.csvFile});

  @override
  State<FlipCardScreen> createState() => _FlipCardScreenState();
}

class _FlipCardScreenState extends State<FlipCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadFlashcards();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    try {
      final flashcards = await FlashcardService.loadFlashcardsFromFile(
        widget.csvFile,
      );
      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _controller.reset();
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _controller.reset();
      });
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voltar'),
        content: const Text('Deseja voltar para a tela anterior?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconBrightness =
        brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _onWillPop().then((shouldPop) {
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        },
        child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(path.basenameWithoutExtension(widget.csvFile.name)),
              if (!_isLoading && _flashcards.isNotEmpty)
                Text(
                  '${_currentIndex + 1} / ${_flashcards.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erro: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFlashcards,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
            : _flashcards.isEmpty
            ? const Center(child: Text('Nenhum flashcard encontrado'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;

                  final cardWidth = screenWidth * 0.7;
                  final cardHeight = cardWidth * (4 / 3);

                  final finalCardHeight = cardHeight > screenHeight * 0.7
                      ? screenHeight * 0.7
                      : cardHeight;
                  final finalCardWidth = finalCardHeight * (3 / 4);

                  return Stack(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _flipCard,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final angle =
                                  _controller.value * 3.14159; // π radians
                              final isFront = _controller.value < 0.5;
                              final currentFlashcard =
                                  _flashcards[_currentIndex];

                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: Container(
                                  width: finalCardWidth,
                                  height: finalCardHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isFront
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.shadow.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(isFront ? 0 : 3.14159),
                                        child: SingleChildScrollView(
                                          child: Text(
                                            isFront
                                                ? currentFlashcard.question
                                                : currentFlashcard.answer,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: isFront
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .onSecondaryContainer,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Seta esquerda
                      if (_currentIndex > 0)
                        Positioned(
                          left: (screenWidth - finalCardWidth) / 2 - 40,
                          top: screenHeight / 2 - 20,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _previousCard,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '<',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_currentIndex < _flashcards.length - 1)
                        Positioned(
                          left: (screenWidth + finalCardWidth) / 2 + 8,
                          top: screenHeight / 2 - 20,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _nextCard,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '>',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        ),  // body: SafeArea
      ),    // Scaffold
      ),    // PopScope
    );      // AnnotatedRegion
  }
}
