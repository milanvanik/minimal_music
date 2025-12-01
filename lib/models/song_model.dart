import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class Song {
  final String title;
  final String artist;
  final Duration duration;
  final String path;
  final Uint8List? albumArt;
  final String? albumArtPath;
  final DateTime modified;
  final String? lyrics;

  Song({
    required this.title,
    required this.artist,
    required this.duration,
    required this.path,
    required this.modified,
    this.albumArt,
    this.albumArtPath,
    this.lyrics,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'duration': duration.inMilliseconds,
    'path': path,
    'albumArtPath': albumArtPath,
    'modified': modified.millisecondsSinceEpoch,
    'lyrics': lyrics,
  };

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] as String,
      artist: json['artist'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      path: json['path'] as String,
      modified: DateTime.fromMillisecondsSinceEpoch(
        json['modified'] as int? ?? 0,
      ),
      albumArt: null,
      albumArtPath: json['albumArtPath'] as String?,
      lyrics: json['lyrics'] as String?,
    );
  }

  static Future<Song?> fromFilePath(String path) async {
    try {
      final metadata = await MetadataRetriever.fromFile(File(path));
      final stat = await File(path).stat();

      return Song(
        title: metadata.trackName ?? File(path).uri.pathSegments.last,
        artist: metadata.trackArtistNames?.join(", ") ?? "Unknown Artist",
        duration: metadata.trackDuration != null
            ? Duration(milliseconds: metadata.trackDuration!)
            : Duration.zero,
        path: path,
        modified: stat.modified,
        albumArt: null,
        albumArtPath: null,
        lyrics: null,
      );
    } catch (e) {
      print("❌ Metadata read failed for $path: $e");
      return null;
    }
  }
}
