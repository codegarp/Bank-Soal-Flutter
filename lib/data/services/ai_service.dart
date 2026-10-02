import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_settings_model.dart';
import '../models/question_model.dart';

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => message;
}

class AiService {
  final http.Client _client;

  AiService({http.Client? client}) : _client = client ?? http.Client();

  /// Clean key from accidental spaces, newlines, quotes
  String cleanKey(String rawKey) {
    return rawKey
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll(' ', '');
  }

  /// Safe error message extractor from HTTP Response
  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        if (decoded['error'] is Map) {
          final errorMap = decoded['error'] as Map;
          return errorMap['message']?.toString() ?? 'Kode ${response.statusCode}';
        } else if (decoded['error'] != null) {
          return decoded['error'].toString();
        } else if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }
    } catch (_) {}
    return 'Status ${response.statusCode} (${response.reasonPhrase ?? "Gagal"})';
  }

  /// Test connection with auto-detection for Groq (gsk_), Gemini (AQ./AIza), and Grok (xai-)
  Future<Map<String, dynamic>> testConnectionWithAutoDetect(String rawKey) async {
    final key = cleanKey(rawKey);
    if (key.isEmpty) {
      throw AiServiceException('API Key tidak boleh kosong.');
    }

    // 1. Groq Key (starts with gsk_) -> 100% FREE & ULTRA FAST
    if (key.startsWith('gsk_')) {
      return await _testGroqWithModelDiscovery(key);
    }

    // 2. Google Gemini Key (starts with AQ. or AIza)
    if (key.startsWith('AQ.') || key.startsWith('AIza')) {
      return await _testGeminiWithModelDiscovery(key);
    }

    // 3. xAI Grok Key (starts with xai-)
    if (key.startsWith('xai-')) {
      final ok = await _testGrokOpenAi(key, 'grok-2-mini', 'https://api.x.ai/v1');
      if (ok) {
        return {
          'provider': 'grok',
          'modelName': 'grok-2-mini',
          'apiBaseUrl': 'https://api.x.ai/v1',
          'message': 'Koneksi ke xAI Grok Berhasil! (Model: grok-2-mini)',
        };
      }
    }

    // 4. Try Groq first, then Gemini
    String? groqError;
    try {
      return await _testGroqWithModelDiscovery(key);
    } catch (e) {
      groqError = e.toString();
    }

    String? geminiError;
    try {
      return await _testGeminiWithModelDiscovery(key);
    } catch (e) {
      geminiError = e.toString();
    }

    throw AiServiceException(
      'Uji koneksi gagal:\n• Groq: $groqError\n• Gemini: $geminiError',
    );
  }

  /// Auto-discover available Groq models from API and test chat
  Future<Map<String, dynamic>> _testGroqWithModelDiscovery(String key) async {
    final modelsUrl = Uri.parse('https://api.groq.com/openai/v1/models');

    try {
      final response = await _client.get(
        modelsUrl,
        headers: {
          'Authorization': 'Bearer $key',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        String selectedModel = 'groq/compound-mini';

        if (decoded is Map && decoded['data'] is List) {
          final modelList = (decoded['data'] as List)
              .map((m) => m['id']?.toString() ?? '')
              .where((id) =>
                  id.isNotEmpty &&
                  !id.contains('whisper') &&
                  !id.contains('guard') &&
                  !id.contains('tool') &&
                  !id.contains('vision') &&
                  !id.contains('tts'))
              .toList();

          if (modelList.contains('openai/gpt-oss-20b')) {
            selectedModel = 'openai/gpt-oss-20b';
          } else if (modelList.contains('qwen/qwen3.8-27b')) {
            selectedModel = 'qwen/qwen3.8-27b';
          } else if (modelList.contains('openai/gpt-oss-120b')) {
            selectedModel = 'openai/gpt-oss-120b';
          } else if (modelList.contains('llama-3.3-70b-versatile')) {
            selectedModel = 'llama-3.3-70b-versatile';
          } else if (modelList.contains('llama-3.1-8b-instant')) {
            selectedModel = 'llama-3.1-8b-instant';
          } else if (modelList.contains('groq/compound-mini')) {
            selectedModel = 'groq/compound-mini';
          } else if (modelList.isNotEmpty) {
            selectedModel = modelList.first;
          }
        }

        // Test Chat Completion with the chosen model
        final chatRes = await _client.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': selectedModel,
            'messages': [
              {'role': 'user', 'content': 'Halo'}
            ],
            'max_tokens': 5,
          }),
        ).timeout(const Duration(seconds: 15));

        if (chatRes.statusCode == 200) {
          return {
            'provider': 'groq',
            'modelName': selectedModel,
            'apiBaseUrl': 'https://api.groq.com/openai/v1',
            'message': 'Koneksi ke Groq AI Berhasil! (Model Aktif: $selectedModel)',
          };
        } else {
          throw AiServiceException('Groq Chat Error: ${_extractErrorMessage(chatRes)}');
        }
      } else if (response.statusCode == 401) {
        throw AiServiceException('API Key Groq tidak valid (401 Unauthorized). Silakan salin ulang dari console.groq.com.');
      } else {
        throw AiServiceException('Groq Error: ${_extractErrorMessage(response)}');
      }
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Gagal terhubung ke Groq: $e');
    }
  }

  /// Auto-discover available Gemini models and test
  Future<Map<String, dynamic>> _testGeminiWithModelDiscovery(String key) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        String selectedModel = 'gemma-4-26b-a4b-it';

        if (decoded is Map && decoded['models'] is List) {
          final candidateModels = <String>[];
          for (var m in (decoded['models'] as List)) {
            final name = m['name']?.toString().replaceAll('models/', '') ?? '';
            final methods = (m['supportedGenerationMethods'] as List?)?.map((e) => e.toString()).toList() ?? [];
            if (methods.contains('generateContent') &&
                !name.contains('tts') &&
                !name.contains('embed') &&
                !name.contains('image') &&
                !name.contains('vision')) {
              candidateModels.add(name);
            }
          }

          // Sort so fast flash models come first
          candidateModels.sort((a, b) {
            int score(String s) {
              if (s == 'gemini-3.6-flash') return 0;
              if (s == 'gemini-3.5-flash') return 1;
              if (s == 'gemini-3-flash-preview') return 2;
              if (s.contains('flash')) return 3;
              return 10;
            }
            return score(a).compareTo(score(b));
          });

          for (final model in candidateModels) {
            try {
              final testRes = await _client.post(
                Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': 'Halo, jawab OK'}
                      ]
                    }
                  ],
                }),
              ).timeout(const Duration(seconds: 10));

              if (testRes.statusCode == 200) {
                selectedModel = model;
                return {
                  'provider': 'gemini',
                  'modelName': selectedModel,
                  'message': 'Koneksi ke Google Gemini Berhasil! (Model: $selectedModel)',
                };
              }
            } catch (_) {}
          }
        }

        return {
          'provider': 'gemini',
          'modelName': selectedModel,
          'message': 'Koneksi ke Google Gemini Berhasil! (Model: $selectedModel)',
        };
      } else {
        throw AiServiceException('Gemini API: ${_extractErrorMessage(response)}');
      }
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Gagal terhubung ke Gemini: $e');
    }
  }

  Future<bool> _testGrokOpenAi(String key, String model, String baseUrl) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'OK'}
          ],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw AiServiceException('API Key xAI Grok tidak valid (401 Unauthorized).');
      } else {
        throw AiServiceException('xAI Grok Error: ${_extractErrorMessage(response)}');
      }
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Gagal terhubung ke xAI Grok: $e');
    }
  }

  /// Generate Questions using AI (Groq, Gemini, or xAI Grok) with automatic batching for large counts
  Future<List<QuestionModel>> generateQuestions({
    required AppSettingsModel settings,
    required String subject,
    required String educationLevel,
    required String grade,
    required String curriculum,
    required List<String> topics,
    required String questionType,
    required String difficulty,
    required int totalQuestions,
  }) async {
    final key = cleanKey(settings.apiKey);
    if (key.isEmpty) {
      throw AiServiceException('API Key belum diatur. Masuk ke menu Pengaturan untuk memasukkan API Key.');
    }

    final topicsJoined = topics.join(', ');

    // For large requests (> 25 questions), generate in batches to ensure all questions are returned without truncation
    if (totalQuestions > 25) {
      final List<QuestionModel> allQuestions = [];
      final int batchSize = 25;
      final int numBatches = (totalQuestions / batchSize).ceil();

      for (int b = 0; b < numBatches; b++) {
        final int remaining = totalQuestions - allQuestions.length;
        final int currentCount = remaining > batchSize ? batchSize : remaining;
        if (currentCount <= 0) break;

        final batchList = await _generateBatch(
          settings: settings,
          key: key,
          subject: subject,
          educationLevel: educationLevel,
          grade: grade,
          curriculum: curriculum,
          topicsJoined: topicsJoined,
          questionType: questionType,
          difficulty: difficulty,
          count: currentCount,
        );

        allQuestions.addAll(batchList);
        if (allQuestions.length >= totalQuestions) break;
      }

      return allQuestions
          .asMap()
          .entries
          .map((e) => e.value.copyWith(number: e.key + 1))
          .toList();
    }

    return await _generateBatch(
      settings: settings,
      key: key,
      subject: subject,
      educationLevel: educationLevel,
      grade: grade,
      curriculum: curriculum,
      topicsJoined: topicsJoined,
      questionType: questionType,
      difficulty: difficulty,
      count: totalQuestions,
    );
  }

  Future<List<QuestionModel>> _generateBatch({
    required AppSettingsModel settings,
    required String key,
    required String subject,
    required String educationLevel,
    required String grade,
    required String curriculum,
    required String topicsJoined,
    required String questionType,
    required String difficulty,
    required int count,
  }) async {
    final systemPrompt = '''
Anda adalah AI Ahli Penyusun Soal dan Kurikulum Pendidikan Nasional Indonesia (Kemendikbudristek).
Tugas Anda adalah membuat bank soal ujian berkualitas tinggi, bermutu pedagogis, dan sesuai dengan standar kurikulum Indonesia.

PEDOMAN PEMBUATAN SOAL:
1. Kurikulum: $curriculum
2. Jenjang & Kelas: $educationLevel - $grade
3. Mata Pelajaran: $subject
4. Materi / Capaian Pembelajaran: $topicsJoined
5. Tingkat Kesulitan: $difficulty
6. Bentuk Soal: $questionType
7. Jumlah Total Soal: $count butir soal.

FORMAT ATURAN OPSI JAWABAN:
- Untuk jenjang SD & SMP: Pilihan ganda memiliki 4 opsi (A, B, C, D).
- Untuk jenjang SMA & SMK: Pilihan ganda memiliki 5 opsi (A, B, C, D, E).
- Kunci jawaban pilihan ganda harus berupa huruf kapital (misal: "A", "B", "C", "D", atau "E").
- Berikan pembahasan yang jelas, edukatif, dan langkah-langkah penyelesaian rinci untuk setiap butir soal.
- PENTING: Gunakan tanda petik tunggal (') di dalam teks soal/pembahasan jika ingin mengutip istilah agar format JSON tetap valid dan tidak error.

OUTPUT WAJIB DALAM FORMAT JSON MURNI:
Kembalikan HANYA array JSON (tanpa teks pembuka/penutup). Format tiap objek soal:
[
  {
    "number": 1,
    "questionText": "Teks soal lengkap...",
    "questionType": "PG",
    "options": [
      {"key": "A", "text": "Pilihan A"},
      {"key": "B", "text": "Pilihan B"},
      {"key": "C", "text": "Pilihan C"},
      {"key": "D", "text": "Pilihan D"}
    ],
    "correctAnswer": "A",
    "explanation": "Pembahasan lengkap dan jelas...",
    "difficulty": "Sedang",
    "topic": "Nama topik"
  }
]
''';

    final userPrompt = '''
Buatkan tepat $count butir soal untuk mata pelajaran "$subject" kelas "$grade" dengan materi "$topicsJoined".
Tingkat kesulitan: $difficulty.
Bentuk soal: $questionType.
Pastikan redaksi soal jelas, tidak ambigu, dan sesuai kaidah penulisan soal ujian Indonesia. Sertakan kunci jawaban dan pembahasan.
Keluarkan HANYA JSON array murni!
''';

    final isGroqKey = key.startsWith('gsk_') || settings.isGroq;
    final isGeminiKey = (!key.startsWith('gsk_') && !key.startsWith('xai-')) && (key.startsWith('AQ.') || key.startsWith('AIza') || settings.isGemini);

    if (isGroqKey) {
      final model = (settings.modelName.isNotEmpty &&
              settings.modelName != 'groq/compound-mini' &&
              settings.modelName != 'openai/gpt-oss-120b')
          ? settings.modelName
          : 'openai/gpt-oss-20b';
      return _generateWithOpenAiFormat(
        key: key,
        url: 'https://api.groq.com/openai/v1/chat/completions',
        modelName: model,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
    } else if (isGeminiKey) {
      return _generateWithGemini(
        key: key,
        modelName: settings.modelName.isNotEmpty ? settings.modelName : 'gemini-3.6-flash',
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
    } else {
      return _generateWithOpenAiFormat(
        key: key,
        url: '${settings.apiBaseUrl}/chat/completions',
        modelName: settings.modelName,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
    }
  }

  Future<List<QuestionModel>> _generateWithOpenAiFormat({
    required String key,
    required String url,
    required String modelName,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final uri = Uri.parse(url);

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.6,
          'max_tokens': 8192,
        }),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode != 200) {
        throw AiServiceException('API Error: ${_extractErrorMessage(response)}');
      }

      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final choices = responseData['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw AiServiceException('AI tidak memberikan jawaban. Silakan coba lagi.');
      }

      final content = choices[0]['message']?['content']?.toString() ?? '';
      return _parseQuestionsFromJson(content);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Terjadi kesalahan saat memproses soal: $e');
    }
  }

  Future<List<QuestionModel>> _generateWithGemini({
    required String key,
    required String modelName,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final model = modelName.isNotEmpty ? modelName : 'gemma-4-26b-a4b-it';
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': [
            {
              'parts': [
                {'text': userPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 8192,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode != 200) {
        throw AiServiceException('Gemini Error: ${_extractErrorMessage(response)}');
      }

      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw AiServiceException('Gemini tidak memberikan respon jawaban. Silakan coba lagi.');
      }

      final text = candidates[0]['content']?['parts']?[0]?['text']?.toString() ?? '';
      return _parseQuestionsFromJson(text);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Terjadi kesalahan pada Google Gemini: $e');
    }
  }

  /// Ultra-resilient JSON parser with automatic truncation recovery and object-level parsing
  List<QuestionModel> _parseQuestionsFromJson(String rawContent) {
    String cleaned = rawContent.trim();

    // 1. Remove Markdown code block wrappers if any
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // 2. Try Standard Full JSON Parse
    final firstBracket = cleaned.indexOf('[');
    final lastBracket = cleaned.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      final arraySubstr = cleaned.substring(firstBracket, lastBracket + 1);
      try {
        final dynamic decoded = jsonDecode(arraySubstr);
        if (decoded is List && decoded.isNotEmpty) {
          return _mapListToQuestions(decoded);
        }
      } catch (_) {}
    }

    // 3. Truncated Array Recovery: Find last complete closing brace '}' and close with ']'
    if (firstBracket != -1) {
      final lastBrace = cleaned.lastIndexOf('}');
      if (lastBrace != -1 && lastBrace > firstBracket) {
        final repairedJson = '${cleaned.substring(firstBracket, lastBrace + 1)}]';
        try {
          final dynamic decoded = jsonDecode(repairedJson);
          if (decoded is List && decoded.isNotEmpty) {
            return _mapListToQuestions(decoded);
          }
        } catch (_) {}
      }
    }

    // 4. Object-by-Object Recovery: Extract individual { ... } JSON objects
    final recoveredQuestions = <QuestionModel>[];
    int depth = 0;
    int startIndex = -1;
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];

      if (escape) {
        escape = false;
        continue;
      }

      if (char == '\\') {
        escape = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') {
          if (depth == 0) startIndex = i;
          depth++;
        } else if (char == '}') {
          depth--;
          if (depth == 0 && startIndex != -1) {
            final objStr = cleaned.substring(startIndex, i + 1);
            try {
              final decodedObj = jsonDecode(objStr);
              if (decodedObj is Map<String, dynamic>) {
                final q = QuestionModel.fromJson(decodedObj);
                if (q.questionText.isNotEmpty) {
                  recoveredQuestions.add(q.copyWith(
                    number: recoveredQuestions.length + 1,
                  ));
                }
              }
            } catch (_) {
              // Try regex field extraction for malformed objects
              final regexQ = _extractQuestionByRegex(objStr, recoveredQuestions.length + 1);
              if (regexQ != null) {
                recoveredQuestions.add(regexQ);
              }
            }
            startIndex = -1;
          }
        }
      }
    }

    if (recoveredQuestions.isNotEmpty) {
      return recoveredQuestions;
    }

    throw AiServiceException('Gagal menyusun format soal dari respon AI. Silakan coba klik tombol generate sekali lagi.');
  }

  List<QuestionModel> _mapListToQuestions(List list) {
    return list.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      if (item is Map<String, dynamic>) {
        final q = QuestionModel.fromJson(item);
        return q.copyWith(number: q.number > 0 ? q.number : index);
      }
      return QuestionModel(
        number: index,
        questionText: item.toString(),
        correctAnswer: 'A',
        explanation: '',
      );
    }).toList();
  }

  QuestionModel? _extractQuestionByRegex(String block, int fallbackNumber) {
    try {
      final textMatch = RegExp(r'"questionText"\s*:\s*"([^"]+)"').firstMatch(block) ??
          RegExp(r'"question"\s*:\s*"([^"]+)"').firstMatch(block);
      final ansMatch = RegExp(r'"correctAnswer"\s*:\s*"([^"]+)"').firstMatch(block) ??
          RegExp(r'"answer"\s*:\s*"([^"]+)"').firstMatch(block);
      final expMatch = RegExp(r'"explanation"\s*:\s*"([^"]+)"').firstMatch(block) ??
          RegExp(r'"pembahasan"\s*:\s*"([^"]+)"').firstMatch(block);

      if (textMatch != null && textMatch.group(1) != null) {
        return QuestionModel(
          number: fallbackNumber,
          questionText: textMatch.group(1)!,
          correctAnswer: ansMatch?.group(1) ?? 'A',
          explanation: expMatch?.group(1) ?? '',
        );
      }
    } catch (_) {}
    return null;
  }
}
