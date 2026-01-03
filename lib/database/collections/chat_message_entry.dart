import 'package:isar/isar.dart';

part 'chat_message_entry.g.dart';

@Collection()
class ChatMessageEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late String messageId;

  @Index()
  late String sessionId;

  late String role; // "user" or "assistant"
  late String content;
  late DateTime timestamp;

  ChatMessageEntry();
}
