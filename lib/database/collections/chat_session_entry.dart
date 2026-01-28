import 'package:isar_community/isar.dart';

part 'chat_session_entry.g.dart';

@Collection()
class ChatSessionEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String sessionId;

  late String title;
  late DateTime createdAt;
  late DateTime lastMessageAt;
  late int messageCount;

  ChatSessionEntry();
}
