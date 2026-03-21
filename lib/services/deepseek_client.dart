import 'package:dio/dio.dart';

const _baseUrl = 'https://api.deepseek.com';

class DeepSeekClient {
  DeepSeekClient({required String apiKey}) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ));
  }

  late final Dio _dio;

  Future<String> chat(String systemPrompt, String userMessage) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/chat/completions',
      data: {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.2,
      },
    );
    final data = response.data;
    if (data == null) throw Exception('Empty response');
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) throw Exception('No choices');
    final content = (choices.first as Map<String, dynamic>)['message']?['content'];
    if (content == null) throw Exception('No content');
    return content as String;
  }
}
