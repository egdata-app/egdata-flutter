#!/bin/bash
# Script to run all shutdown-related tests

echo "Running shutdown tests..."
flutter test test/services/app_shell_shutdown_test.dart test/services/app_shell_shutdown_simple_test.dart test/services/shutdown_performance_test.dart test/services/window_hiding_test.dart

echo "Shutdown tests completed!"