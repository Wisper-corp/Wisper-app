/// Reading presence out of what the socket already sends.
///
/// The server pushes the whole `chatList` whenever anyone in it connects or
/// disconnects, with `isOnline` set on every participant, and a `typingStatus`
/// event whenever someone starts or stops typing. Both were arriving and
/// neither was being read: the chat header took a bool passed in when the
/// screen opened and never changed it, and the typing handler only printed.
///
/// These are plain functions on plain maps so they can be tested against the
/// real payload shapes without a socket or a controller.
library;

/// The other person's online state for [chatId], or null when the payload says
/// nothing about it.
///
/// Null means "no news" rather than "offline" — a chat list that does not
/// mention this conversation must not knock the header back to Offline.
bool? peerOnlineFromChatList(
  dynamic payload, {
  required String chatId,
  required String myAuthId,
}) {
  final chats = _chatsOf(payload);
  if (chats == null) return null;

  for (final chat in chats) {
    if (chat is! Map) continue;
    if (chat['id']?.toString() != chatId) continue;

    final participants = chat['participants'];
    if (participants is! List) return null;

    for (final p in participants) {
      if (p is! Map) continue;
      final authId = _authIdOf(p);
      // The other one. With no id to compare against we cannot tell which
      // participant is which, so we say nothing rather than guess.
      if (authId == null || authId.isEmpty) continue;
      if (myAuthId.isNotEmpty && authId == myAuthId) continue;

      final online = p['isOnline'];
      if (online is bool) return online;
      if (online is String) return online.toLowerCase() == 'true';
      return null;
    }
    return null;
  }
  return null;
}

/// Whether the other person is typing, from a `typingStatus` event, or null
/// when the event is about a different chat or about us.
bool? peerTypingFromEvent(
  dynamic data, {
  required String chatId,
  required String myAuthId,
}) {
  if (data is! Map) return null;
  if (data['chatId']?.toString() != chatId) return null;

  // Our own typing echoes back on a second device; it is not news about them.
  final who = data['userId']?.toString();
  if (who != null && myAuthId.isNotEmpty && who == myAuthId) return null;

  final typing = data['isTyping'];
  if (typing is bool) return typing;
  if (typing is String) return typing.toLowerCase() == 'true';
  return null;
}

/// The chat list, wherever it is in the payload.
///
/// The socket service wraps what it receives as `{receivedAt, payload}`, the
/// socket sends `{meta, chats}`, and the REST route wraps that again in
/// `data`. Accepting all three keeps the caller from caring which it got.
List? _chatsOf(dynamic payload) {
  var node = payload;
  for (var depth = 0; depth < 4; depth++) {
    if (node is List) return node;
    if (node is! Map) return null;
    if (node['chats'] is List) return node['chats'] as List;
    node = node['payload'] ?? node['data'];
    if (node == null) return null;
  }
  return null;
}

String? _authIdOf(Map participant) {
  final auth = participant['auth'];
  if (auth is Map && auth['id'] != null) return auth['id'].toString();
  // Some payloads flatten it.
  return participant['authId']?.toString();
}
