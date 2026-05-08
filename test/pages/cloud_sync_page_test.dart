import 'dart:async';

import 'package:egdata_flutter/models/epic_library_item.dart';
import 'package:egdata_flutter/models/upload_status.dart';
import 'package:egdata_flutter/pages/cloud_sync_page.dart';
import 'package:egdata_flutter/services/epic_auth_service.dart';
import 'package:egdata_flutter/services/sync_queue_service.dart';
import 'package:egdata_flutter/services/upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    title: title ?? 'Friendly $id',
    catalogItemId: id,
    namespace: 'ns',
    assetId: 'asset-$id',
  );
}

SyncQueueService createService({
  required UploadService uploadService,
  Future<List<int>?> Function(EpicLibraryItem item)? manifestLoader,
}) {
  return SyncQueueService(
    authService: EpicAuthService(),
    uploadService: uploadService,
    manifestLoader: manifestLoader ?? (_) async => [1, 2, 3],
    titleLoader: (_) async => const {},
    delayBetweenItems: Duration.zero,
  );
}

Widget buildPage(SyncQueueService service) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        height: 820,
        child: CloudSyncPage(
          authService: EpicAuthService(),
          syncQueueService: service,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'epic_access_token': 'test-token',
      'epic_account_id': 'test-account',
    });
  });

  testWidgets('renders the empty idle state', (tester) async {
    final service = createService(uploadService: FakeUploadService({}));

    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    expect(find.text('Cloud Sync'), findsOneWidget);
    expect(find.text('Queue is empty'), findsOneWidget);
    expect(find.text('Start Full Sync'), findsOneWidget);
  });

  testWidgets('shows friendly titles instead of catalog ids', (tester) async {
    final service = createService(uploadService: FakeUploadService({}));

    await service.startSync(
      items: [createItem('catalog-id', title: 'Friendly Game Title')],
    );

    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    expect(find.text('Friendly Game Title'), findsOneWidget);
    expect(find.text('catalog-id'), findsNothing);
  });

  testWidgets('filters queue rows by status', (tester) async {
    final service = createService(
      uploadService: FakeUploadService({
        'failed': UploadStatus(
          status: UploadStatusType.failed,
          message: 'Upload failed',
        ),
      }),
    );

    await service.startSync(
      items: [
        createItem('failed', title: 'Failed Game'),
        createItem('ok', title: 'Uploaded Game'),
      ],
    );

    await tester.pumpWidget(buildPage(service));
    await tester.pump();
    await tester.tap(find.text('Failed 1'));
    await tester.pump();

    expect(find.text('Failed Game'), findsOneWidget);
    expect(find.text('Uploaded Game'), findsNothing);
  });

  testWidgets('disables invalid row actions for the running row', (
    tester,
  ) async {
    final manifest = Completer<List<int>?>();
    final service = createService(
      uploadService: FakeUploadService({}),
      manifestLoader: (_) => manifest.future,
    );

    unawaited(service.startSync(items: [createItem('running')]));
    await Future<void>.delayed(Duration.zero);

    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(checkbox.onChanged, isNull);

    service.cancel();
    manifest.complete([1]);
  });
}
