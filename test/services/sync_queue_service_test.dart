import 'dart:async';

import 'package:egdata_flutter/models/epic_library_item.dart';
import 'package:egdata_flutter/models/upload_status.dart';
import 'package:egdata_flutter/services/epic_auth_service.dart';
import 'package:egdata_flutter/services/sync_queue_service.dart';
import 'package:egdata_flutter/services/upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUploadService extends UploadService {
  final Map<String, UploadStatus> results;

  FakeUploadService(this.results);

  @override
  Future<UploadStatus> uploadCloudManifest(
    EpicLibraryItem item,
    List<int> manifestBytes,
  ) async {
    return results[item.catalogItemId] ??
        UploadStatus(status: UploadStatusType.uploaded, message: 'Uploaded');
  }
}

EpicLibraryItem createItem(String id, {String? title}) {
  return EpicLibraryItem(
    appName: 'app-$id',
    title: title ?? 'Game $id',
    catalogItemId: id,
    namespace: 'ns',
    assetId: 'asset-$id',
  );
}

SyncQueueService createService({
  required UploadService uploadService,
  Future<List<int>?> Function(EpicLibraryItem item)? manifestLoader,
  int syncConcurrency = 5,
}) {
  return SyncQueueService(
    authService: EpicAuthService(),
    uploadService: uploadService,
    manifestLoader: manifestLoader ?? (_) async => [1, 2, 3],
    titleLoader: (_) async => const {},
    delayBetweenItems: Duration.zero,
    syncConcurrency: syncConcurrency,
  );
}

Future<void> pumpQueue() => Future<void>.delayed(Duration.zero);

void main() {
  group('SyncQueueEntry', () {
    test('uses library title as display title instead of item id', () {
      final entry = SyncQueueEntry(
        item: EpicLibraryItem(
          appName: 'artifact-id',
          title: 'Friendly Game Title',
          catalogItemId: 'catalog-id',
          namespace: 'ns',
          assetId: 'asset-id',
        ),
      );

      expect(entry.displayTitle, 'Friendly Game Title');
    });

    test('does not fall back to app name or ids when title is missing', () {
      final entry = SyncQueueEntry(
        item: EpicLibraryItem(
          appName: 'GameArtifact',
          title: 'catalog-id',
          catalogItemId: 'catalog-id',
          namespace: 'ns',
          assetId: 'asset-id',
        ),
      );

      expect(entry.displayTitle, 'Unknown item');
    });

    test('uses resolved item title before library title', () {
      final entry = SyncQueueEntry(
        item: EpicLibraryItem(
          appName: 'artifact-id',
          title: 'artifact-id',
          catalogItemId: 'catalog-id',
          namespace: 'ns',
          assetId: 'asset-id',
        ),
        displayTitle: 'Resolved Item Title',
      );

      expect(entry.displayTitle, 'Resolved Item Title');
    });
  });

  group('SyncQueueService controls', () {
    test('starts up to five sync entries by default', () async {
      final manifests = <String, Completer<List<int>?>>{};
      final service = createService(
        uploadService: FakeUploadService({}),
        manifestLoader: (item) {
          final completer = Completer<List<int>?>();
          manifests[item.catalogItemId] = completer;
          return completer.future;
        },
      );

      final run = service.startSync(
        items: List.generate(6, (index) => createItem('item-$index')),
      );
      await pumpQueue();

      expect(
        service.queue.where(
          (entry) => entry.state == SyncQueueEntryState.running,
        ),
        hasLength(5),
      );
      expect(service.queue.last.state, SyncQueueEntryState.pending);

      service.cancel();
      for (final completer in manifests.values) {
        if (!completer.isCompleted) completer.complete([1]);
      }
      await run;
    });

    test('pause and resume continues from the next pending item', () async {
      final firstManifest = Completer<List<int>?>();
      final first = createItem('one');
      final second = createItem('two');
      final service = createService(
        uploadService: FakeUploadService({}),
        syncConcurrency: 1,
        manifestLoader: (item) {
          if (item.catalogItemId == first.catalogItemId) {
            return firstManifest.future;
          }
          return Future.value([4, 5, 6]);
        },
      );

      final run = service.startSync(items: [first, second]);
      await pumpQueue();

      service.pause();
      firstManifest.complete([1, 2, 3]);
      await run;

      expect(service.status, SyncQueueStatus.paused);
      expect(service.queue[0].state, SyncQueueEntryState.uploaded);
      expect(service.queue[1].state, SyncQueueEntryState.pending);

      await service.resume();

      expect(service.status, SyncQueueStatus.completed);
      expect(service.queue[1].state, SyncQueueEntryState.uploaded);
    });

    test(
      'cancel marks pending entries cancelled without changing completed entries',
      () async {
        final firstManifest = Completer<List<int>?>();
        final items = [
          createItem('one'),
          createItem('two'),
          createItem('three'),
        ];
        final service = createService(
          uploadService: FakeUploadService({}),
          syncConcurrency: 1,
          manifestLoader: (item) {
            if (item.catalogItemId == 'one') return firstManifest.future;
            return Future.value([1]);
          },
        );

        final run = service.startSync(items: items);
        await pumpQueue();

        service.cancel();
        firstManifest.complete([1, 2, 3]);
        await run;

        expect(service.status, SyncQueueStatus.cancelled);
        expect(service.queue[0].state, SyncQueueEntryState.uploaded);
        expect(service.queue[1].state, SyncQueueEntryState.cancelled);
        expect(service.queue[2].state, SyncQueueEntryState.cancelled);
      },
    );

    test('retry failed resets failed skipped and cancelled entries', () async {
      final failed = createItem('failed');
      final skipped = createItem('skipped');
      final cancelled = createItem('cancelled');
      final ok = createItem('ok');
      final results = {
        'failed': UploadStatus(
          status: UploadStatusType.failed,
          message: 'Upload failed',
        ),
        'skipped': UploadStatus(
          status: UploadStatusType.failed,
          message: 'Manifest unavailable',
        ),
        'ok': UploadStatus(
          status: UploadStatusType.uploaded,
          message: 'Uploaded',
        ),
      };
      final service = createService(
        uploadService: FakeUploadService(results),
        manifestLoader: (item) {
          if (item.catalogItemId == 'skipped') return Future.value(null);
          return Future.value([1]);
        },
      );

      await service.startSync(items: [failed, skipped, cancelled, ok]);
      service.queue[2].state = SyncQueueEntryState.cancelled;
      service.queue[2].status = UploadStatusType.failed;
      results
        ..['failed'] = UploadStatus(
          status: UploadStatusType.uploaded,
          message: 'Retried',
        )
        ..['skipped'] = UploadStatus(
          status: UploadStatusType.uploaded,
          message: 'Retried',
        )
        ..['cancelled'] = UploadStatus(
          status: UploadStatusType.uploaded,
          message: 'Retried',
        );

      await service.retryFailed();

      expect(service.queue[0].state, SyncQueueEntryState.uploaded);
      expect(service.queue[1].state, SyncQueueEntryState.skipped);
      expect(service.queue[2].state, SyncQueueEntryState.uploaded);
      expect(service.queue[3].attempts, 1);
    });

    test('retry selected ignores the running entry', () async {
      final firstManifest = Completer<List<int>?>();
      final running = createItem('running');
      final failed = createItem('failed');
      final results = {
        'failed': UploadStatus(
          status: UploadStatusType.failed,
          message: 'Upload failed',
        ),
      };
      final service = createService(
        uploadService: FakeUploadService(results),
        syncConcurrency: 1,
        manifestLoader: (item) {
          if (item.catalogItemId == 'running') return firstManifest.future;
          return Future.value([1]);
        },
      );

      final run = service.startSync(items: [running, failed]);
      await pumpQueue();

      final runningId = service.queue[0].identityKey;
      service.queue[1]
        ..state = SyncQueueEntryState.failed
        ..status = UploadStatusType.failed;
      results['failed'] = UploadStatus(
        status: UploadStatusType.uploaded,
        message: 'Retried',
      );

      await service.retryEntries({runningId, service.queue[1].identityKey});

      expect(service.queue[0].state, SyncQueueEntryState.running);
      expect(service.queue[1].state, SyncQueueEntryState.pending);

      service.cancel();
      firstManifest.complete([1]);
      await run;

      expect(service.queue[1].state, SyncQueueEntryState.cancelled);
    });

    test('remove selected does not remove the running entry', () async {
      final firstManifest = Completer<List<int>?>();
      final service = createService(
        uploadService: FakeUploadService({}),
        syncConcurrency: 1,
        manifestLoader: (item) {
          if (item.catalogItemId == 'running') return firstManifest.future;
          return Future.value([1]);
        },
      );

      final run = service.startSync(
        items: [createItem('running'), createItem('pending')],
      );
      await pumpQueue();

      service.removeEntries({
        service.queue[0].identityKey,
        service.queue[1].identityKey,
      });

      expect(service.queue[0].state, SyncQueueEntryState.running);
      expect(service.queue[1].state, SyncQueueEntryState.removed);

      service.cancel();
      firstManifest.complete([1]);
      await run;
    });

    test('ownedUploadStatuses reports useful library card statuses', () async {
      final firstManifest = Completer<List<int>?>();
      final service = createService(
        uploadService: FakeUploadService({}),
        manifestLoader: (_) => firstManifest.future,
      );

      final run = service.startSync(items: [createItem('running')]);
      await pumpQueue();

      final entry = service.queue.single;
      expect(
        service.ownedUploadStatuses[entry.identityKey]?.status,
        UploadStatusType.uploading,
      );
      expect(service.syncingIdentityKeys, contains(entry.identityKey));

      firstManifest.complete([1]);
      await run;
    });
  });
}
