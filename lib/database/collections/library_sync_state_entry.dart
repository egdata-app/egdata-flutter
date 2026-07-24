import 'package:isar_community/isar.dart';

import '../../models/epic_progress.dart';

part 'library_sync_state_entry.g.dart';

@Collection()
class LibrarySyncStateEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  String? status;
  String? title;
  String? message;
  String? evidencePacked;
  DateTime? checkedAt;
  late DateTime updatedAt;

  LibrarySyncStateEntry();

  factory LibrarySyncStateEntry.fromProgressProof(
    EpicProgressProofResult proof,
  ) {
    return LibrarySyncStateEntry()
      ..key = 'official_progress'
      ..status = proof.status.name
      ..title = proof.title
      ..message = proof.message
      ..evidencePacked = proof.evidence.join('\n')
      ..checkedAt = proof.checkedAt
      ..updatedAt = DateTime.now();
  }

  @ignore
  EpicProgressProofResult? get progressProof {
    if (key != 'official_progress') return null;
    final rawStatus = status;
    final parsedStatus = EpicProgressProofStatus.values
        .where((value) => value.name == rawStatus)
        .firstOrNull;
    if (parsedStatus == null) return null;
    return EpicProgressProofResult(
      status: parsedStatus,
      title: title ?? 'Official progress status',
      message: message ?? '',
      checkedAt: checkedAt ?? updatedAt,
      evidence: evidencePacked == null || evidencePacked!.isEmpty
          ? const []
          : evidencePacked!.split('\n'),
    );
  }
}
