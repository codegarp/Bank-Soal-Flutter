class AppSettingsModel {
  final String provider; // 'groq', 'gemini', or 'grok'
  final String apiKey;
  final String apiBaseUrl;
  final String modelName;
  final String schoolName;
  final String schoolAddress;
  final String schoolPhone;
  final String teacherName;
  final String teacherNip;
  final String academicYear;
  final String semester;

  const AppSettingsModel({
    this.provider = 'groq',
    this.apiKey = '',
    this.apiBaseUrl = 'https://api.groq.com/openai/v1',
    this.modelName = 'llama-3.3-70b-versatile',
    this.schoolName = 'SMA Negeri 1 Indonesia',
    this.schoolAddress = 'Jl. Pendidikan No. 1, Kota Belajar',
    this.schoolPhone = '021-1234567',
    this.teacherName = 'Guru Teladan, S.Pd.',
    this.teacherNip = '19850101 201001 1 001',
    this.academicYear = '2024/2025',
    this.semester = 'Ganjil',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;
  bool get isGemini => provider.toLowerCase() == 'gemini';
  bool get isGroq => provider.toLowerCase() == 'groq';
  bool get isGrok => provider.toLowerCase() == 'grok';

  AppSettingsModel copyWith({
    String? provider,
    String? apiKey,
    String? apiBaseUrl,
    String? modelName,
    String? schoolName,
    String? schoolAddress,
    String? schoolPhone,
    String? teacherName,
    String? teacherNip,
    String? academicYear,
    String? semester,
  }) {
    return AppSettingsModel(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      modelName: modelName ?? this.modelName,
      schoolName: schoolName ?? this.schoolName,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      schoolPhone: schoolPhone ?? this.schoolPhone,
      teacherName: teacherName ?? this.teacherName,
      teacherNip: teacherNip ?? this.teacherNip,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'apiKey': apiKey,
      'apiBaseUrl': apiBaseUrl,
      'modelName': modelName,
      'schoolName': schoolName,
      'schoolAddress': schoolAddress,
      'schoolPhone': schoolPhone,
      'teacherName': teacherName,
      'teacherNip': teacherNip,
      'academicYear': academicYear,
      'semester': semester,
    };
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      provider: json['provider'] ?? 'groq',
      apiKey: json['apiKey'] ?? '',
      apiBaseUrl: json['apiBaseUrl'] ?? 'https://api.groq.com/openai/v1',
      modelName: json['modelName'] ?? 'llama-3.3-70b-versatile',
      schoolName: json['schoolName'] ?? 'SMA Negeri 1 Indonesia',
      schoolAddress:
          json['schoolAddress'] ?? 'Jl. Pendidikan No. 1, Kota Belajar',
      schoolPhone: json['schoolPhone'] ?? '021-1234567',
      teacherName: json['teacherName'] ?? 'Guru Teladan, S.Pd.',
      teacherNip: json['teacherNip'] ?? '19850101 201001 1 001',
      academicYear: json['academicYear'] ?? '2024/2025',
      semester: json['semester'] ?? 'Ganjil',
    );
  }

  static const List<String> groqModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
  ];

  static const List<String> geminiModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.5-flash',
  ];

  static const List<String> grokModels = [
    'grok-2-mini',
    'grok-2',
    'grok-beta',
  ];
}
