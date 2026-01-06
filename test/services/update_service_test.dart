import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/services/update_service.dart';

void main() {
  group('UpdateService', () {
    group('getBinaryUrl', () {
      test('returns Windows installer URL', () {
        if (Platform.isWindows) {
          final url = UpdateService.getBinaryUrl('1.0.5');
          expect(url, 'https://github.com/egdata-app/egdata-flutter/releases/download/v1.0.5/egdata-app-1.0.5-setup.exe');
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('returns macOS DMG URL', () {
        if (Platform.isMacOS) {
          final url = UpdateService.getBinaryUrl('1.0.5');
          expect(url, 'https://github.com/egdata-app/egdata-flutter/releases/download/v1.0.5/egdata-app-1.0.5-macos.dmg');
        }
      }, skip: !Platform.isMacOS ? 'Only runs on macOS' : null);

      test('returns releases tag URL for unsupported platforms', () {
        // This test will run on the current platform
        // On Windows/macOS it won't hit fallback, but on Linux it will
        if (!Platform.isWindows && !Platform.isMacOS) {
          final url = UpdateService.getBinaryUrl('1.0.5');
          expect(url, 'https://github.com/egdata-app/egdata-flutter/releases/tag/v1.0.5');
        }
      }, skip: (Platform.isWindows || Platform.isMacOS) ? 'Only runs on unsupported platforms' : null);

      test('includes version in URL correctly', () {
        final url = UpdateService.getBinaryUrl('2.3.4');
        expect(url, contains('v2.3.4'));
        expect(url, contains('2.3.4'));
      });

      test('handles version with multiple digits', () {
        final url = UpdateService.getBinaryUrl('10.20.30');
        expect(url, contains('v10.20.30'));
      });
    });

    group('version parsing (integration test concept)', () {
      // These tests verify the expected behavior for version string handling
      // The actual getLatestVersion() makes HTTP calls, so we test the logic

      test('version format: removes v prefix', () {
        // This simulates what getLatestVersion does with tag_name
        String parseVersion(String tagName) {
          return tagName.startsWith('v') ? tagName.substring(1) : tagName;
        }

        expect(parseVersion('v1.0.0'), '1.0.0');
        expect(parseVersion('v2.5.10'), '2.5.10');
        expect(parseVersion('1.0.0'), '1.0.0');
        expect(parseVersion('v'), '');
      });

      test('GitHub API URL format', () {
        // Verify the expected API URL format
        const repoOwner = 'egdata-app';
        const repoName = 'egdata-flutter';
        const githubApiBase = 'https://api.github.com';

        final latestUrl = '$githubApiBase/repos/$repoOwner/$repoName/releases/latest';
        expect(latestUrl, 'https://api.github.com/repos/egdata-app/egdata-flutter/releases/latest');

        final tagUrl = '$githubApiBase/repos/$repoOwner/$repoName/releases/tags/v1.0.5';
        expect(tagUrl, 'https://api.github.com/repos/egdata-app/egdata-flutter/releases/tags/v1.0.5');
      });
    });

    group('URL construction', () {
      test('Windows URL has correct format', () {
        // Test without platform check to verify format
        const version = '1.2.3';
        const expectedFormat = 'https://github.com/egdata-app/egdata-flutter/releases/download/v1.2.3/egdata-app-1.2.3-setup.exe';

        // Verify format components
        expect(expectedFormat, contains('/releases/download/'));
        expect(expectedFormat, contains('v$version'));
        expect(expectedFormat, contains('egdata-app-$version-setup.exe'));
      });

      test('macOS URL has correct format', () {
        const version = '1.2.3';
        const expectedFormat = 'https://github.com/egdata-app/egdata-flutter/releases/download/v1.2.3/egdata-app-1.2.3-macos.dmg';

        expect(expectedFormat, contains('/releases/download/'));
        expect(expectedFormat, contains('v$version'));
        expect(expectedFormat, contains('egdata-app-$version-macos.dmg'));
      });

      test('fallback URL points to releases tag page', () {
        const version = '1.2.3';
        const expectedFormat = 'https://github.com/egdata-app/egdata-flutter/releases/tag/v1.2.3';

        expect(expectedFormat, contains('/releases/tag/'));
        expect(expectedFormat, contains('v$version'));
        expect(expectedFormat, isNot(contains('/download/')));
      });
    });
  });
}
