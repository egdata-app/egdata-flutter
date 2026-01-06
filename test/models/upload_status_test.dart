import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/upload_status.dart';

void main() {
  group('UploadStatus', () {
    group('fromJson - status field mapping', () {
      test('maps "uploaded" to uploaded', () {
        final json = {'status': 'uploaded', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('maps "success" to uploaded', () {
        final json = {'status': 'success', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('maps "created" to uploaded', () {
        final json = {'status': 'created', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('maps "ok" to uploaded', () {
        final json = {'status': 'ok', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('maps "already_uploaded" to alreadyUploaded', () {
        final json = {'status': 'already_uploaded', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.alreadyUploaded);
      });

      test('maps "exists" to alreadyUploaded', () {
        final json = {'status': 'exists', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.alreadyUploaded);
      });

      test('maps "duplicate" to alreadyUploaded', () {
        final json = {'status': 'duplicate', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.alreadyUploaded);
      });

      test('maps "failed" to failed', () {
        final json = {'status': 'failed', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.failed);
      });

      test('maps "error" to failed', () {
        final json = {'status': 'error', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.failed);
      });

      test('is case insensitive', () {
        final json = {'status': 'UPLOADED', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('handles mixed case', () {
        final json = {'status': 'AlReAdY_UpLoAdEd', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.alreadyUploaded);
      });
    });

    group('fromJson - message fallback', () {
      test('falls back to uploaded when message contains "success"', () {
        final json = {'status': 'unknown', 'message': 'Upload was a success!'};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('falls back to uploaded when message contains "uploaded"', () {
        final json = {'status': '', 'message': 'File uploaded successfully'};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.uploaded);
      });

      test('falls back to alreadyUploaded when message contains "already"', () {
        // Note: "already uploaded" would match "uploaded" first, so use a message without "uploaded"
        final json = {'status': 'unknown', 'message': 'This file was already processed'};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.alreadyUploaded);
      });

      test('falls back to alreadyUploaded when message contains "exists"', () {
        final json = {'status': '', 'message': 'File already exists in the system'};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.alreadyUploaded);
      });

      test('falls back to failed for unrecognized status and message', () {
        final json = {'status': 'unknown', 'message': 'Something went wrong'};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.failed);
      });

      test('falls back to failed when message is empty', () {
        final json = {'status': 'unknown', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.failed);
      });
    });

    group('fromJson - field extraction', () {
      test('extracts message field', () {
        final json = {'status': 'uploaded', 'message': 'Custom message'};
        final status = UploadStatus.fromJson(json);
        expect(status.message, 'Custom message');
      });

      test('extracts manifest_hash field', () {
        final json = {
          'status': 'uploaded',
          'message': '',
          'manifest_hash': 'abc123',
        };
        final status = UploadStatus.fromJson(json);
        expect(status.manifestHash, 'abc123');
      });

      test('handles missing manifest_hash', () {
        final json = {'status': 'uploaded', 'message': ''};
        final status = UploadStatus.fromJson(json);
        expect(status.manifestHash, isNull);
      });

      test('handles null message', () {
        final json = {'status': 'uploaded', 'message': null};
        final status = UploadStatus.fromJson(json);
        expect(status.message, '');
      });

      test('handles missing message', () {
        final json = {'status': 'uploaded'};
        final status = UploadStatus.fromJson(json);
        expect(status.message, '');
      });

      test('handles missing status', () {
        final json = {'message': 'No status provided'};
        final status = UploadStatus.fromJson(json);
        // Falls back to failed since empty status doesn't match any case
        expect(status.status, UploadStatusType.failed);
      });
    });

    group('fromJson - edge cases', () {
      test('handles empty JSON', () {
        final json = <String, dynamic>{};
        final status = UploadStatus.fromJson(json);
        expect(status.status, UploadStatusType.failed);
        expect(status.message, '');
        expect(status.manifestHash, isNull);
      });

      test('handles status as non-string (int)', () {
        final json = {'status': 200, 'message': ''};
        final status = UploadStatus.fromJson(json);
        // toString() on 200 gives '200', which doesn't match any case
        expect(status.status, UploadStatusType.failed);
      });
    });
  });
}
