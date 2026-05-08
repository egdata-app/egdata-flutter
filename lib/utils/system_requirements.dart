import '../models/api/offer.dart';

/// Parsed system-requirements view of an [Offer]'s `customAttributes`.
///
/// Epic stores requirements under heterogeneous keys depending on the title
/// (`requirementsMin`, `MinimumOS`, `WindowsMinimumCPU`, …). We bucket every
/// recognised key into [minimum]/[recommended] and expose a human-friendly
/// label so UIs can render a simple two-column table without re-deriving the
/// classification themselves.
class SystemRequirements {
  final List<RequirementRow> minimum;
  final List<RequirementRow> recommended;

  const SystemRequirements({
    required this.minimum,
    required this.recommended,
  });

  bool get isEmpty => minimum.isEmpty && recommended.isEmpty;
  bool get isNotEmpty => !isEmpty;

  static SystemRequirements parse(Map<String, CustomAttribute> attributes) {
    final minimum = <RequirementRow>[];
    final recommended = <RequirementRow>[];

    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value.value.trim();
      if (value.isEmpty) continue;

      final lower = key.toLowerCase();
      final isMin = lower.contains('min');
      final isRec = lower.contains('rec');
      if (!isMin && !isRec) continue;

      // Skip catch-all blobs that pack everything into a single HTML payload —
      // we only want the per-spec keys to keep the table readable.
      if (lower == 'requirementsmin' || lower == 'requirementsrecommended') {
        continue;
      }

      final spec = _classifySpec(lower);
      if (spec == null) continue;

      final row = RequirementRow(label: spec, value: value);
      if (isMin) {
        minimum.add(row);
      } else {
        recommended.add(row);
      }
    }

    minimum.sort((a, b) => _specOrder(a.label).compareTo(_specOrder(b.label)));
    recommended.sort(
      (a, b) => _specOrder(a.label).compareTo(_specOrder(b.label)),
    );

    return SystemRequirements(minimum: minimum, recommended: recommended);
  }

  static String? _classifySpec(String lowerKey) {
    if (lowerKey.contains('os')) return 'OS';
    if (lowerKey.contains('cpu') || lowerKey.contains('processor')) {
      return 'Processor';
    }
    if (lowerKey.contains('memory') || lowerKey.contains('ram')) {
      return 'Memory';
    }
    if (lowerKey.contains('gpu') ||
        lowerKey.contains('graphics') ||
        lowerKey.contains('video')) {
      return 'Graphics';
    }
    if (lowerKey.contains('storage') ||
        lowerKey.contains('disk') ||
        lowerKey.contains('hdd') ||
        lowerKey.contains('ssd')) {
      return 'Storage';
    }
    if (lowerKey.contains('directx')) return 'DirectX';
    if (lowerKey.contains('network')) return 'Network';
    if (lowerKey.contains('sound') || lowerKey.contains('audio')) {
      return 'Sound';
    }
    return null;
  }

  static int _specOrder(String label) {
    const order = [
      'OS',
      'Processor',
      'Memory',
      'Graphics',
      'DirectX',
      'Storage',
      'Sound',
      'Network',
    ];
    final idx = order.indexOf(label);
    return idx == -1 ? order.length : idx;
  }
}

class RequirementRow {
  final String label;
  final String value;
  const RequirementRow({required this.label, required this.value});
}
