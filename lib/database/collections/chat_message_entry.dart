import 'package:isar/isar.dart';

part 'chat_message_entry.g.dart';

@Collection()
class ChatMessageEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late String messageId;

  late String content;
  late bool isUser;
  late DateTime timestamp;

  // JSON serialized game results (List<Offer>) for messages with search results
  String? gameResultsJson;

  ChatMessageEntry();
}
