import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/csv_file.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import 'create_deck_screen.dart';
import 'ai_prompt_screen.dart';
import 'paste_csv_screen.dart';
import 'flip_card_screen.dart';
import 'feedback_screen.dart';
import 'package:get_it/get_it.dart';
import '../presentation/viewmodels/feedback_viewmodel.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final List<CsvFile> _csvFiles = [];
  final List<Deck> _decks = [];
  late FeedbackViewModel _feedbackViewModel;

  @override
  void initState() {
    super.initState();
    _loadCachedFiles();
    
    _feedbackViewModel = GetIt.instance<FeedbackViewModel>();
    _feedbackViewModel.addListener(() {
      if (mounted) {
        setState(() {});
        if (_feedbackViewModel.triggerProactiveAlert) {
          _feedbackViewModel.markAlertAsSeen();
          _showFeedbackDialog();
        }
      }
    });
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deixe sua Sugestão!'),
        content: const Text(
            'Estamos sempre buscando melhorar o Memory Flash. '
            'Você gostaria de deixar um feedback ou sugestão agora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FeedbackScreen()),
              );
            },
            child: const Text('Deixar Feedback'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadCachedFiles() async {
    try {
      final decks = await DeckService.getDecks();
      if (mounted) {
        setState(() {
          _decks.clear();
          _decks.addAll(decks);
        });
      }

      final cacheDir = await getTemporaryDirectory();
      final csvDir = Directory(path.join(cacheDir.path, 'csv_files'));

      if (await csvDir.exists()) {
        final files = csvDir.listSync();
        final csvFiles = <CsvFile>[];

        for (var file in files) {
          if (file is File &&
              path.extension(file.path).toLowerCase() == '.csv') {
            csvFiles.add(
              CsvFile(
                name: path.basename(file.path),
                path: file.path,
                isAsset: false,
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            for (var csvFile in csvFiles) {
              if (!_csvFiles.any((f) => f.path == csvFile.path)) {
                _csvFiles.add(csvFile);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar arquivos do cache: $e');
    }
  }

  Future<void> _addItem() async {
    bool isLoadingDialogOpen = false;

    try {
      if (mounted) {
        isLoadingDialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: false,
      );

      if (mounted && isLoadingDialogOpen) {
        isLoadingDialogOpen = false;
        Navigator.of(context).pop();
      }

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;

        if (pickedFile.path == null || pickedFile.path!.isEmpty) {
          throw Exception(
            'Por favor, selecione um arquivo local. Arquivos do Google Drive não são suportados.',
          );
        }

        final sourceFile = File(pickedFile.path!);
        if (!await sourceFile.exists()) {
          throw Exception(
            'Arquivo não encontrado. Por favor, selecione um arquivo local.',
          );
        }

        final cacheDir = await getTemporaryDirectory();
        final csvDir = Directory(path.join(cacheDir.path, 'csv_files'));

        if (!await csvDir.exists()) {
          await csvDir.create(recursive: true);
        }

        String fileName = pickedFile.name;
        if (fileName.isEmpty) {
          fileName = 'flashcard_${DateTime.now().millisecondsSinceEpoch}.csv';
        }

        String finalFileName = fileName;
        int counter = 1;
        while (await File(path.join(csvDir.path, finalFileName)).exists()) {
          final baseName = path.basenameWithoutExtension(fileName);
          final extension = path.extension(fileName);
          finalFileName = '${baseName}_$counter$extension';
          counter++;
        }

        final destPath = path.join(csvDir.path, finalFileName);

        final destFile = await sourceFile.copy(destPath);

        if (await destFile.exists()) {
          setState(() {
            _csvFiles.add(
              CsvFile(name: finalFileName, path: destFile.path, isAsset: false),
            );
          });

          if (mounted) {
            final fileNameWithoutExtension = path.basenameWithoutExtension(
              finalFileName,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Arquivo $fileNameWithoutExtension importado com sucesso!',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Não foi possível salvar o arquivo no cache');
        }
      }
    } catch (e) {
      if (mounted && isLoadingDialogOpen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar arquivo: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteCsvFile(int index) async {
    final csvFile = _csvFiles[index];

    if (csvFile.isAsset) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Não é possível deletar arquivos de assets'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final fileNameWithoutExtension = path.basenameWithoutExtension(
      csvFile.name,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir arquivo'),
        content: Text(
          'Deseja realmente excluir o arquivo "$fileNameWithoutExtension"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final file = File(csvFile.path);
        if (await file.exists()) {
          await file.delete();
        }

        setState(() {
          _csvFiles.removeAt(index);
        });

        if (mounted) {
          final fileNameWithoutExtension = path.basenameWithoutExtension(
            csvFile.name,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Arquivo $fileNameWithoutExtension excluído com sucesso!',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir arquivo: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _openCsvFile(CsvFile csvFile) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FlipCardScreen(csvFile: csvFile)),
    );
  }

  void _openDeck(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FlipCardScreen(deck: deck)),
    );
  }

  Future<void> _editDeck(Deck deck) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDeckScreen(deckToEdit: deck),
      ),
    );
    if (result == true) {
      _loadCachedFiles();
    }
  }

  Future<void> _deleteDeck(int index) async {
    final deck = _decks[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir baralho'),
        content: Text('Deseja realmente excluir o baralho "${deck.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DeckService.deleteDeck(deck.id);
      _loadCachedFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Baralho ${deck.name} excluído!')),
        );
      }
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.create),
              title: const Text('Criar Novo Baralho'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (!mounted) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateDeckScreen()),
                );
                if (result == true) {
                  _loadCachedFiles();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Importar CSV'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addItem();
              },
            ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('Colar texto CSV'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (!mounted) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PasteCsvScreen()),
                );
                if (result == true) {
                  _loadCachedFiles();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.amber),
              title: const Text('Gerar com IA'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (!mounted) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiPromptScreen()),
                );
                if (!mounted) return;
                if (result == 'import_csv') {
                  _addItem();
                } else if (result == 'paste_csv') {
                  final pasteResult = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PasteCsvScreen()),
                  );
                  if (pasteResult == true) {
                    _loadCachedFiles();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<dynamic>> _buildMenuItems() {
    final items = <PopupMenuEntry<dynamic>>[
      PopupMenuItem<ThemeMode>(
        enabled: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Modo noturno', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(width: 16),
            Switch(
              value: widget.themeMode == ThemeMode.dark,
              onChanged: (value) {
                widget.onThemeModeChanged(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ];

    if (_feedbackViewModel.showFeedbackButton) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<String>(
          value: 'feedback',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.feedback_outlined),
              const SizedBox(width: 16),
              Text('Deixar uma Sugestão', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconBrightness = brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Arquivos CSV'),
          actions: [
            PopupMenuButton<dynamic>(
              icon: const Icon(Icons.menu),
              tooltip: 'Opções',
              onSelected: (value) {
                if (value == 'feedback') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                  );
                }
              },
              itemBuilder: (context) => _buildMenuItems(),
            ),
          ],
        ),
        body: SafeArea(
          child: _csvFiles.isEmpty && _decks.isEmpty
              ? const Center(child: Text('Nenhum baralho encontrado'))
              : ListView.builder(
                  itemCount: _csvFiles.length + _decks.length,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    // Recuo manual para edge-to-edge (barra de navegação)
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemBuilder: (context, index) {
                    if (index < _decks.length) {
                      final deck = _decks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.style),
                          title: Text(
                            deck.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editDeck(deck),
                                tooltip: 'Editar baralho',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () => _deleteDeck(index),
                                tooltip: 'Excluir baralho',
                              ),
                            ],
                          ),
                          onTap: () => _openDeck(deck),
                        ),
                      );
                    } else {
                      final csvIndex = index - _decks.length;
                      final csvFile = _csvFiles[csvIndex];
                      final fileNameWithoutExtension = path
                          .basenameWithoutExtension(csvFile.name);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(
                            fileNameWithoutExtension,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!csvFile.isAsset)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => _deleteCsvFile(csvIndex),
                                  tooltip: 'Excluir arquivo',
                                ),
                            ],
                          ),
                          onTap: () => _openCsvFile(csvFile),
                        ),
                      );
                    }
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddOptions,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
