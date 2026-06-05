import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suggest_service.dart';
import '_suggest_form_helpers.dart';

class SuggestMcScreen extends StatefulWidget {
  const SuggestMcScreen({super.key});

  @override
  State<SuggestMcScreen> createState() => _SuggestMcScreenState();
}

class _SuggestMcScreenState extends State<SuggestMcScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _altCtrls = List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

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
    final alts = _altCtrls.map((c) => c.text.trim()).toList();
    if (alts.any((t) => t.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Preencha todas as alternativas')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.suggestMultipleChoice(
        statement: _statementCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        decadeId: _decadeId,
        mediaId: _mediaId,
        genreIds: _genreIds.toList(),
        alternatives: [
          for (int i = 0; i < 4; i++)
            AlternativeInput()
              ..text = alts[i]
              ..correct = i == _correctIndex,
        ],
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
    for (final c in _altCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Múltipla Escolha')),
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
                    const Text('Alternativas', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecione a alternativa correta',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < 4; i++) ...[
                      InkWell(
                        onTap: () => setState(() => _correctIndex = i),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _correctIndex == i
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _correctIndex == i
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _altCtrls[i],
                                  decoration: InputDecoration(
                                    labelText: 'Alternativa ${String.fromCharCode(65 + i)}',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
