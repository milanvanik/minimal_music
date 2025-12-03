import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class PlaybackProvider extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
  );
  List<Song> _playlist = [];

  int get currentIndex => player.currentIndex ?? -1;

  List<Song> get playlist => _playlist;

  Song? get currentSong =>
      (currentIndex >= 0 && currentIndex < _playlist.length)
      ? _playlist[currentIndex]
      : null;

  bool get isActuallyPlaying {
    return player.playing &&
        player.processingState != ProcessingState.completed;
  }

  PlaybackProvider() {
    player.currentIndexStream.listen((index) {
      if (index != null) {
        _saveLastPlayedIndex(index);
        notifyListeners();
      }
    });

    player.playerStateStream.listen((state) {
      notifyListeners();
    });

    player.shuffleModeEnabledStream.listen((enabled) {
      notifyListeners();
    });

    player.loopModeStream.listen((mode) {
      notifyListeners();
    });
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        notifyListeners();
      }
    });

    _loadLastState();
  }

  Future<void> _saveLastPlayedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_played_index', index);
  }

  Future<void> setPlaylist(
    List<Song> songs,
    int startIndex, {
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) return;

    if (currentSong != null && currentSong!.path == songs[startIndex].path) {
      if (!player.playing && autoPlay) {
        player.play();
      }
      return;
    }

    _playlist = songs;

    final audioSources = songs.map((song) {
      return AudioSource.file(
        song.path,
        tag: MediaItem(
          id: song.path,
          album: "Local Music",
          title: song.title,
          artist: song.artist,
          artUri: song.albumArtPath != null
              ? Uri.file(song.albumArtPath!)
              : null,
        ),
      );
    }).toList();

    final playlistSource = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: audioSources,
    );

    try {
      await player.setAudioSource(
        playlistSource,
        initialIndex: startIndex.clamp(0, songs.length - 1),
      );

      if (autoPlay) {
        await player.play();
      }

      _savePlaylist(songs);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error setting playlist: $e");
    }
  }

  Future<void> _savePlaylist(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = songs
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    await prefs.setStringList('last_playlist', encoded);
  }

  Future<void> _loadLastState() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String>? encoded = prefs.getStringList('last_playlist');
    if (encoded == null || encoded.isEmpty) return;

    try {
      final List<Song> songs = encoded
          .map((s) => Song.fromJson(jsonDecode(s)))
          .toList();
      _playlist = songs;

      final int lastIndex = prefs.getInt('last_played_index') ?? 0;

      await setPlaylist(songs, lastIndex, autoPlay: false);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error loading last state: $e");
    }
  }

  void play() async {
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero, index: 0);
    }
    player.play();
    notifyListeners();
  }

  void pause() {
    player.pause();
    notifyListeners();
  }

  void skipToNext() {
    if (player.hasNext) {
      player.seekToNext();
    }
  }

  void skipToPrevious() {
    if (player.hasPrevious) {
      player.seekToPrevious();
    }
  }

  void seekToindex(int index) {
    if (index >= 0 && index < _playlist.length) {
      player.seek(Duration.zero, index: index);
    }
  }

  Future<void> toggleShuffle() async {
    final enable = !player.shuffleModeEnabled;
    if (enable) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(enable);
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    final current = player.loopMode;
    final next = current == LoopMode.off
        ? LoopMode.all
        : current == LoopMode.all
        ? LoopMode.one
        : LoopMode.off;
    await player.setLoopMode(next);
    notifyListeners();
  }

  Uint8List? get currentAlbumArt => currentSong?.albumArt;

  bool _showLyrics = false;
  bool get showLyrics => _showLyrics;

  void toggleLyrics() {
    _showLyrics = !_showLyrics;
    notifyListeners();
  }
}
