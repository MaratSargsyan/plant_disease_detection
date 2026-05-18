import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

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

  /// Returns the AI analysis text, or null if offline / no key / error.
  /// [offlineReason] is set to true when the call was skipped due to no internet.
  static Future<({String? text, bool offline})> analyseImage({
    required File imageFile,
    required String diseaseName,
    required String confidence,
  }) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) return (text: null, offline: false);

    final online = await ConnectivityService.isOnline();
    if (!online) return (text: null, offline: true);

    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);
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
                    'In 2-3 sentences: (1) note the key visual symptoms you see, '
                    '(2) comment on severity or spread, and '
                    '(3) give one immediate practical action the grower should take. '
                    'Be concise and direct.',
              },
            ],
          }
        ],
      });

      final response = await http
          .post(
            Uri.parse(_kEndpoint),
            headers: {
              'x-api-key': key,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final content = json['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          return (
            text: (content.first as Map<String, dynamic>)['text'] as String?,
            offline: false
          );
        }
      }
    } catch (_) {
      // Network or timeout — fail silently
    }
    return (text: null, offline: false);
  }
}
