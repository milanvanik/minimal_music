import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class AudioService {
  static const _channel = MethodChannel('music_scanner');

  String generateHash(Song s) {
    final data = [
      s.title,
      s.artist,
      s.duration.inMilliseconds,
      s.path,
      s.modified.millisecondsSinceEpoch,
    ].join("|");

    return data.hashCode.toString();
  }

  String hashPlaylist(List<Song> list) {
    final hashes = list.map((s) => generateHash(s)).toList()..sort();
    return hashes.join("-");
  }

  Future<File> getArtCacheFile(String songPath) async {
    final cacheDir = await getTemporaryDirectory();
    final fileName = "art_${songPath.hashCode}.jpg";
    return File("${cacheDir.path}/$fileName");
  }

  Future<String?> extractAndSaveArt(String songPath) async {
    try {
      final file = await getArtCacheFile(songPath);
      if (await file.exists()) {
        return file.path;
      }

      final metadata = await MetadataRetriever.fromFile(File(songPath));
      final artBytes = metadata.albumArt;

      if (artBytes != null && artBytes.isNotEmpty) {
        await file.writeAsBytes(artBytes, flush: true);
        return file.path;
      }
    } catch (e) {
      print("⚠️ Art extraction failed for $songPath: $e");
    }
    return null;
  }

  Future<List<Song>> fetchAllAudioFiles() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSongs');

      final List<Song> songs = [];

      for (var songData in result) {
        final path = songData['path'] as String? ?? '';
        if (path.isEmpty) continue;

        final artFile = await getArtCacheFile(path);
        String? artPath;
        if (await artFile.exists()) {
          artPath = artFile.path;
        } else {
          artPath = await extractAndSaveArt(path);
        }

        songs.add(
          Song(
            title: songData['title'] ?? 'Unknown Title',
            artist: songData['artist'] ?? 'Unknown Artist',
            duration: Duration(
              milliseconds: (songData['duration'] ?? 0).toInt(),
            ),
            path: path,
            albumArt: null,
            albumArtPath: artPath,
            lyrics: null,
            modified: DateTime.fromMillisecondsSinceEpoch(
              (songData['dateModified'] ?? 0).toInt() * 1000,
            ),
          ),
        );
      }

      return songs;
    } catch (e) {
      print("❌ fetchAllAudioFiles: $e");
      return [];
    }
  }

  Map<String, dynamic> comparePlaylists(
    List<Song> oldList,
    List<Song> newList,
  ) {
    final oldHash = hashPlaylist(oldList);
    final newHash = hashPlaylist(newList);

    bool changed = oldHash != newHash;

    final oldPaths = oldList.map((e) => e.path).toSet();
    final newPaths = newList.map((e) => e.path).toSet();

    final newSongs = newPaths.difference(oldPaths).length;

    return {"changed": changed, "newSongs": newSongs};
  }

  Future<void> saveLyrics(String songPath, String lyrics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lyrics_${songPath.hashCode}', lyrics);
  }

  Future<String?> getLyrics(String songPath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lyrics_${songPath.hashCode}');
  }
}
