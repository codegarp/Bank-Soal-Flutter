import 'package:flutter/material.dart';
import '../data/models/app_settings_model.dart';
import '../data/models/question_model.dart';
import '../data/models/question_package_model.dart';
import '../data/datasources/local_db.dart';
import '../data/services/ai_service.dart';
import '../core/constants/curriculum_data.dart';

class GeneratorProvider extends ChangeNotifier {
  final AiService _aiService;
  final LocalDatabase _localDb;

  // Form State
  String _curriculum = CurriculumData.curriculums.first;
  String _educationLevel = CurriculumData.educationLevels[1]; // SMP default
  String _grade = 'Kelas 8 (Fase D)';
  String _subject = 'Matematika';
  List<String> _topics = [];
  String _questionType = CurriculumData.questionTypes.first; // PG
  String _difficulty = CurriculumData.difficultyLevels[1]; // Sedang
  int _totalQuestions = 10;
  int _durationMinutes = 60;
  String _examTitle = '';

  // Execution State
  bool _isGenerating = false;
  String? _errorMessage;
  QuestionPackageModel? _currentPackage;

  GeneratorProvider({
    AiService? aiService,
    LocalDatabase? localDb,
  })  : _aiService = aiService ?? AiService(),
        _localDb = localDb ?? LocalDatabase.instance;

  // Getters
  String get curriculum => _curriculum;
  String get educationLevel => _educationLevel;
  String get grade => _grade;
  String get subject => _subject;
  List<String> get topics => _topics;
  String get questionType => _questionType;
  String get difficulty => _difficulty;
  int get totalQuestions => _totalQuestions;
  int get durationMinutes => _durationMinutes;
  String get examTitle => _examTitle;

  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  QuestionPackageModel? get currentPackage => _currentPackage;

  // Setters
  void setCurriculum(String val) {
    _curriculum = val;
    notifyListeners();
  }

  void setEducationLevel(String val) {
    _educationLevel = val;
    final grades = CurriculumData.gradesByLevel[val] ?? [];
    if (grades.isNotEmpty) {
      _grade = grades.first;
    }
    final subjects = CurriculumData.subjectsByLevel[val] ?? [];
    if (subjects.isNotEmpty && !subjects.contains(_subject)) {
      _subject = subjects.first;
    }
    notifyListeners();
  }

  void setGrade(String val) {
    _grade = val;
    notifyListeners();
  }

  void setSubject(String val) {
    _subject = val;
    notifyListeners();
  }

  void addTopic(String topic) {
    final trimmed = topic.trim();
    if (trimmed.isNotEmpty && !_topics.contains(trimmed)) {
      _topics.add(trimmed);
      notifyListeners();
    }
  }

  void removeTopic(String topic) {
    _topics.remove(topic);
    notifyListeners();
  }

  void clearTopics() {
    _topics.clear();
    notifyListeners();
  }

  void setQuestionType(String val) {
    _questionType = val;
    notifyListeners();
  }

  void setDifficulty(String val) {
    _difficulty = val;
    notifyListeners();
  }

  void setTotalQuestions(int val) {
    _totalQuestions = val;
    notifyListeners();
  }

  void setDurationMinutes(int val) {
    _durationMinutes = val;
    notifyListeners();
  }

  void setExamTitle(String val) {
    _examTitle = val;
    notifyListeners();
  }

  void setCurrentPackage(QuestionPackageModel package) {
    _currentPackage = package;
    _curriculum = package.curriculum;
    _educationLevel = package.educationLevel;
    _grade = package.grade;
    _subject = package.subject;
    _topics = List.from(package.topics);
    _questionType = package.questionType;
    _difficulty = package.difficulty;
    _totalQuestions = package.totalQuestions;
    _durationMinutes = package.durationMinutes;
    _examTitle = package.title;
    notifyListeners();
  }

  /// Generate Soal via Grok API
  Future<bool> generateExam({required AppSettingsModel settings}) async {
    if (_topics.isEmpty) {
      _errorMessage = 'Harap tambahkan minimal 1 materi atau topik pembelajaran.';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final generatedQuestions = await _aiService.generateQuestions(
        settings: settings,
        subject: _subject,
        educationLevel: _educationLevel,
        grade: _grade,
        curriculum: _curriculum,
        topics: _topics,
        questionType: _questionType,
        difficulty: _difficulty,
        totalQuestions: _totalQuestions,
      );

      final title = _examTitle.isNotEmpty
          ? _examTitle
          : 'Penilaian Harian $_subject $_grade';

      final package = QuestionPackageModel(
        title: title,
        subject: _subject,
        educationLevel: _educationLevel,
        grade: _grade,
        curriculum: _curriculum,
        topics: List.from(_topics),
        questionType: _questionType,
        difficulty: _difficulty,
        totalQuestions: generatedQuestions.length,
        durationMinutes: _durationMinutes,
        academicYear: settings.academicYear,
        semester: settings.semester,
        schoolName: settings.schoolName,
        teacherName: settings.teacherName,
        questions: generatedQuestions,
      );

      _currentPackage = package;
      // Auto save to local DB (graceful fallback if web storage has permission issue)
      try {
        await _localDb.insertPackage(package);
      } catch (dbErr) {
        debugPrint('Auto-save to DB warning: $dbErr');
      }

      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isGenerating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update single question item
  void updateQuestion(int index, QuestionModel updatedQuestion) {
    if (_currentPackage == null || index < 0 || index >= _currentPackage!.questions.length) return;

    final updatedList = List<QuestionModel>.from(_currentPackage!.questions);
    updatedList[index] = updatedQuestion;

    _currentPackage = _currentPackage!.copyWith(
      questions: updatedList,
      totalQuestions: updatedList.length,
    );
    notifyListeners();
  }

  /// Delete question item
  void deleteQuestion(int index) {
    if (_currentPackage == null || index < 0 || index >= _currentPackage!.questions.length) return;

    final updatedList = List<QuestionModel>.from(_currentPackage!.questions);
    updatedList.removeAt(index);

    // Renumber remaining questions
    final renumberedList = updatedList.asMap().entries.map((e) {
      return e.value.copyWith(number: e.key + 1);
    }).toList();

    _currentPackage = _currentPackage!.copyWith(
      questions: renumberedList,
      totalQuestions: renumberedList.length,
    );
    notifyListeners();
  }

  /// Add new manual question
  void addQuestion(QuestionModel newQuestion) {
    if (_currentPackage == null) return;

    final updatedList = List<QuestionModel>.from(_currentPackage!.questions);
    updatedList.add(newQuestion.copyWith(number: updatedList.length + 1));

    _currentPackage = _currentPackage!.copyWith(
      questions: updatedList,
      totalQuestions: updatedList.length,
    );
    notifyListeners();
  }

  /// Persist current package changes to DB
  Future<void> saveCurrentPackage() async {
    if (_currentPackage != null) {
      await _localDb.updatePackage(_currentPackage!);
    }
  }
}
