import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiPromptScreen extends StatefulWidget {
  const AiPromptScreen({super.key});

  @override
  State<AiPromptScreen> createState() => _AiPromptScreenState();
}

class _AiPromptScreenState extends State<AiPromptScreen> {
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String get _aiPrompt {
    final theme = _themeController.text.trim().isEmpty 
        ? '[COLOQUE SEU TEMA AQUI]' 
        : _themeController.text.trim();
    
    final quantity = _quantityController.text.trim().isEmpty 
        ? '[COLOQUE A QUANTIDADE AQUI]' 
        : _quantityController.text.trim();

    return '''Você é um especialista na criação de Flashcards para estudo e memorização.
Preciso que você crie um baralho de estudos sobre o tema: $theme.

Você deve gerar o conteúdo no formato de texto CSV, seguindo ESTRITAMENTE estas regras:

1. Não inclua linha de cabeçalho (header).
2. Cada linha representará um flashcard.
3. A estrutura de cada linha deve conter exatamente duas colunas separadas por uma vírgula (,): a primeira coluna é a PERGUNTA e a segunda é a RESPOSTA.
4. Caso o texto da pergunta ou da resposta contenha uma vírgula (,), aspas duplas (") ou quebra de linha interna, você OBRIGATORIAMENTE deve envolver esse texto inteiro entre aspas duplas (""). 
5. Seja direto, forneça apenas o conteúdo CSV no bloco de código para que eu possa copiar, colar e salvar com a extensão .csv. Não adicione comentários adicionais.
6. A quantidade desejada de cartas é de: $quantity cartas.

Por favor, gere o CSV agora.''';
  }

  void _copyPrompt(BuildContext context) {
    if (_themeController.text.trim().isEmpty || _quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha o tema e a quantidade antes de copiar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: _aiPrompt)).then((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Comando Copiado!'),
            ],
          ),
          content: const Text(
            'O texto foi copiado com sucesso.\n\n'
            'Passo a Passo:\n'
            '1. Abra a Inteligência Artificial da sua escolha (ChatGPT, Gemini, Claude, etc).\n'
            '2. Cole o texto copiado lá.\n'
            '3. Copie a resposta gerada por ela.\n'
            '4. Volte aqui no app e escolha a opção "Colar texto CSV"!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi!'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _themeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar com Inteligência Artificial'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Como criar baralhos usando IA',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Preencha as informações abaixo para gerarmos o seu comando mágico. Depois basta copiar e colar no ChatGPT!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            
            // Formulário
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'Tema do Baralho (ex: Inglês Básico)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantidade de Cartas (máx: 50)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final intValue = int.tryParse(value) ?? 0;
                  if (intValue > 50) {
                    _quantityController.text = '50';
                    _quantityController.selection = TextSelection.fromPosition(
                      const TextPosition(offset: 2),
                    );
                  }
                }
                setState(() {});
              },
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade700 
                      : Colors.grey.shade400,
                ),
              ),
              child: SelectableText(
                _aiPrompt,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'COPIAR COMANDO PARA A IA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: () => _copyPrompt(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Já gerou o seu baralho com a IA?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.paste),
                    label: const Text('Colar Texto'),
                    onPressed: () => Navigator.pop(context, 'paste_csv'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('Importar Arquivo'),
                    onPressed: () => Navigator.pop(context, 'import_csv'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
