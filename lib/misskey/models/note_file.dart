import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_file.freezed.dart';
part 'note_file.g.dart';

/// A file attached to a Misskey note.
///
/// Misskey calls these "drive files". The shape mirrors the backend's
/// `DriveFile` entity. We keep it minimal: the timeline only needs URL,
/// MIME, dimensions, and the sensitivity/blurhash bits to render a grid.
@freezed
class NoteFile with _$NoteFile {
  const NoteFile._();

  const factory NoteFile({
    required String id,
    required String type,
    required String url,
    String? thumbnailUrl,
    String? name,
    String? comment,
    String? blurhash,
    @Default(false) bool isSensitive,
    int? width,
    int? height,
  }) = _NoteFile;

  factory NoteFile.fromJson(Map<String, dynamic> json) =>
      _$NoteFileFromJson(json);

  bool get isImage => type.startsWith('image/');
  bool get isVideo => type.startsWith('video/');
  bool get isAudio => type.startsWith('audio/');

  /// Aspect ratio when known; defaults to 1:1 so layout stays stable
  /// while properties are missing.
  double get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return 1.0;
    return w / h;
  }
}
