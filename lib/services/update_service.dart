import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class UpdateService {
  static const String _repoOwner = 'egdata-app';
  static const String _repoName = 'egdata-flutter';
  static const String _githubApiBase = 'https://api.github.com';

  /// Fetches the latest version from GitHub Releases.
  /// Returns the version string (e.g., "1.0.1") or null if failed.
  static Future<String?> getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$_githubApiBase/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = json['tag_name'] as String?;
        if (tagName != null) {
          // Remove 'v' prefix if present (e.g., "v1.0.1" -> "1.0.1")
          return tagName.startsWith('v') ? tagName.substring(1) : tagName;
        }
      }
    } catch (e) {
      // Silently fail - update check is not critical
    }
    return null;
  }

  /// Returns the download URL for the installer based on the platform.
  static String getBinaryUrl(String version) {
    if (Platform.isWindows) {
      return 'https://github.com/$_repoOwner/$_repoName/releases/download/v$version/egdata-app-$version-setup.exe';
    } else if (Platform.isMacOS) {
      return 'https://github.com/$_repoOwner/$_repoName/releases/download/v$version/egdata-app-$version-macos.dmg';
    }
    // Fallback for unsupported platforms
    return 'https://github.com/$_repoOwner/$_repoName/releases/tag/v$version';
  }

  /// Fetches the changelog/release notes for a specific version.
  static Future<String?> getChangelog(String version) async {
    try {
      final response = await http.get(
        Uri.parse('$_githubApiBase/repos/$_repoOwner/$_repoName/releases/tags/v$version'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['body'] as String?;
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }
}
