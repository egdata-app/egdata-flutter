import 'package:egdata_flutter/models/api/offer.dart';
import 'package:egdata_flutter/utils/system_requirements.dart';
import 'package:flutter_test/flutter_test.dart';

CustomAttribute _attr(String value) =>
    CustomAttribute(type: 'STRING', value: value);

void main() {
  group('SystemRequirements.parse', () {
    test('returns empty when no requirement-shaped keys are present', () {
      final reqs = SystemRequirements.parse({
        'somethingElse': _attr('ignore me'),
      });
      expect(reqs.isEmpty, isTrue);
      expect(reqs.minimum, isEmpty);
      expect(reqs.recommended, isEmpty);
    });

    test('classifies per-OS specs into minimum and recommended buckets', () {
      final reqs = SystemRequirements.parse({
        'WindowsMinimumOS': _attr('Windows 10 64-bit'),
        'WindowsMinimumCPU': _attr('Intel i5-2500K'),
        'WindowsRecommendedOS': _attr('Windows 11 64-bit'),
        'WindowsRecommendedRAM': _attr('16 GB'),
      });

      expect(reqs.minimum.length, 2);
      expect(reqs.recommended.length, 2);
      expect(
        reqs.minimum.map((r) => r.label).toList(),
        // OS sorts before Processor.
        ['OS', 'Processor'],
      );
      expect(reqs.recommended.first.label, 'OS');
    });

    test('skips empty values and unrecognised spec keys', () {
      final reqs = SystemRequirements.parse({
        'MinimumOS': _attr(''),
        'MinimumLanguage': _attr('English'),
        'MinimumCPU': _attr('Quad-core'),
      });

      expect(reqs.minimum.length, 1);
      expect(reqs.minimum.first.label, 'Processor');
    });

    test('skips the catch-all requirementsMin/Recommended HTML blobs', () {
      final reqs = SystemRequirements.parse({
        'requirementsMin': _attr('<p>min spec html</p>'),
        'requirementsRecommended': _attr('<p>rec spec html</p>'),
      });

      expect(reqs.isEmpty, isTrue);
    });
  });
}
