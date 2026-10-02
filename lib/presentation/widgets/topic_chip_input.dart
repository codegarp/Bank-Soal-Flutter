import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/curriculum_data.dart';

class TopicChipInput extends StatefulWidget {
  final List<String> topics;
  final String currentSubject;
  final ValueChanged<String> onAddTopic;
  final ValueChanged<String> onRemoveTopic;
  final VoidCallback onClearAll;

  const TopicChipInput({
    super.key,
    required this.topics,
    required this.currentSubject,
    required this.onAddTopic,
    required this.onRemoveTopic,
    required this.onClearAll,
  });

  @override
  State<TopicChipInput> createState() => _TopicChipInputState();
}

class _TopicChipInputState extends State<TopicChipInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleAdd() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAddTopic(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = CurriculumData.suggestedTopics[widget.currentSubject] ?? [];
    final availableSuggestions = suggestions
        .where((s) => !widget.topics.contains(s))
        .take(6)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Materi / Topik Pembelajaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.topics.isNotEmpty)
              GestureDetector(
                onTap: widget.onClearAll,
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _handleAdd(),
                decoration: InputDecoration(
                  hintText: 'Ketik materi (contoh: Teorema Pythagoras)...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.bookmark_outline, size: 20, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _handleAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Selected Topics Chips
        if (widget.topics.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.topics.map((topic) {
              return Chip(
                backgroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primaryLight, width: 0.8),
                label: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryDark),
                onDeleted: () => widget.onRemoveTopic(topic),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Suggestions from database
        if (availableSuggestions.isNotEmpty) ...[
          const Text(
            'Saran Topik Cepat:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: availableSuggestions.map((suggestion) {
              return ActionChip(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                label: Text(
                  '+ $suggestion',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                onPressed: () => widget.onAddTopic(suggestion),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
