import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suggest_service.dart';
import '_suggest_form_helpers.dart';

class SuggestTfScreen extends StatefulWidget {
  const SuggestTfScreen({super.key});

  @override
  State<SuggestTfScreen> createState() => _SuggestTfScreenState();
}

class _SuggestTfScreenState extends State<SuggestTfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _correctAnswer = true;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.suggestTrueFalse(
        statement: _statementCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        decadeId: _decadeId,
        mediaId: _mediaId,
        genreIds: _genreIds.toList(),
        correctAnswer: _correctAnswer,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verdadeiro ou Falso')),
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
                    const Text('A afirmação é:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _AnswerButton(
                            label: 'VERDADEIRO',
                            selected: _correctAnswer,
                            color: Colors.green,
                            onTap: () => setState(() => _correctAnswer = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnswerButton(
                            label: 'FALSO',
                            selected: !_correctAnswer,
                            color: Colors.red,
                            onTap: () => setState(() => _correctAnswer = false),
                          ),
                        ),
                      ],
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

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.textSecondary.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
