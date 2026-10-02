import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'question_model.dart';

class QuestionPackageModel {
  final String id;
  final String title;
  final String subject;
  final String educationLevel;
  final String grade;
  final String curriculum;
  final List<String> topics;
  final String questionType;
  final String difficulty;
  final int totalQuestions;
  final int durationMinutes;
  final String academicYear;
  final String semester;
  final String schoolName;
  final String teacherName;
  final DateTime createdAt;
  final List<QuestionModel> questions;

  QuestionPackageModel({
    String? id,
    required this.title,
    required this.subject,
    required this.educationLevel,
    required this.grade,
    required this.curriculum,
    required this.topics,
    required this.questionType,
    required this.difficulty,
    required this.totalQuestions,
    this.durationMinutes = 90,
    this.academicYear = '2024/2025',
    this.semester = 'Ganjil',
    this.schoolName = '',
    this.teacherName = '',
    DateTime? createdAt,
    required this.questions,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  QuestionPackageModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? educationLevel,
    String? grade,
    String? curriculum,
    List<String>? topics,
    String? questionType,
    String? difficulty,
    int? totalQuestions,
    int? durationMinutes,
    String? academicYear,
    String? semester,
    String? schoolName,
    String? teacherName,
    DateTime? createdAt,
    List<QuestionModel>? questions,
  }) {
    return QuestionPackageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      educationLevel: educationLevel ?? this.educationLevel,
      grade: grade ?? this.grade,
      curriculum: curriculum ?? this.curriculum,
      topics: topics ?? this.topics,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      schoolName: schoolName ?? this.schoolName,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'educationLevel': educationLevel,
      'grade': grade,
      'curriculum': curriculum,
      'topics': jsonEncode(topics),
      'questionType': questionType,
      'difficulty': difficulty,
      'totalQuestions': totalQuestions,
      'durationMinutes': durationMinutes,
      'academicYear': academicYear,
      'semester': semester,
      'schoolName': schoolName,
      'teacherName': teacherName,
      'createdAt': createdAt.toIso8601String(),
      'questions': jsonEncode(questions.map((q) => q.toJson()).toList()),
    };
  }

  factory QuestionPackageModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTopics = [];
    if (map['topics'] != null) {
      try {
        final decoded = jsonDecode(map['topics']);
        if (decoded is List) {
          parsedTopics = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedTopics = [map['topics'].toString()];
      }
    }

    List<QuestionModel> parsedQuestions = [];
    if (map['questions'] != null) {
      try {
        dynamic decoded = map['questions'];
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }
        if (decoded is List) {
          parsedQuestions = decoded
              .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        // Fallback
      }
    }

    return QuestionPackageModel(
      id: map['id']?.toString(),
      title: map['title']?.toString() ?? 'Paket Soal',
      subject: map['subject']?.toString() ?? '',
      educationLevel: map['educationLevel']?.toString() ?? '',
      grade: map['grade']?.toString() ?? '',
      curriculum: map['curriculum']?.toString() ?? '',
      topics: parsedTopics,
      questionType: map['questionType']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? '',
      totalQuestions: int.tryParse(map['totalQuestions']?.toString() ?? '0') ?? parsedQuestions.length,
      durationMinutes: int.tryParse(map['durationMinutes']?.toString() ?? '90') ?? 90,
      academicYear: map['academicYear']?.toString() ?? '',
      semester: map['semester']?.toString() ?? '',
      schoolName: map['schoolName']?.toString() ?? '',
      teacherName: map['teacherName']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      questions: parsedQuestions,
    );
  }
}
