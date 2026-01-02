import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_tags tool
Tool createGetTagsTool(ApiService apiService) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_tags',
    description:
        'Get all available tags/labels for games. Returns tag data including IDs for search_offers. '
        'Each tag has: id (numeric ID), name (display name), groupName (category), referenceCount (popularity). '
        'CRITICAL: Use the "id" field (NOT name) from returned tags when calling search_offers with tags parameter.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'groupName': <String, dynamic>{
          'type': 'string',
          'description':
              'Optional: Filter by group name (e.g., "genre", "feature", "event"). Leave empty to get all tags.',
        },
        'searchTerm': <String, dynamic>{
          'type': 'string',
          'description':
              'Optional: Search for tags containing this term (e.g., "city", "builder", "steampunk"). Case-insensitive partial match.',
        },
      },
    },
    func: (toolInput) async => await getTags(apiService, toolInput),
  );
}

/// Implement get_tags
Future<Map<String, dynamic>> getTags(
  ApiService apiService,
  Map<String, dynamic> args,
) async {
  try {
    final groupNameFilter = args['groupName'] as String?;
    final searchTerm = args['searchTerm'] as String?;

    final allTags = await apiService.getTags();

    // Filter by groupName if specified
    var filteredTags = allTags;
    if (groupNameFilter != null && groupNameFilter.isNotEmpty) {
      filteredTags = allTags
          .where((tag) => tag['groupName'] == groupNameFilter)
          .toList();
    }

    // Filter by searchTerm if specified (case-insensitive partial match)
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final searchLower = searchTerm.toLowerCase();
      filteredTags = filteredTags.where((tag) {
        final name = (tag['name'] as String?)?.toLowerCase() ?? '';
        final aliases = tag['aliases'] as List?;
        final aliasesMatch = aliases?.any((alias) =>
                alias.toString().toLowerCase().contains(searchLower)) ??
            false;
        return name.contains(searchLower) || aliasesMatch;
      }).toList();
    }

    // Sort by reference count (most popular first)
    filteredTags.sort((a, b) {
      final countA = (a['referenceCount'] as num?) ?? 0;
      final countB = (b['referenceCount'] as num?) ?? 0;
      return countB.compareTo(countA);
    });

    // Group tags by groupName for easier browsing
    final groupedTags = <String, List<Map<String, dynamic>>>{};
    for (final tag in filteredTags) {
      final groupName = (tag['groupName'] as String?) ?? 'other';
      groupedTags.putIfAbsent(groupName, () => []);
      groupedTags[groupName]!.add({
        'id': tag['id'],
        'name': tag['name'],
        'groupName': groupName,
        'referenceCount': tag['referenceCount'],
        'aliases': tag['aliases'],
      });
    }

    // Create a simplified list for the AI
    final simplifiedTags = filteredTags.map((tag) {
      return {
        'id': tag['id'],
        'name': tag['name'],
        'groupName': tag['groupName'],
        'referenceCount': tag['referenceCount'],
        'aliases': tag['aliases'],
      };
    }).toList();

    return {
      'tags': simplifiedTags,
      'groupedTags': groupedTags,
      'count': filteredTags.length,
      'availableGroups': groupedTags.keys.toList(),
    };
  } catch (e) {
    return {
      'error': e.toString(),
      'tags': [],
      'count': 0,
    };
  }
}
