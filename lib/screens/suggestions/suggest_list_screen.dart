import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suggest_service.dart';
import '_suggest_form_helpers.dart';

class SuggestListScreen extends StatefulWidget {
  const SuggestListScreen({super.key});

  @override
  State<SuggestListScreen> createState() => _SuggestListScreenState();
}

class _SuggestListScreenState extends State<SuggestListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final List<TextEditingController> _answerCtrls =
      List.generate(5, (_) => TextEditingController());

  ThemeCatalog? _catalog;
  int? _decadeId;
  int? _mediaId;
  final Set<int> _genreIds = {};
  bool _loading = true;
  bool _saving = false;
  late SuggestService _service;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _service = SuggestService(ApiClient(storage));
    final catalog = await _service.getThemes();
    setState(() {
      _catalog = catalog;
      _loading = false;
    });
  }

  void _addAnswer() {
    setState(() => _answerCtrls.add(TextEditingController()));
  }

  void _removeAnswer(int index) {
    if (_answerCtrls.length <= 5) return;
    setState(() {
      _answerCtrls[index].dispose();
      _answerCtrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final answers =
        _answerCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (answers.length < 5) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mínimo de 5 respostas')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.suggestList(
        statement: _statementCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        decadeId: _decadeId,
        mediaId: _mediaId,
        genreIds: _genreIds.toList(),
        answers: answers,
      );
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sugestão enviada!'),
        content: const Text('Obrigado! Sua pergunta será avaliada pela equipe.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statementCtrl.dispose();
    _imageCtrl.dispose();
    for (final c in _answerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatementField(controller: _statementCtrl),
                    const SizedBox(height: 12),
                    ImageUrlField(controller: _imageCtrl),
                    const SizedBox(height: 16),
                    ThemeSelector(
                      catalog: _catalog!,
                      decadeId: _decadeId,
                      mediaId: _mediaId,
                      genreIds: _genreIds,
                      onDecadeChanged: (v) => setState(() => _decadeId = v),
                      onMediaChanged: (v) => setState(() => _mediaId = v),
                      onGenreToggled: (id) => setState(() {
                        if (_genreIds.contains(id)) {
                          _genreIds.remove(id);
                        } else {
                          _genreIds.add(id);
                        }
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Respostas válidas (mínimo 5)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Liste os itens que o jogador deve identificar.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < _answerCtrls.length; i++) ...[
                      Row(
                        children: [
                          const Icon(Icons.label_outline, color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _answerCtrls[i],
                              decoration: InputDecoration(labelText: 'Resposta ${i + 1}'),
                              validator: i < 5
                                  ? (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null
                                  : null,
                            ),
                          ),
                          if (_answerCtrls.length > 5)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeAnswer(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextButton.icon(
                      onPressed: _addAnswer,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar resposta'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Enviar sugestão'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
