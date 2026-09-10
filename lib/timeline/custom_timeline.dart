import 'dart:convert';

import 'timeline_source.dart';

/// A user-defined unified timeline. Lives in Drift's `custom_timelines`.
///
/// `sources` is the in-memory representation of the JSON-encoded list
/// the table stores in `sourcesJson`. Order is preserved on save —
/// while merge-sort discards source order at render time, the picker
/// for editing keeps it as the user laid it out.
class CustomTimeline {
  final String id;
  final String name;
  final int sortOrder;
  final List<TimelineSource> sources;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomTimeline({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.sources,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomTimeline copyWith({
    String? name,
    int? sortOrder,
    List<TimelineSource>? sources,
    DateTime? updatedAt,
  }) =>
      CustomTimeline(
        id: id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        sources: sources ?? this.sources,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String encodeSources(List<TimelineSource> sources) =>
      jsonEncode(sources.map((s) => s.toJson()).toList());

  static List<TimelineSource> decodeSources(String json) {
    if (json.isEmpty) return const [];
    try {
      return (jsonDecode(json) as List)
          .map((e) => TimelineSource.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
