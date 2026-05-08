import 'package:url_launcher/url_launcher.dart';

/// Builds and launches `com.epicgames.launcher://` protocol URIs.
///
/// Reference: https://dev.epicgames.com/docs/epic-games-store/protocol-activation
class EpicProtocol {
  EpicProtocol._();

  static const String scheme = 'com.epicgames.launcher';

  /// Launches an installed game.
  ///
  /// When [namespace] and [itemId] are supplied, the launcher will fetch the
  /// owned entitlement before launch. Otherwise the [appName] alone is used.
  /// [silent] suppresses launcher pop-ups during launch.
  static Uri launchApp(
    String appName, {
    String? namespace,
    String? itemId,
    bool silent = true,
    Map<String, String>? extraArgs,
  }) {
    return _appUri(
      appName,
      namespace: namespace,
      itemId: itemId,
      action: 'launch',
      params: {
        'silent': silent.toString(),
        if (extraArgs != null) ...extraArgs,
      },
    );
  }

  /// Installs / starts the download for an owned game.
  static Uri installApp(
    String appName, {
    String? namespace,
    String? itemId,
  }) {
    return _appUri(
      appName,
      namespace: namespace,
      itemId: itemId,
      action: 'install',
    );
  }

  static Uri uninstallApp(String appName) {
    return _appUri(appName, action: 'uninstall');
  }

  static Uri updateApp(String appName) {
    return _appUri(appName, action: 'update');
  }

  static Uri verifyApp(String appName) {
    return _appUri(appName, action: 'verify');
  }

  /// Opens a product detail page inside the launcher.
  ///
  /// Either pass a store [slug] (e.g. `fortnite`) or the catalog
  /// [namespace] + [itemId] + [appName] triplet.
  static Uri productDetailPage({
    String? slug,
    String? namespace,
    String? itemId,
    String? appName,
  }) {
    if (slug != null && slug.isNotEmpty) {
      return Uri.parse('$scheme://store/p/${Uri.encodeComponent(slug)}');
    }
    if (namespace != null && itemId != null && appName != null) {
      return _appUri(
        appName,
        namespace: namespace,
        itemId: itemId,
        action: 'show-pdp',
      );
    }
    throw ArgumentError(
      'productDetailPage requires either a slug or (namespace, itemId, appName)',
    );
  }

  static Uri storeHome() => Uri.parse('$scheme://store/home');
  static Uri storeLibrary() => Uri.parse('$scheme://store/library');
  static Uri storeWishlist() => Uri.parse('$scheme://store/wishlist');
  static Uri storeBrowse() => Uri.parse('$scheme://store/browse');
  static Uri storeDiscover() => Uri.parse('$scheme://store/discover');
  static Uri storeAccount() => Uri.parse('$scheme://store/account');
  static Uri storeDownloads() => Uri.parse('$scheme://store/downloads');

  /// Parses an incoming `com.epicgames.launcher://...` URL into a typed
  /// activation. Returns `null` if the URL does not match the scheme.
  ///
  /// Used when the OS launches the app via deep link / argv (e.g. EGS first-
  /// party titles receiving session invalidation callbacks).
  static EpicProtocolActivation? parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != scheme) return null;

    final segments = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final host = uri.host;

    if (host == 'apps' && segments.isNotEmpty) {
      final parts = Uri.decodeComponent(segments.first).split(':');
      String? namespace;
      String? itemId;
      String appName;
      if (parts.length == 3) {
        namespace = parts[0];
        itemId = parts[1];
        appName = parts[2];
      } else {
        appName = parts.first;
      }
      return EpicAppActivation(
        appName: appName,
        namespace: namespace,
        itemId: itemId,
        action: uri.queryParameters['action'],
        params: Map.unmodifiable(uri.queryParameters),
      );
    }

    if (host == 'store') {
      final section = segments.isNotEmpty ? segments.first : '';
      final detail = segments.length > 1
          ? Uri.decodeComponent(segments[1])
          : null;
      return EpicStoreActivation(
        section: section,
        detail: detail,
        params: Map.unmodifiable(uri.queryParameters),
        sessionInvalidated:
            uri.queryParameters['sessionInvalidated']?.toLowerCase() == 'true',
      );
    }

    return EpicUnknownActivation(
      uri: uri,
      params: Map.unmodifiable(uri.queryParameters),
    );
  }

  /// Hands the URI to the OS so the Epic Games Launcher can handle it.
  /// Returns `false` when no handler is registered (launcher not installed).
  static Future<bool> launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Uri _appUri(
    String appName, {
    String? namespace,
    String? itemId,
    required String action,
    Map<String, String>? params,
  }) {
    final hasTriplet = namespace != null && itemId != null;
    final identifier = hasTriplet
        ? '${Uri.encodeComponent(namespace)}%3A${Uri.encodeComponent(itemId)}%3A${Uri.encodeComponent(appName)}'
        : Uri.encodeComponent(appName);

    final query = <String, String>{'action': action, ...?params};
    final queryString = query.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    return Uri.parse('$scheme://apps/$identifier?$queryString');
  }
}

sealed class EpicProtocolActivation {
  const EpicProtocolActivation({required this.params});
  final Map<String, String> params;
}

class EpicAppActivation extends EpicProtocolActivation {
  const EpicAppActivation({
    required this.appName,
    required this.namespace,
    required this.itemId,
    required this.action,
    required super.params,
  });

  final String appName;
  final String? namespace;
  final String? itemId;
  final String? action;

  bool get isLaunch => action == 'launch';
  bool get isInstall => action == 'install';
  bool get isUninstall => action == 'uninstall';
  bool get isUpdate => action == 'update';
  bool get silent => params['silent']?.toLowerCase() == 'true';
}

class EpicStoreActivation extends EpicProtocolActivation {
  const EpicStoreActivation({
    required this.section,
    required this.detail,
    required this.sessionInvalidated,
    required super.params,
  });

  /// E.g. `home`, `library`, `wishlist`, `p` (product detail page).
  final String section;

  /// For `store/p/<slug>`, the product slug.
  final String? detail;

  /// True when the launcher signalled that the previous auth session expired.
  final bool sessionInvalidated;

  bool get isProductPage => section == 'p' && detail != null;
}

class EpicUnknownActivation extends EpicProtocolActivation {
  const EpicUnknownActivation({required this.uri, required super.params});
  final Uri uri;
}
