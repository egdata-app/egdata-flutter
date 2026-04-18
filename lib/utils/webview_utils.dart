import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> getWebViewUserDataFolder() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final webViewDirectory = Directory(
    p.join(supportDirectory.path, 'webview_window_WebView2'),
  );

  await webViewDirectory.create(recursive: true);
  return webViewDirectory.path;
}
