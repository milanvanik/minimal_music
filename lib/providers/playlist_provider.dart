import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString('playlists');

      if (playlistsJson != null) {
        final decoded = jsonDecode(playlistsJson) as List;
        _playlists = decoded.map((e) => Playlist.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error loading playlists: $e");
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_playlists.map((e) => e.toJson()).toList());
      await prefs.setString('playlists', encoded);
    } catch (e) {
      print("Error saving playlists: $e");
    }
  }

  Playlist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;

    final now = DateTime.now();
    final playlist = Playlist(
      id: now.millisecondsSinceEpoch.toString(),
      name: name.trim(),
      songPaths: [],
      createdAt: now,
      modifiedAt: now,
    );

    _playlists.add(playlist);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    if (newName.trim().isEmpty) return;

    final index = _playlists.indexWhere((p) => p.id == id);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        name: newName.trim(),
        modifiedAt: DateTime.now(),
      );
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songPath) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];

      if (playlist.songPaths.contains(songPath)) return;

      final updatedSongPaths = List<String>.from(playlist.songPaths)
        ..add(songPath);
      _playlists[index] = playlist.copyWith(
        songPaths: updatedSongPaths,
        modifiedAt: DateTime.now(),
      );
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    String songPath,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedSongPaths = List<String>.from(playlist.songPaths)
        ..remove(songPath);

      _playlists[index] = playlist.copyWith(
        songPaths: updatedSongPaths,
        modifiedAt: DateTime.now(),
      );
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> reorderSongs(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedSongPaths = List<String>.from(playlist.songPaths);

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = updatedSongPaths.removeAt(oldIndex);
      updatedSongPaths.insert(newIndex, item);

      _playlists[index] = playlist.copyWith(
        songPaths: updatedSongPaths,
        modifiedAt: DateTime.now(),
      );
      notifyListeners();
      await _savePlaylists();
    }
  }

  bool isSongInPlaylist(String playlistId, String songPath) {
    final playlist = getPlaylistById(playlistId);
    return playlist?.songPaths.contains(songPath) ?? false;
  }

  List<Song> getSongsInPlaylist(String playlistId, List<Song> allSongs) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];

    final songMap = {for (var song in allSongs) song.path: song};

    return playlist.songPaths
        .map((path) => songMap[path])
        .whereType<Song>()
        .toList();
  }
}
