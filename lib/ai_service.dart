import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApiKeyPref = 'claude_api_key';
const String _kModel = 'claude-haiku-4-5-20251001';
const String _kEndpoint = 'https://api.anthropic.com/v1/messages';

class AiService {
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kApiKeyPref);
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKeyPref, key.trim());
  }

  /// Analyses [imageFile] using Claude vision and returns a brief description.
  /// Returns null if no API key is configured or on error.
  static Future<String?> analyseImage({
    required File imageFile,
    required String diseaseName,
    required String confidence,
  }) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) return null;

    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);

    // Detect mime type by file extension
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

    final body = jsonEncode({
      'model': _kModel,
      'max_tokens': 256,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {'type': 'base64', 'media_type': mime, 'data': b64},
            },
            {
              'type': 'text',
              'text':
                  'This plant image was classified as "$diseaseName" with $confidence confidence. '
                  'In 2-3 concise sentences, describe what you observe in the image and '
                  'briefly confirm or add context about this diagnosis. Be practical.',
            },
          ],
        }
      ],
    });

    try {
      final response = await http.post(
        Uri.parse(_kEndpoint),
        headers: {
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final content = json['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          return (content.first as Map<String, dynamic>)['text'] as String?;
        }
      }
    } catch (_) {
      // Network or timeout — fail silently
    }
    return null;
  }
}
