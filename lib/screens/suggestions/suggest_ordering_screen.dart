import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suggest_service.dart';
import '_suggest_form_helpers.dart';

class SuggestOrderingScreen extends StatefulWidget {
  const SuggestOrderingScreen({super.key});

  @override
  State<SuggestOrderingScreen> createState() => _SuggestOrderingScreenState();
}

class _SuggestOrderingScreenState extends State<SuggestOrderingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final List<TextEditingController> _itemCtrls =
      List.generate(4, (_) => TextEditingController());

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

  void _addItem() {
    setState(() => _itemCtrls.add(TextEditingController()));
  }

  void _removeItem(int index) {
    if (_itemCtrls.length <= 4) return;
    setState(() {
      _itemCtrls[index].dispose();
      _itemCtrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final items = _itemCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (items.length < 4) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mínimo de 4 itens')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.suggestOrdering(
        statement: _statementCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        decadeId: _decadeId,
        mediaId: _mediaId,
        genreIds: _genreIds.toList(),
        items: items,
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
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordenação')),
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
                      'Itens em ordem correta (mínimo 4)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Insira os itens já na ordem certa que o jogador deverá reproduzir.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < _itemCtrls.length; i++) ...[
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _itemCtrls[i],
                              decoration: InputDecoration(labelText: 'Item ${i + 1}'),
                              validator: i < 4
                                  ? (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null
                                  : null,
                            ),
                          ),
                          if (_itemCtrls.length > 4)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeItem(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar item'),
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
