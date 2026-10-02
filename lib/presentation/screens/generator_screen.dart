import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/curriculum_data.dart';
import '../../providers/generator_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/topic_chip_input.dart';
import 'preview_editor_screen.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _customSubjectController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isCustomSubject = false;

  @override
  void dispose() {
    _customSubjectController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final generator = context.read<GeneratorProvider>();
    final settings = context.read<SettingsProvider>().settings;

    if (!settings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key AI belum diisi. Silakan isi di tab Pengaturan terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isCustomSubject && _customSubjectController.text.trim().isNotEmpty) {
      generator.setSubject(_customSubjectController.text.trim());
    }

    if (_titleController.text.trim().isNotEmpty) {
      generator.setExamTitle(_titleController.text.trim());
    }

    final success = await generator.generateExam(settings: settings);

    if (!mounted) return;

    if (success) {
      context.read<HistoryProvider>().loadPackages();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PreviewEditorScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(generator.errorMessage ?? 'Gagal membuat soal. Silakan periksa koneksi internet.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final generator = context.watch<GeneratorProvider>();
    final grades = CurriculumData.gradesByLevel[generator.educationLevel] ?? [];
    final subjects = CurriculumData.subjectsByLevel[generator.educationLevel] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Paket Soal AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              generator.clearTopics();
              _titleController.clear();
              _customSubjectController.clear();
            },
            tooltip: 'Reset Formulir',
          ),
        ],
      ),
      body: generator.isGenerating
          ? _buildLoadingState(generator)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryDark, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pilih kurikulum, mata pelajaran, materi, serta tingkat kesulitan yang diinginkan.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 1. Kurikulum & Jenjang
                _buildDropdownField(
                  label: 'Kurikulum Pendidikan',
                  value: generator.curriculum,
                  items: CurriculumData.curriculums,
                  onChanged: (val) {
                    if (val != null) generator.setCurriculum(val);
                  },
                ),
                const SizedBox(height: 14),

                _buildDropdownField(
                  label: 'Jenjang Pendidikan',
                  value: generator.educationLevel,
                  items: CurriculumData.educationLevels,
                  onChanged: (val) {
                    if (val != null) {
                      generator.setEducationLevel(val);
                      _isCustomSubject = false;
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Kelas & Semester
                _buildDropdownField(
                  label: 'Kelas / Fase',
                  value: grades.contains(generator.grade) ? generator.grade : (grades.isNotEmpty ? grades.first : ''),
                  items: grades,
                  onChanged: (val) {
                    if (val != null) generator.setGrade(val);
                  },
                ),
                const SizedBox(height: 14),

                // 3. Mata Pelajaran
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mata Pelajaran',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCustomSubject = !_isCustomSubject;
                            });
                          },
                          child: Text(
                            _isCustomSubject ? 'Pilih dari Daftar' : '+ Mapel Kustom',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_isCustomSubject)
                      CustomTextField(
                        label: '',
                        hint: 'Ketik nama mata pelajaran (contoh: Bahasa Sunda)...',
                        controller: _customSubjectController,
                        prefixIcon: const Icon(Icons.menu_book, color: AppColors.textMuted, size: 20),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: subjects.contains(generator.subject) ? generator.subject : (subjects.isNotEmpty ? subjects.first : null),
                        items: subjects.map((sub) {
                          return DropdownMenuItem(value: sub, child: Text(sub, style: const TextStyle(fontSize: 13.5)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) generator.setSubject(val);
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.menu_book, color: AppColors.textMuted, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Topic Chip Input (Multi topics)
                TopicChipInput(
                  topics: generator.topics,
                  currentSubject: generator.subject,
                  onAddTopic: (t) => generator.addTopic(t),
                  onRemoveTopic: (t) => generator.removeTopic(t),
                  onClearAll: () => generator.clearTopics(),
                ),
                const SizedBox(height: 18),

                // 5. Bentuk Soal
                _buildDropdownField(
                  label: 'Bentuk / Tipe Soal',
                  value: generator.questionType,
                  items: CurriculumData.questionTypes,
                  onChanged: (val) {
                    if (val != null) generator.setQuestionType(val);
                  },
                ),
                const SizedBox(height: 14),

                // 6. Tingkat Kesulitan
                _buildDropdownField(
                  label: 'Tingkat Kesulitan / Ranah Kognitif',
                  value: generator.difficulty,
                  items: CurriculumData.difficultyLevels,
                  onChanged: (val) {
                    if (val != null) generator.setDifficulty(val);
                  },
                ),
                const SizedBox(height: 16),

                // 7. Jumlah Soal (Chips)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jumlah Butir Soal',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${generator.totalQuestions} Soal',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: CurriculumData.questionCountOptions.map((count) {
                        final isSelected = generator.totalQuestions == count;
                        return ChoiceChip(
                          label: Text('$count Soal'),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                          onSelected: (selected) {
                            if (selected) generator.setTotalQuestions(count);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8. Opsi Dokumen & Judul
                CustomTextField(
                  label: 'Judul Penilaian / Ujian (Opsional)',
                  hint: 'Contoh: Ulangan Harian Bab 1 / Penilaian Sumatif',
                  controller: _titleController,
                  prefixIcon: const Icon(Icons.edit_note, color: AppColors.textMuted, size: 20),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Waktu Ujian',
                        value: '${generator.durationMinutes} Menit',
                        items: const ['45 Menit', '60 Menit', '90 Menit', '120 Menit'],
                        onChanged: (val) {
                          if (val != null) {
                            final mins = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 90;
                            generator.setDurationMinutes(mins);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                CustomButton(
                  text: 'Generate Soal dengan AI',
                  icon: Icons.auto_awesome,
                  onPressed: _handleGenerate,
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: validValue,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(GeneratorProvider generator) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Sedang Menyusun Soal...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Menganalisis capaian kurikulum "${generator.curriculum}"\nuntuk materi: ${generator.topics.join(", ")}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Menyusun ${generator.totalQuestions} Butir Soal & Kunci Jawaban',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
