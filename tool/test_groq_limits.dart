import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final groqKey = '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';
  final models = [
    'openai/gpt-oss-20b',
    'qwen/qwen3.8-27b',
    'allam-2-7b',
  ];

  for (final m in models) {
    final sw = Stopwatch()..start();
    try {
      final res = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqKey',
        },
        body: jsonEncode({
          'model': m,
          'messages': [
            {'role': 'user', 'content': 'Buat 5 butir soal IPA SMP kelas 8 format JSON array.'}
          ],
          'temperature': 0.6,
          'max_tokens': 2048,
        }),
      );
      print('Groq $m -> Status: ${res.statusCode} in ${sw.elapsedMilliseconds}ms');
      if (res.statusCode != 200) {
        print('  Error: ${res.body}');
      } else {
        print('  Success! Response length: ${res.body.length}');
      }
    } catch (e) {
      print('Groq $m exception: $e');
    }
  }
}
