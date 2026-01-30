import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/csv_file.dart';
import 'flip_card_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final List<CsvFile> _csvFiles = [];

  @override
  void initState() {
    super.initState();
    _loadCachedFiles();
  }

  Future<void> _loadCachedFiles() async {
    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arquivos CSV')),
      body: SafeArea(
        child: _csvFiles.isEmpty
            ? const Center(child: Text('Nenhum arquivo CSV encontrado'))
            : ListView.builder(
              itemCount: _csvFiles.length,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              itemBuilder: (context, index) {
                final csvFile = _csvFiles[index];
                final fileNameWithoutExtension = path.basenameWithoutExtension(
                  csvFile.name,
                );
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
                            onPressed: () => _deleteCsvFile(index),
                            tooltip: 'Excluir arquivo',
                          ),
                        //const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _openCsvFile(csvFile),
                  ),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
