import 'package:freezed_annotation/freezed_annotation.dart';

part 'server.freezed.dart';
part 'server.g.dart';

/// A Misskey instance the user has at least one account on, plus its meta.
///
/// Forks (Sharkey, Firefish, etc.) populate `softwareName`/`softwareVersion`
/// differently — keep both fields raw and let capability-detect logic in the
/// HTTP layer decide what's safe to call.
@freezed
class Server with _$Server {
  const factory Server({
    required String host,
    String? name,
    String? description,
    String? softwareName,
    String? softwareVersion,
    String? iconUrl,
    String? bannerUrl,
    DateTime? metaFetchedAt,
  }) = _Server;

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
}
