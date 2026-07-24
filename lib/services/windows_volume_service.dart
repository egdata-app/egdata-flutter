import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';

import '../models/drive_discovery.dart';

abstract class VolumeProvider {
  Future<List<DriveIdentity>> listVolumes();
}

class WindowsVolumeService implements VolumeProvider {
  const WindowsVolumeService();

  @override
  Future<List<DriveIdentity>> listVolumes() async {
    if (!Platform.isWindows) return const [];

    const bufferLength = 512;
    final buffer = wsalloc(bufferLength);
    try {
      final written = GetLogicalDriveStrings(bufferLength, buffer);
      if (written == 0 || written >= bufferLength) return const [];

      final units = buffer.cast<Uint16>().asTypedList(written + 1);
      final roots = <String>[];
      var start = 0;
      for (var index = 0; index < units.length; index++) {
        if (units[index] != 0) continue;
        if (index > start) {
          roots.add(String.fromCharCodes(units.sublist(start, index)));
        }
        start = index + 1;
      }

      return roots.map(_readIdentity).whereType<DriveIdentity>().toList();
    } finally {
      calloc.free(buffer);
    }
  }

  DriveIdentity? _readIdentity(String root) {
    final rootPointer = root.toNativeUtf16();
    final volumeName = wsalloc(MAX_PATH);
    final label = wsalloc(MAX_PATH);
    final fileSystem = wsalloc(MAX_PATH);
    final serial = calloc<DWORD>();
    final maxComponentLength = calloc<DWORD>();
    final fileSystemFlags = calloc<DWORD>();

    try {
      final driveType = GetDriveType(rootPointer);
      if (driveType != DRIVE_FIXED &&
          driveType != DRIVE_REMOVABLE &&
          driveType != DRIVE_REMOTE) {
        return null;
      }

      final hasVolumeName = GetVolumeNameForVolumeMountPoint(
        rootPointer,
        volumeName,
        MAX_PATH,
      );
      final hasInfo = GetVolumeInformation(
        rootPointer,
        label,
        MAX_PATH,
        serial,
        maxComponentLength,
        fileSystemFlags,
        fileSystem,
        MAX_PATH,
      );

      final volumeId = hasVolumeName != 0
          ? volumeName.toDartString().toLowerCase()
          : 'serial:${serial.value.toRadixString(16)}';
      final volumeLabel = hasInfo != 0 ? label.toDartString() : '';

      return DriveIdentity(
        volumeId: volumeId,
        serialNumber: serial.value,
        mountPath: root,
        label: volumeLabel,
        kind: switch (driveType) {
          DRIVE_FIXED => DriveKind.fixed,
          DRIVE_REMOVABLE => DriveKind.removable,
          DRIVE_REMOTE => DriveKind.network,
          _ => DriveKind.other,
        },
      );
    } finally {
      calloc.free(rootPointer);
      calloc.free(volumeName);
      calloc.free(label);
      calloc.free(fileSystem);
      calloc.free(serial);
      calloc.free(maxComponentLength);
      calloc.free(fileSystemFlags);
    }
  }

  static DriveIdentity? findForPath(
    String path,
    Iterable<DriveIdentity> volumes,
  ) {
    final root = p.windows.rootPrefix(path).toLowerCase();
    for (final volume in volumes) {
      if (p.windows.rootPrefix(volume.mountPath).toLowerCase() == root) {
        return volume;
      }
    }
    return null;
  }

  static String? relativePathFor(String path, DriveIdentity? drive) {
    if (drive == null) return null;
    return p.windows.relative(path, from: drive.mountPath);
  }
}
