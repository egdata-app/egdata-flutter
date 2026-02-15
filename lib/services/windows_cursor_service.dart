import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsCursorService {
  static ({double x, double y})? getCursorScreenPosition() {
    if (!Platform.isWindows) {
      return null;
    }

    final point = calloc<POINT>();
    try {
      final ok = GetCursorPos(point);
      if (ok == 0) {
        return null;
      }
      return (x: point.ref.x.toDouble(), y: point.ref.y.toDouble());
    } finally {
      calloc.free(point);
    }
  }

  static bool isMouseButtonDown() {
    if (!Platform.isWindows) {
      return false;
    }

    final leftDown = (GetAsyncKeyState(VK_LBUTTON) & 0x8000) != 0;
    final rightDown = (GetAsyncKeyState(VK_RBUTTON) & 0x8000) != 0;
    final middleDown = (GetAsyncKeyState(VK_MBUTTON) & 0x8000) != 0;
    return leftDown || rightDown || middleDown;
  }

  static bool isCursorInsideWindow(String windowTitle) {
    if (!Platform.isWindows) {
      return true;
    }

    final titlePtr = windowTitle.toNativeUtf16();
    final point = calloc<POINT>();
    final rect = calloc<RECT>();
    try {
      final hwnd = FindWindow(nullptr, titlePtr);
      if (hwnd == 0) {
        return false;
      }

      final gotPoint = GetCursorPos(point);
      final gotRect = GetWindowRect(hwnd, rect);
      if (gotPoint == 0 || gotRect == 0) {
        return false;
      }

      return point.ref.x >= rect.ref.left &&
          point.ref.x <= rect.ref.right &&
          point.ref.y >= rect.ref.top &&
          point.ref.y <= rect.ref.bottom;
    } finally {
      calloc.free(titlePtr);
      calloc.free(point);
      calloc.free(rect);
    }
  }
}
