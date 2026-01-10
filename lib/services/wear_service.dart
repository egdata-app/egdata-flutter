import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';

/// Service for detecting and communicating with Wear OS devices.
/// Only functional on Android.
class WearService {
  static const _channel = MethodChannel('com.ignacioaldama.egdata/wear');

  /// Check if wear functionality is available (Android only)
  bool get isAvailable => Platform.isAndroid;

  /// Get list of connected Wear OS devices.
  Future<List<WearDevice>> getConnectedDevices() async {
    if (!isAvailable) return [];

    try {
      final result = await _channel.invokeMethod<List>('getConnectedDevices');
      if (result == null) return [];

      return result.map((device) {
        final map = Map<String, dynamic>.from(device as Map);
        return WearDevice(
          id: map['id'] as String,
          displayName: map['displayName'] as String,
          isNearby: map['isNearby'] as bool,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get list of device IDs that have the EGData wear app installed.
  Future<List<String>> getDevicesWithAppInstalled() async {
    if (!isAvailable) return [];

    try {
      final result = await _channel.invokeMethod<List>('getDevicesWithApp');
      if (result == null) return [];
      return result.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Check if any connected device needs the wear app installed.
  /// Returns list of devices that don't have the app.
  Future<List<WearDevice>> getDevicesNeedingApp() async {
    if (!isAvailable) return [];

    final connectedDevices = await getConnectedDevices();
    if (connectedDevices.isEmpty) return [];

    final devicesWithApp = await getDevicesWithAppInstalled();
    final devicesWithAppSet = devicesWithApp.toSet();

    return connectedDevices
        .where((device) => !devicesWithAppSet.contains(device.id))
        .toList();
  }

  /// Open Play Store on the specified watch to install the app.
  Future<bool> openPlayStoreOnWatch(String nodeId) async {
    developer.log('openPlayStoreOnWatch called with nodeId: $nodeId', name: 'WearService');
    if (!isAvailable) {
      developer.log('Wear not available (not Android)', name: 'WearService');
      return false;
    }

    try {
      developer.log('Invoking openPlayStoreOnWatch method channel', name: 'WearService');
      final result = await _channel.invokeMethod<bool>(
        'openPlayStoreOnWatch',
        {'nodeId': nodeId},
      );
      developer.log('openPlayStoreOnWatch result: $result', name: 'WearService');
      return result ?? false;
    } catch (e) {
      developer.log('openPlayStoreOnWatch error: $e', name: 'WearService');
      return false;
    }
  }

  /// Trigger a tile refresh on all connected watches.
  Future<bool> triggerTileRefresh() async {
    if (!isAvailable) return false;

    try {
      final result = await _channel.invokeMethod<bool>('triggerTileRefresh');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// Represents a connected Wear OS device.
class WearDevice {
  final String id;
  final String displayName;
  final bool isNearby;

  const WearDevice({
    required this.id,
    required this.displayName,
    required this.isNearby,
  });

  @override
  String toString() => 'WearDevice(id: $id, displayName: $displayName, isNearby: $isNearby)';
}
