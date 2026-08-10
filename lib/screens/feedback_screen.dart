import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../presentation/viewmodels/feedback_viewmodel.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late FeedbackViewModel _viewModel;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.instance<FeedbackViewModel>();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    final success = await _viewModel.submitFeedback(text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua sugestão foi enviada com sucesso. Muito obrigado!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro ao enviar. Tente novamente mais tarde.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deixar uma Sugestão'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tem alguma ideia, encontrou um problema ou gostaria de ver algo novo no Memory Flash?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _feedbackController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Escreva sua sugestão aqui...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, child) {
                  return ElevatedButton(
                    onPressed: _viewModel.isSending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _viewModel.isSending
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Enviar',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
