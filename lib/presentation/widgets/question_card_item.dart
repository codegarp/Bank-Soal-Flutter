import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';

class QuestionCardItem extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuestionCardItem({
    super.key,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<QuestionCardItem> createState() => _QuestionCardItemState();
}

class _QuestionCardItemState extends State<QuestionCardItem> {
  bool _isExplanationExpanded = false;

  Color _getDifficultyColor(String difficulty) {
    final lower = difficulty.toLowerCase();
    if (lower.contains('mudah') || lower.contains('lots')) {
      return AppColors.easyBadge;
    } else if (lower.contains('sulit') || lower.contains('hots')) {
      return AppColors.hardBadge;
    }
    return AppColors.mediumBadge;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final difficultyColor = _getDifficultyColor(q.difficulty);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Number + Difficulty Badge + Edit/Delete Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${q.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: difficultyColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    q.difficulty,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: difficultyColor,
                    ),
                  ),
                ),
                if (q.topic.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '• ${q.topic}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  onPressed: widget.onEdit,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit Soal',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  onPressed: widget.onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus Soal',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text
            Text(
              q.questionText,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Options List (if PG)
            if (q.options.isNotEmpty) ...[
              Column(
                children: q.options.map((opt) {
                  final isCorrect = opt.key.toUpperCase() == q.correctAnswer.toUpperCase();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCorrect ? AppColors.successLight.withValues(alpha: 0.4) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect ? AppColors.success : AppColors.border,
                        width: isCorrect ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${opt.key}.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.w600,
                            color: isCorrect ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                              color: isCorrect ? const Color(0xFF065F46) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Correct Answer Tag (for Essay/Isian or general)
            if (q.options.isEmpty && q.correctAnswer.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kunci Jawaban: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        q.correctAnswer,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Explanation / Pembahasan Accordion
            if (q.explanation.isNotEmpty) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    _isExplanationExpanded = !_isExplanationExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Pembahasan & Kunci',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExplanationExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExplanationExpanded) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    q.explanation,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
