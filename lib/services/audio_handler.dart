import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class AudioHandler {
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

  Future<List<Song>> fetchAllAudioFiles({Function(int)? onProgress}) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSongs');

      final List<Song> songs = [];
      int count = 0;

      for (var songData in result) {
        final path = songData['path'] as String? ?? '';
        if (path.isEmpty) continue;

        // Eagerly extract art
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

        count++;
        if (onProgress != null && count % 5 == 0) {
          onProgress(count);
        }
      }

      // Final update
      if (onProgress != null) onProgress(count);

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

  Future<bool> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print("❌ Error deleting file: $e");
    }
    return false;
  }
}
