import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../../data/services/docx_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/generator_provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/question_card_item.dart';
import 'pdf_viewer_screen.dart';

class PreviewEditorScreen extends StatelessWidget {
  const PreviewEditorScreen({super.key});

  void _showEditQuestionSheet(BuildContext context, int index, QuestionModel question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditQuestionBottomSheet(
        index: index,
        question: question,
        onSave: (updated) {
          context.read<GeneratorProvider>().updateQuestion(index, updated);
          context.read<GeneratorProvider>().saveCurrentPackage();
          context.read<HistoryProvider>().loadPackages();
        },
      ),
    );
  }

  void _showAddQuestionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditQuestionBottomSheet(
        index: -1,
        question: const QuestionModel(
          number: 0,
          questionText: '',
          questionType: 'PG',
          options: [
            QuestionOption(key: 'A', text: ''),
            QuestionOption(key: 'B', text: ''),
            QuestionOption(key: 'C', text: ''),
            QuestionOption(key: 'D', text: ''),
          ],
          correctAnswer: 'A',
          explanation: '',
          difficulty: 'Sedang',
        ),
        onSave: (newQuestion) {
          context.read<GeneratorProvider>().addQuestion(newQuestion);
          context.read<GeneratorProvider>().saveCurrentPackage();
          context.read<HistoryProvider>().loadPackages();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generator = context.watch<GeneratorProvider>();
    final package = generator.currentPackage;

    if (package == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Soal')),
        body: const Center(child: Text('Paket soal tidak ditemukan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${package.subject} • ${package.grade}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Color(0xFF2563EB)),
            onPressed: () async {
              final settings = context.read<SettingsProvider>().settings;
              final docxService = DocxService();
              await docxService.exportAndShareDocx(package: package, settings: settings);
            },
            tooltip: 'Export ke MS Word (.docx)',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(package: package),
                ),
              );
            },
            tooltip: 'Export / Cetak PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${package.questions.length} Butir Soal Siap Digunakan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        package.curriculum,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Topik: ${package.topics.join(", ")}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Question Items
          ...package.questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            return QuestionCardItem(
              question: q,
              onEdit: () => _showEditQuestionSheet(context, idx, q),
              onDelete: () {
                generator.deleteQuestion(idx);
                generator.saveCurrentPackage();
                context.read<HistoryProvider>().loadPackages();
              },
            );
          }),

          const SizedBox(height: 8),

          // Add Question Button
          OutlinedButton.icon(
            onPressed: () => _showAddQuestionSheet(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Soal Manual'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final settings = context.read<SettingsProvider>().settings;
                  final docxService = DocxService();
                  await docxService.exportAndShareDocx(package: package, settings: settings);
                },
                icon: const Icon(Icons.description, size: 18, color: Color(0xFF2563EB)),
                label: const Text(
                  'Ekspor MS Word',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(package: package),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                label: const Text(
                  'Cetak PDF',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditQuestionBottomSheet extends StatefulWidget {
  final int index;
  final QuestionModel question;
  final ValueChanged<QuestionModel> onSave;

  const _EditQuestionBottomSheet({
    required this.index,
    required this.question,
    required this.onSave,
  });

  @override
  State<_EditQuestionBottomSheet> createState() => _EditQuestionBottomSheetState();
}

class _EditQuestionBottomSheetState extends State<_EditQuestionBottomSheet> {
  late TextEditingController _questionTextController;
  late TextEditingController _explanationController;
  late TextEditingController _correctAnswerController;
  late List<TextEditingController> _optionControllers;
  late List<String> _optionKeys;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController(text: widget.question.questionText);
    _explanationController = TextEditingController(text: widget.question.explanation);
    _correctAnswerController = TextEditingController(text: widget.question.correctAnswer);
    _difficulty = widget.question.difficulty;

    if (widget.question.options.isNotEmpty) {
      _optionKeys = widget.question.options.map((o) => o.key).toList();
      _optionControllers = widget.question.options.map((o) => TextEditingController(text: o.text)).toList();
    } else {
      _optionKeys = ['A', 'B', 'C', 'D'];
      _optionControllers = _optionKeys.map((_) => TextEditingController()).toList();
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _explanationController.dispose();
    _correctAnswerController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSave() {
    if (_questionTextController.text.trim().isEmpty) return;

    List<QuestionOption> options = [];
    if (widget.question.isMultipleChoice) {
      for (int i = 0; i < _optionControllers.length; i++) {
        options.add(QuestionOption(
          key: _optionKeys[i],
          text: _optionControllers[i].text.trim(),
        ));
      }
    }

    final updated = widget.question.copyWith(
      questionText: _questionTextController.text.trim(),
      options: options,
      correctAnswer: _correctAnswerController.text.trim(),
      explanation: _explanationController.text.trim(),
      difficulty: _difficulty,
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPG = widget.question.isMultipleChoice;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.index >= 0 ? 'Edit Butir Soal #${widget.question.number}' : 'Tambah Soal Baru',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                CustomTextField(
                  label: 'Teks Soal',
                  controller: _questionTextController,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),

                if (isPG) ...[
                  const Text(
                    'Pilihan Jawaban',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  ..._optionControllers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final key = _optionKeys[idx];
                    final controller = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              key,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'Pilihan $key...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Kunci Jawaban Dropdown
                  Row(
                    children: [
                      const Text(
                        'Kunci Jawaban Benar: ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _optionKeys.contains(_correctAnswerController.text.toUpperCase())
                            ? _correctAnswerController.text.toUpperCase()
                            : _optionKeys.first,
                        items: _optionKeys.map((k) {
                          return DropdownMenuItem(value: k, child: Text('Opsi $k'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _correctAnswerController.text = val);
                          }
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Kunci / Pedoman Jawaban',
                    controller: _correctAnswerController,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Pembahasan & Penjelasan',
                  controller: _explanationController,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                CustomButton(
                  text: 'Simpan Soal',
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
