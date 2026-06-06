import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suggest_service.dart';
import '_suggest_form_helpers.dart';

class SuggestHintsScreen extends StatefulWidget {
  const SuggestHintsScreen({super.key});

  @override
  State<SuggestHintsScreen> createState() => _SuggestHintsScreenState();
}

class _SuggestHintsScreenState extends State<SuggestHintsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final List<TextEditingController> _hintCtrls =
      List.generate(10, (_) => TextEditingController());

  String _orientation = 'TITLE';

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

  @override
  void dispose() {
    _statementCtrl.dispose();
    _imageCtrl.dispose();
    _answerCtrl.dispose();
    for (final c in _hintCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.suggestHints(
        statement: _statementCtrl.text.trim(),
        imageUrl:
            _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        decadeId: _decadeId,
        mediaId: _mediaId,
        genreIds: _genreIds.toList(),
        orientation: _orientation,
        answer: _answerCtrl.text.trim(),
        hints: _hintCtrls.map((c) => c.text.trim()).toList(),
      );
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sugerir — Dicas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Instrução
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'Crie uma questão com 10 dicas que revelam progressivamente a resposta. '
                        'A dica 1 deve ser a mais difícil e a dica 10 a mais fácil.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enunciado (contexto da pergunta)
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
                    const SizedBox(height: 20),

                    // Orientação
                    const Text('O que deve ser adivinhado? *',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _OrientationChip(
                          label: 'Título',
                          value: 'TITLE',
                          selected: _orientation == 'TITLE',
                          onTap: () => setState(() => _orientation = 'TITLE'),
                        ),
                        const SizedBox(width: 8),
                        _OrientationChip(
                          label: 'Personagem',
                          value: 'CHARACTER',
                          selected: _orientation == 'CHARACTER',
                          onTap: () =>
                              setState(() => _orientation = 'CHARACTER'),
                        ),
                        const SizedBox(width: 8),
                        _OrientationChip(
                          label: 'Ator/Atriz',
                          value: 'ACTOR',
                          selected: _orientation == 'ACTOR',
                          onTap: () => setState(() => _orientation = 'ACTOR'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Resposta correta
                    TextFormField(
                      controller: _answerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Resposta correta *',
                        hintText: 'Ex: De Volta para o Futuro',
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 24),

                    // Dicas
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppColors.secondary, size: 18),
                        const SizedBox(width: 6),
                        const Text('Dicas (da mais difícil para a mais fácil)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dica 1 = mais difícil  •  Dica 10 = mais fácil (quase entrega a resposta)',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    ...List.generate(10, (i) => _HintField(
                          index: i,
                          controller: _hintCtrls[i],
                        )),

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52)),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Enviar sugestão',
                              style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _OrientationChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _OrientationChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HintField extends StatelessWidget {
  final int index;
  final TextEditingController controller;

  const _HintField({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isEasy = index >= 7;
    final badgeColor = isEasy ? AppColors.correct : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Dica ${index + 1}',
                hintText: index == 0
                    ? 'Dica mais difícil...'
                    : index == 9
                        ? 'Dica mais fácil (quase entrega)...'
                        : null,
              ),
              maxLines: 2,
              minLines: 1,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
          ),
        ],
      ),
    );
  }
}
