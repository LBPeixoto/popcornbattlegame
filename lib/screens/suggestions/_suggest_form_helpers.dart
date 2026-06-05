import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/theme_model.dart';
import '../../services/suggest_service.dart';

class StatementField extends StatelessWidget {
  final TextEditingController controller;
  const StatementField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Enunciado da pergunta *',
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
    );
  }
}

class ImageUrlField extends StatelessWidget {
  final TextEditingController controller;
  const ImageUrlField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'URL de imagem (opcional)',
        prefixIcon: Icon(Icons.image_outlined),
      ),
      keyboardType: TextInputType.url,
    );
  }
}

class ThemeSelector extends StatelessWidget {
  final ThemeCatalog catalog;
  final int? decadeId;
  final int? mediaId;
  final Set<int> genreIds;
  final ValueChanged<int?> onDecadeChanged;
  final ValueChanged<int?> onMediaChanged;
  final ValueChanged<int> onGenreToggled;

  const ThemeSelector({
    super.key,
    required this.catalog,
    required this.decadeId,
    required this.mediaId,
    required this.genreIds,
    required this.onDecadeChanged,
    required this.onMediaChanged,
    required this.onGenreToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemedDropdown<int>(
          label: 'Década (opcional)',
          value: decadeId,
          items: catalog.decades,
          onChanged: onDecadeChanged,
        ),
        const SizedBox(height: 12),
        _ThemedDropdown<int>(
          label: 'Mídia (opcional)',
          value: mediaId,
          items: catalog.medias,
          onChanged: onMediaChanged,
        ),
        const SizedBox(height: 12),
        const Text('Gêneros (opcional)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: catalog.genres.map((g) {
            final selected = genreIds.contains(g.id);
            return FilterChip(
              label: Text(g.name),
              selected: selected,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (_) => onGenreToggled(g.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ThemedDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<ThemeModel> items;
  final ValueChanged<T?> onChanged;

  const _ThemedDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            DropdownMenuItem<T>(value: null, child: const Text('— Nenhuma —')),
            for (final t in items)
              DropdownMenuItem<T>(value: t.id as T, child: Text(t.name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
