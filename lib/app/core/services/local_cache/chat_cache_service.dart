import 'package:hive/hive.dart';

class ChatCacheService {
  ChatCacheService._();

  static const String _chatListBox = 'chat_list_box';
  static const String _messagesBox = 'messages_box';
  static const String _chatListKey = 'my_chats';

  static Future<void> init() async {
    // Open boxes once at app start.
    await Hive.openBox(_chatListBox);
    await Hive.openBox(_messagesBox);
  }

  static Box _chatList() => Hive.box(_chatListBox);
  static Box _messages() => Hive.box(_messagesBox);

  static List<Map<String, dynamic>> getCachedChats() {
    final raw = _chatList().get(_chatListKey, defaultValue: <dynamic>[]);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => _normalizeMap(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    // Store a plain List<Map> to keep Hive simple (no adapters required).
    await _chatList().put(
      _chatListKey,
      chats.map((e) => _normalizeMap(e)).toList(),
    );
  }

  static List<Map<String, dynamic>> getCachedMessages(String chatId) {
    if (chatId.isEmpty) return <Map<String, dynamic>>[];
    final raw = _messages().get(chatId, defaultValue: <dynamic>[]);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => _normalizeMap(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> saveMessages(
    String chatId,
    List<Map<String, dynamic>> messages,
  ) async {
    if (chatId.isEmpty) return;
    await _messages().put(
      chatId,
      messages.map((e) => _normalizeMap(e)).toList(),
    );
  }

  static Map<String, dynamic> _normalizeMap(Map input) {
    final Map<String, dynamic> out = {};
    input.forEach((key, value) {
      final String k = key.toString();
      if (value is Map) {
        out[k] = _normalizeMap(value);
      } else if (value is List) {
        out[k] = value.map((e) {
          if (e is Map) return _normalizeMap(e);
          return e;
        }).toList();
      } else {
        out[k] = value;
      }
    });
    return out;
  }
}
