import '../misskey/streaming/stream_subscription_spec.dart';
import 'timeline_kind.dart';

/// One feed inside a custom-unified timeline: which account, which
/// kind, and (for `kind == channel`) which channel id.
///
/// `accountId` is the persistent `Account.id` ("host:userId") rather
/// than a live Account reference so saved custom timelines survive
/// account-list reordering.
class TimelineSource {
  final String accountId;
  final TimelineSourceKind kind;

  /// Required when `kind == TimelineSourceKind.channel`, ignored
  /// otherwise. The Misskey channel id is account-local (issued by the
  /// account's home server), so a channel source is implicitly tied to
  /// that one account.
  final String? channelId;

  /// Required when `kind == TimelineSourceKind.antenna`. Account-local.
  final String? antennaId;

  const TimelineSource({
    required this.accountId,
    required this.kind,
    this.channelId,
    this.antennaId,
  });

  /// Convert to the streaming-channel + params pair to subscribe with.
  /// Channels need an extra `channelId` param at subscribe time.
  ({String channel, Map<String, dynamic> params}) toStreamSpec() {
    switch (kind) {
      case TimelineSourceKind.home:
        return (channel: MisskeyChannels.homeTimeline, params: const {});
      case TimelineSourceKind.local:
        return (channel: MisskeyChannels.localTimeline, params: const {});
      case TimelineSourceKind.hybrid:
        return (channel: MisskeyChannels.hybridTimeline, params: const {});
      case TimelineSourceKind.global:
        return (channel: MisskeyChannels.globalTimeline, params: const {});
      case TimelineSourceKind.channel:
        return (
          channel: MisskeyChannels.channel,
          params: {'channelId': channelId ?? ''},
        );
      case TimelineSourceKind.antenna:
        return (
          channel: MisskeyChannels.antenna,
          params: {'antennaId': antennaId ?? ''},
        );
    }
  }

  /// Stable identity of this source for use in Riverpod family keys
  /// and reconcile sets — survives JSON round-trips.
  String get fingerprint {
    final extra = switch (kind) {
      TimelineSourceKind.channel =>
        channelId == null ? '' : ':$channelId',
      TimelineSourceKind.antenna =>
        antennaId == null ? '' : ':$antennaId',
      _ => '',
    };
    return 'src:$accountId:${kind.name}$extra';
  }

  @override
  bool operator ==(Object other) =>
      other is TimelineSource &&
      other.accountId == accountId &&
      other.kind == kind &&
      other.channelId == channelId &&
      other.antennaId == antennaId;

  @override
  int get hashCode =>
      Object.hash(accountId, kind, channelId, antennaId);

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'kind': kind.name,
        if (channelId != null) 'channelId': channelId,
        if (antennaId != null) 'antennaId': antennaId,
      };

  factory TimelineSource.fromJson(Map<String, dynamic> j) {
    return TimelineSource(
      accountId: j['accountId'] as String,
      kind: TimelineSourceKind.values.firstWhere(
        (k) => k.name == j['kind'],
        orElse: () => TimelineSourceKind.home,
      ),
      channelId: j['channelId'] as String?,
      antennaId: j['antennaId'] as String?,
    );
  }
}

/// Kinds available as a source in a custom-unified timeline.
///
/// Mirrors [TimelineKind] plus `channel`. Two enums avoids leaking
/// channel into per-account timelines (which don't pick a channel id).
enum TimelineSourceKind {
  home,
  local,
  hybrid,
  global,
  channel,
  antenna;

  /// Map back to the per-account [TimelineKind] when applicable.
  /// Returns null for kinds that don't have a basic per-account
  /// timeline representation (channel, antenna).
  TimelineKind? toBasicKind() {
    switch (this) {
      case TimelineSourceKind.home:
        return TimelineKind.home;
      case TimelineSourceKind.local:
        return TimelineKind.local;
      case TimelineSourceKind.hybrid:
        return TimelineKind.hybrid;
      case TimelineSourceKind.global:
        return TimelineKind.global;
      case TimelineSourceKind.channel:
      case TimelineSourceKind.antenna:
        return null;
    }
  }
}
