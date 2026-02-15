import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsWindowStyleService {
  static bool makeActiveWindowBorderless() {
    if (!Platform.isWindows) {
      return false;
    }

    final hwnd = GetForegroundWindow();
    if (hwnd == 0) {
      return false;
    }

    if (!_belongsToCurrentProcess(hwnd)) {
      return false;
    }

    _applyBorderlessStyle(hwnd);
    return true;
  }

  static void makeBorderlessToolWindow(String title) {
    if (!Platform.isWindows) {
      return;
    }

    final titlePtr = title.toNativeUtf16();
    try {
      final hwnd = FindWindow(nullptr, titlePtr);
      if (hwnd == 0) {
        return;
      }

      _applyBorderlessStyle(hwnd);
    } finally {
      calloc.free(titlePtr);
    }
  }

  static bool _belongsToCurrentProcess(int hwnd) {
    final pidPtr = calloc<Uint32>();
    try {
      GetWindowThreadProcessId(hwnd, pidPtr);
      return pidPtr.value == GetCurrentProcessId();
    } finally {
      calloc.free(pidPtr);
    }
  }

  static void _applyBorderlessStyle(int hwnd) {
    var style = GetWindowLongPtr(hwnd, GWL_STYLE);
    style &= ~WS_OVERLAPPEDWINDOW;
    style |= WS_POPUP;
    style |= WS_VISIBLE;
    SetWindowLongPtr(hwnd, GWL_STYLE, style);

    var exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    exStyle |= WS_EX_TOOLWINDOW;
    exStyle &= ~WS_EX_APPWINDOW;
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);

    SetWindowPos(
      hwnd,
      NULL,
      0,
      0,
      0,
      0,
      SWP_NOMOVE |
          SWP_NOSIZE |
          SWP_NOZORDER |
          SWP_NOACTIVATE |
          SWP_FRAMECHANGED,
    );
  }
}
