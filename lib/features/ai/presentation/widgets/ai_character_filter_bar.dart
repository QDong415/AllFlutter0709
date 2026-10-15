import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/ai/data/ai_character_repository.dart';
import 'package:flutter/material.dart';

/// AI 角色页搜索框与顶部筛选栏。
class AiCharacterFilterBar extends StatelessWidget {
  const AiCharacterFilterBar({
    super.key,
    required this.selectedFilter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onCreateTap,
  });

  final AiCharacterFilter selectedFilter;
  final TextEditingController searchController;
  final ValueChanged<AiCharacterFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.toolbar,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索 AI 伙伴',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空',
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  for (final filter in AiCharacterFilter.values) ...[
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: filter == selectedFilter,
                      onSelected: (_) => onFilterChanged(filter),
                      showCheckmark: false,
                      side: BorderSide.none,
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.primary.withValues(alpha: 0.14),
                      labelStyle: TextStyle(
                        color: filter == selectedFilter
                            ? AppColors.primary
                            : AppColors.titleText,
                        fontWeight: filter == selectedFilter
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onCreateTap,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: const Text('新角色'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
