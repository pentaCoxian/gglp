import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_channel.freezed.dart';
part 'note_channel.g.dart';

/// Misskey channel that a note belongs to.
///
/// Channels are server-side topic groups; notes posted into a channel
/// only show up in its dedicated timeline (not home/local) unless the
/// channel is configured to fan out. We surface the channel name +
/// color as a chip on the note card so the user can see at a glance
/// which channel the note came from.
@freezed
class NoteChannel with _$NoteChannel {
  const factory NoteChannel({
    required String id,
    required String name,

    /// Hex `#rrggbb` colour the channel publishes for itself; null when
    /// the server didn't pick one. We treat null as "use the default
    /// theme accent" at render time.
    String? color,
    @Default(false) bool isSensitive,
  }) = _NoteChannel;

  factory NoteChannel.fromJson(Map<String, dynamic> json) =>
      _$NoteChannelFromJson(json);
}
