import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:guru_soal_ai/data/models/question_model.dart';
import 'package:guru_soal_ai/data/models/question_package_model.dart';
import 'package:guru_soal_ai/data/models/app_settings_model.dart';
import 'package:guru_soal_ai/data/services/docx_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('GuruSoal AI Unit Tests', () {
    test('QuestionModel JSON parsing test', () {
      final json = {
        'number': 1,
        'questionText': 'Berapakah hasil dari 2 + 2?',
        'questionType': 'PG',
        'options': [
          {'key': 'A', 'text': '2'},
          {'key': 'B', 'text': '3'},
          {'key': 'C', 'text': '4'},
          {'key': 'D', 'text': '5'},
        ],
        'correctAnswer': 'C',
        'explanation': '2 + 2 = 4',
        'difficulty': 'Mudah',
        'topic': 'Aritmatika',
      };

      final q = QuestionModel.fromJson(json);
      expect(q.number, 1);
      expect(q.questionText, 'Berapakah hasil dari 2 + 2?');
      expect(q.options.length, 4);
      expect(q.options[2].key, 'C');
      expect(q.options[2].text, '4');
      expect(q.correctAnswer, 'C');
      expect(q.isMultipleChoice, true);
    });

    test('QuestionPackageModel SQLite toMap and fromMap test', () {
      final package = QuestionPackageModel(
        title: 'Ulangan Harian Matematika',
        subject: 'Matematika',
        educationLevel: 'SMP',
        grade: 'Kelas 8',
        curriculum: 'Kurikulum Merdeka',
        topics: ['Aljabar', 'SPLDV'],
        questionType: 'Pilihan Ganda',
        difficulty: 'Sedang',
        totalQuestions: 1,
        questions: [
          const QuestionModel(
            number: 1,
            questionText: 'Nilai x dari 2x = 10 adalah...',
            questionType: 'PG',
            options: [
              QuestionOption(key: 'A', text: '5'),
              QuestionOption(key: 'B', text: '10'),
            ],
            correctAnswer: 'A',
            explanation: 'x = 10 / 2 = 5',
          ),
        ],
      );

      final map = package.toMap();
      final reconstructed = QuestionPackageModel.fromMap(map);

      expect(reconstructed.id, package.id);
      expect(reconstructed.title, 'Ulangan Harian Matematika');
      expect(reconstructed.topics.length, 2);
      expect(reconstructed.topics.first, 'Aljabar');
      expect(reconstructed.questions.length, 1);
      expect(reconstructed.questions.first.questionText, 'Nilai x dari 2x = 10 adalah...');
    });

    test('AppSettingsModel config status test', () {
      const emptySettings = AppSettingsModel(apiKey: '');
      expect(emptySettings.isConfigured, false);

      const filledSettings = AppSettingsModel(apiKey: 'xai-test-key-12345');
      expect(filledSettings.isConfigured, true);
    });

    test('DocxService generates valid zip/docx bytes', () {
      final docxService = DocxService();
      final package = QuestionPackageModel(
        title: 'Ulangan Harian Biologi',
        subject: 'Biologi',
        educationLevel: 'SMA',
        grade: 'Kelas 10',
        curriculum: 'Kurikulum Merdeka',
        topics: ['Sel & Organel'],
        questionType: 'PG',
        difficulty: 'Mudah',
        totalQuestions: 1,
        questions: [
          const QuestionModel(
            number: 1,
            questionText: 'Organel penghasil energi pada sel adalah...',
            questionType: 'PG',
            options: [
              QuestionOption(key: 'A', text: 'Mitokondria'),
              QuestionOption(key: 'B', text: 'Ribosom'),
            ],
            correctAnswer: 'A',
            explanation: 'Mitokondria adalah the powerhouse of the cell.',
          ),
        ],
      );

      final bytes = docxService.generateDocxBytes(
        package: package,
        settings: const AppSettingsModel(),
      );

      expect(bytes.isNotEmpty, true);
      // Valid ZIP / docx header bytes: 0x50 0x4B (PK)
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });
  });
}
