import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';

enum SortOption { dateAdded, title, artist }

class SongProvider extends ChangeNotifier {
  final AudioHandler _audioHandler = AudioHandler();
  List<Song> _songs = [];
  bool _isInitializing = true;
  SortOption _sortOption = SortOption.dateAdded;

  Set<String> _favorites = {};
  bool _showFavoritesOnly = false;

  bool _filterShortSongs = true;
  Set<String> _excludedFolders = {};
  Set<String> _manualFolders = {};
  List<Song> _allSongs = [];

  bool _selectionMode = false;
  Set<String> _selectedSongs = {};

  List<Song> get songs {
    if (_showFavoritesOnly) {
      return _songs.where((s) => _favorites.contains(s.path)).toList();
    }
    return _songs;
  }

  List<Song> get allSongs => _songs;

  bool get isInitializing => _isInitializing;
  SortOption get sortOption => _sortOption;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get hasFavorites => _favorites.isNotEmpty;
  bool get filterShortSongs => _filterShortSongs;
  Set<String> get excludedFolders => _excludedFolders;

  bool get selectionMode => _selectionMode;
  Set<String> get selectedSongs => _selectedSongs;
  int get selectedCount => _selectedSongs.length;
  bool isSongSelected(String path) => _selectedSongs.contains(path);

  Map<String, int> get managedFolders {
    final folders = <String, int>{};

    for (var song in _allSongs) {
      final folder = song.path.substring(0, song.path.lastIndexOf('/'));
      folders[folder] = (folders[folder] ?? 0) + 1;
    }

    for (var folder in _excludedFolders) {
      if (!folders.containsKey(folder)) {
        folders[folder] = 0;
      }
    }

    for (var folder in _manualFolders) {
      if (!folders.containsKey(folder)) {
        folders[folder] = 0;
      }
    }

    return folders;
  }

  SongProvider() {
    _init();
  }

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  Future<void> _init() async {
    await _requestStoragePermission();

    await loadSongs(fromUser: false);

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> checkPermission() async {
    bool granted = false;

    if (await Permission.audio.isGranted) {
      granted = true;
    } else if (await Permission.storage.isGranted) {
      granted = true;
    } else if (await Permission.manageExternalStorage.isGranted) {
      granted = true;
    }

    _hasPermission = granted;
    notifyListeners();
  }

  Future<bool> _requestStoragePermission() async {
    await checkPermission();
    if (_hasPermission) return true;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    if (statuses[Permission.audio]?.isGranted == true ||
        statuses[Permission.storage]?.isGranted == true) {
      _hasPermission = true;
      return true;
    }

    if (await Permission.manageExternalStorage.isGranted) {
      _hasPermission = true;
      return true;
    }

    _hasPermission = false;
    return false;
  }

  void sortSongs(SortOption option) {
    _sortOption = option;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    switch (_sortOption) {
      case SortOption.dateAdded:
        _songs.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case SortOption.title:
        _songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.artist:
        _songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
    }
  }

  bool isFavorite(String path) => _favorites.contains(path);

  Future<void> toggleFavorite(String path) async {
    if (_favorites.contains(path)) {
      _favorites.remove(path);
    } else {
      _favorites.add(path);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_songs', _favorites.toList());
  }

  void toggleShowFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  void setShowFavoritesOnly(bool show) {
    _showFavoritesOnly = show;
    notifyListeners();
  }

  Future<void> toggleFilterShortSongs() async {
    _filterShortSongs = !_filterShortSongs;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_short_songs', _filterShortSongs);

    _applyFilters();
  }

  bool isFolderVisible(String folder) => !_excludedFolders.contains(folder);

  Future<void> toggleFolderVisibility(String folder) async {
    if (_excludedFolders.contains(folder)) {
      _excludedFolders.remove(folder);
    } else {
      _excludedFolders.add(folder);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('excluded_folders', _excludedFolders.toList());

    _applyFilters();
  }

  Future<void> addManualFolder(String path) async {
    if (path.isEmpty) return;
    _manualFolders.add(path);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('manual_folders', _manualFolders.toList());
  }

  void _applyFilters() {
    var filtered = List<Song>.from(_allSongs);

    if (_excludedFolders.isNotEmpty) {
      filtered = filtered.where((s) {
        final folder = s.path.substring(0, s.path.lastIndexOf('/'));
        return !_excludedFolders.contains(folder);
      }).toList();
    }

    if (_filterShortSongs) {
      filtered = filtered.where((s) => s.duration.inSeconds >= 60).toList();
    }

    _songs = filtered;
    _applySort();
    notifyListeners();
  }

  int _scannedSongsCount = 0;
  int get scannedSongsCount => _scannedSongsCount;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> loadSongs({bool fromUser = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final favList = prefs.getStringList('favorite_songs') ?? [];
    _favorites = favList.toSet();

    _filterShortSongs = prefs.getBool('filter_short_songs') ?? true;

    final excludedList = prefs.getStringList('excluded_folders') ?? [];
    _excludedFolders = excludedList.toSet();

    final manualList = prefs.getStringList('manual_folders') ?? [];
    _manualFolders = manualList.toSet();

    final cachedJson = prefs.getString('cached_songs');
    List<Song> cachedSongs = [];

    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as List;
        final list = decoded.map((e) => Song.fromJson(e)).toList();

        _allSongs = list;
        cachedSongs = list;
        _applyFilters();
      } catch (_) {}
    }

    await checkPermission();

    if (_hasPermission) {
      _isScanning = true;
      _scannedSongsCount = 0;
      notifyListeners();

      try {
        final freshSongs = await _audioHandler.fetchAllAudioFiles(
          onProgress: (count) {
            _scannedSongsCount = count;
            notifyListeners();
          },
        );

        final diff = _audioHandler.comparePlaylists(cachedSongs, freshSongs);

        if (diff["changed"] == true) {
          _allSongs = freshSongs;
          _applyFilters();

          prefs.setString(
            'cached_songs',
            jsonEncode(freshSongs.map((e) => e.toJson()).toList()),
          );
        }
      } finally {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteSong(Song song) async {
    final success = await _audioHandler.deleteAudioFile(song.path);
    if (success) {
      _songs.removeWhere((s) => s.path == song.path);
      _allSongs.removeWhere((s) => s.path == song.path);

      if (_favorites.contains(song.path)) {
        toggleFavorite(song.path);
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  void enterSelectionMode(String songPath) {
    _selectionMode = true;
    _selectedSongs.clear();
    _selectedSongs.add(songPath);
    notifyListeners();
  }

  void exitSelectionMode() {
    _selectionMode = false;
    _selectedSongs.clear();
    notifyListeners();
  }

  void toggleSongSelection(String path) {
    if (_selectedSongs.contains(path)) {
      _selectedSongs.remove(path);
      if (_selectedSongs.isEmpty) {
        _selectionMode = false;
      }
    } else {
      _selectedSongs.add(path);
    }
    notifyListeners();
  }

  void selectAllSongs() {
    _selectedSongs.clear();
    _selectedSongs.addAll(songs.map((s) => s.path));
    notifyListeners();
  }

  Future<int> deleteSelectedSongs() async {
    int deletedCount = 0;
    final pathsToDelete = List<String>.from(_selectedSongs);

    final success = await _audioHandler.deleteAudioFiles(pathsToDelete);

    if (success) {
      for (final path in pathsToDelete) {
        _songs.removeWhere((s) => s.path == path);
        _allSongs.removeWhere((s) => s.path == path);
        _favorites.remove(path);
        deletedCount++;
      }
    }

    exitSelectionMode();
    notifyListeners();
    return deletedCount;
  }
}
