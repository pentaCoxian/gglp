/// Normalized Misskey host. Strips schemes, slashes, and the optional
/// leading `@` from things like `@user@instance.example`.
class MisskeyHost {
  final String value;
  const MisskeyHost._(this.value);

  factory MisskeyHost.parse(String input) {
    var s = input.trim();
    // Strip an optional `@` prefix from a `user@host` paste.
    if (s.contains('@')) s = s.split('@').last;
    // Strip scheme + path.
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    s = s.split('/').first;
    s = s.toLowerCase();
    if (s.isEmpty) {
      throw const FormatException('Empty host');
    }
    final hostPattern = RegExp(r'^[a-z0-9.\-]+(:\d+)?$');
    if (!hostPattern.hasMatch(s)) {
      throw FormatException('Invalid host: $s');
    }
    return MisskeyHost._(s);
  }

  Uri uri(String path, [Map<String, dynamic>? query]) =>
      Uri.https(value, path, query?.map((k, v) => MapEntry(k, '$v')));

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is MisskeyHost && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
