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

  // Favorites
  Set<String> _favorites = {};
  bool _showFavoritesOnly = false;

  // Filtering
  bool _filterShortSongs = true;
  Set<String> _excludedFolders = {};
  Set<String> _manualFolders = {}; // User-added paths
  List<Song> _allSongs = []; // Store all songs to derive folders

  List<Song> get songs {
    if (_showFavoritesOnly) {
      return _songs.where((s) => _favorites.contains(s.path)).toList();
    }
    return _songs;
  }

  bool get isInitializing => _isInitializing;
  SortOption get sortOption => _sortOption;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get filterShortSongs => _filterShortSongs;
  Set<String> get excludedFolders => _excludedFolders;

  // Combined list for UI: Detected + Excluded + Manual
  Map<String, int> get managedFolders {
    final folders = <String, int>{};

    // 1. Add detected folders
    for (var song in _allSongs) {
      final folder = song.path.substring(0, song.path.lastIndexOf('/'));
      folders[folder] = (folders[folder] ?? 0) + 1;
    }

    // 2. Add excluded folders (if not already present)
    for (var folder in _excludedFolders) {
      if (!folders.containsKey(folder)) {
        folders[folder] = 0;
      }
    }

    // 3. Add manual folders (if not already present)
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
    // Request permission FIRST
    await _requestStoragePermission();

    // Load songs (will only scan if permission granted)
    await loadSongs(fromUser: false);

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> checkPermission() async {
    bool granted = false;

    // Android 13+
    if (await Permission.audio.isGranted) {
      granted = true;
    }
    // Android 12 and below
    else if (await Permission.storage.isGranted) {
      granted = true;
    }
    // Manage External Storage
    else if (await Permission.manageExternalStorage.isGranted) {
      granted = true;
    }

    _hasPermission = granted;
    notifyListeners();
  }

  Future<bool> _requestStoragePermission() async {
    // Check if already granted
    await checkPermission();
    if (_hasPermission) return true;

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    // Check results
    if (statuses[Permission.audio]?.isGranted == true ||
        statuses[Permission.storage]?.isGranted == true) {
      _hasPermission = true;
      return true;
    }

    // Check if Manage External Storage is ALREADY granted (don't request it automatically)
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
        _songs.sort((a, b) => b.modified.compareTo(a.modified)); // Newest first
        break;
      case SortOption.title:
        _songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.artist:
        _songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
    }
  }

  // Favorites Logic
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

  // Filtering Logic
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

    // 1. Filter excluded folders
    if (_excludedFolders.isNotEmpty) {
      filtered = filtered.where((s) {
        final folder = s.path.substring(0, s.path.lastIndexOf('/'));
        return !_excludedFolders.contains(folder);
      }).toList();
    }

    // 2. Filter short songs
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

    // Load favorites
    final favList = prefs.getStringList('favorite_songs') ?? [];
    _favorites = favList.toSet();

    // Load filter preference
    _filterShortSongs = prefs.getBool('filter_short_songs') ?? true;

    // Load excluded folders
    final excludedList = prefs.getStringList('excluded_folders') ?? [];
    _excludedFolders = excludedList.toSet();

    // Load manual folders
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

    // Update permission status before deciding to scan
    await checkPermission();

    // Only scan if we have permission OR if user explicitly requested (and we have permission)
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

      // Also remove from favorites if present
      if (_favorites.contains(song.path)) {
        toggleFavorite(song.path);
      }

      notifyListeners();
      return true;
    }
    return false;
  }
}
