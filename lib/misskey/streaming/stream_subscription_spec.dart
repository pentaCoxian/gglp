/// A logical subscription to a Misskey streaming channel.
///
/// `localId` is what we use internally to correlate inbound `channel`
/// frames back to a subscription; we generate it (don't reuse the
/// channel name) so the same channel can be subscribed multiple times
/// with different params.
class StreamSubscriptionSpec {
  final String localId;
  final String channel;
  final Map<String, dynamic> params;

  const StreamSubscriptionSpec({
    required this.localId,
    required this.channel,
    this.params = const {},
  });

  Map<String, dynamic> toConnectFrame() => {
        'type': 'connect',
        'body': {
          'channel': channel,
          'id': localId,
          if (params.isNotEmpty) 'params': params,
        },
      };

  Map<String, dynamic> toDisconnectFrame() => {
        'type': 'disconnect',
        'body': {'id': localId},
      };
}

/// Convenience builders for the channels we support today.
class MisskeyChannels {
  static const homeTimeline = 'homeTimeline';
  static const localTimeline = 'localTimeline';
  static const hybridTimeline = 'hybridTimeline';
  static const globalTimeline = 'globalTimeline';

  /// `channel` requires `params: {'channelId': '...'}` at subscribe
  /// time. Used for custom timelines that include a channel source.
  static const channel = 'channel';

  /// `antenna` requires `params: {'antennaId': '...'}` at subscribe
  /// time. Used for the stand-alone antenna viewer + custom timelines
  /// that include an antenna source.
  static const antenna = 'antenna';

  static const main = 'main';
}
