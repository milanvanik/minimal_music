import 'package:flutter/material.dart';
import 'package:music_player_app/ui/widgets/add_to_playlist_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/playback_provider.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/search_delegate.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/bulk_add_to_playlist_dialog.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import 'playlists_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<SongProvider>(
        context,
        listen: false,
      ).loadSongs(fromUser: false);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  void _handleScroll(double dy, double totalHeight) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final fraction = (dy / totalHeight).clamp(0.0, 1.0);
    final targetOffset = fraction * maxScroll;
    _scrollController.jumpTo(targetOffset);
  }

  @override
  Widget build(BuildContext context) {
    final playbackProvider = Provider.of<PlaybackProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);
    final songs = songProvider.songs;
    final currentSong = playbackProvider.currentSong;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: songProvider.selectionMode
          ? null
          : AppBar(
              backgroundColor: Colors.grey[900],
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                songProvider.showFavoritesOnly ? 'Favorites' : 'Your Library',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: SongSearchDelegate(songs, playbackProvider),
                    );
                  },
                ),
                PopupMenuButton<SortOption>(
                  icon: const Icon(Icons.sort_rounded, color: Colors.white),
                  onSelected: (option) {
                    songProvider.sortSongs(option);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: SortOption.dateAdded,
                      child: Text("Date Added (Newest)"),
                    ),
                    const PopupMenuItem(
                      value: SortOption.title,
                      child: Text("Title (A-Z)"),
                    ),
                    const PopupMenuItem(
                      value: SortOption.artist,
                      child: Text("Artist (A-Z)"),
                    ),
                  ],
                ),
              ],
            ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[900],
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Minimal Music",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        "Refresh Library",
                        style: TextStyle(color: Colors.grey),
                      ),
                      subtitle: const Text(
                        "Scan device for new songs",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(context);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const AlertDialog(
                            backgroundColor: Color.fromARGB(255, 201, 201, 201),
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.deepPurpleAccent,
                                ),
                                SizedBox(width: 20),
                                Text(
                                  "Scanning library...",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        );

                        await songProvider.loadSongs(fromUser: true);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "✅ Library refreshed",
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.deepPurpleAccent,
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.home_rounded,
                        color: !songProvider.showFavoritesOnly
                            ? Colors.deepPurpleAccent
                            : Colors.white70,
                      ),
                      title: Text(
                        "Home",
                        style: TextStyle(
                          color: !songProvider.showFavoritesOnly
                              ? Colors.deepPurpleAccent
                              : Colors.white,
                          fontWeight: !songProvider.showFavoritesOnly
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        songProvider.setShowFavoritesOnly(false);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.favorite_rounded,
                        color: songProvider.showFavoritesOnly
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                      title: Text(
                        "Favorites",
                        style: TextStyle(
                          color: songProvider.showFavoritesOnly
                              ? Colors.redAccent
                              : Colors.white,
                          fontWeight: songProvider.showFavoritesOnly
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        songProvider.setShowFavoritesOnly(true);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.playlist_play_rounded,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        "Playlists",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, PlaylistsScreen.route());
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        "Settings",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, SettingsScreen.route());
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        "About",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showAboutDialog(
                          context: context,
                          applicationName: "Minimal Music",
                          applicationVersion: "1.0.0",
                          applicationIcon: const Icon(
                            Icons.music_note_rounded,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                          children: [
                            const Text(
                              "A beautiful, minimal music player built with Flutter.",
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "v1.0.0",
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: songs.isEmpty
                ? Center(
                    child:
                        (songProvider.isInitializing ||
                                songProvider.isScanning) &&
                            !(songProvider.showFavoritesOnly &&
                                !songProvider.hasFavorites)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Found ${songProvider.scannedSongsCount} songs...",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : songProvider.hasPermission
                        ? Text(
                            songProvider.showFavoritesOnly
                                ? 'No favorites yet.\nTry adding some songs.'
                                : 'No songs found on device.\nTry adding some music files.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.folder_off_rounded,
                                size: 64,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Storage Permission Needed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please allow access to scan songs.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  openAppSettings();
                                },
                                icon: const Icon(Icons.settings),
                                label: const Text("Grant Permission"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(
                              top: songProvider.selectionMode
                                  ? MediaQuery.of(context).padding.top + 90
                                  : 0,
                              bottom: songProvider.selectionMode ? 80 : 80,
                            ),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              return AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) =>
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        20 * (1 - _fadeAnimation.value),
                                      ),
                                      child: Opacity(
                                        opacity: _fadeAnimation.value,
                                        child: child,
                                      ),
                                    ),
                                child: SongListTile(
                                  title: song.title,
                                  artist: song.artist,
                                  duration: _formatDuration(song.duration),
                                  albumArt: song.albumArt,
                                  albumArtPath: song.albumArtPath,
                                  selectionMode: songProvider.selectionMode,
                                  isSelected: songProvider.isSongSelected(
                                    song.path,
                                  ),
                                  onTap: () {
                                    if (songProvider.selectionMode) {
                                      songProvider.toggleSongSelection(
                                        song.path,
                                      );
                                    } else {
                                      playbackProvider.setPlaylist(
                                        songs,
                                        index,
                                      );
                                      Navigator.push(
                                        context,
                                        PlayerScreen.route(),
                                      );
                                    }
                                  },
                                  onMenuTap: songProvider.selectionMode
                                      ? null
                                      : () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                AddToPlaylistDialog(
                                                  songPath: song.path,
                                                ),
                                          );
                                        },
                                  onLongPress: () {
                                    if (!songProvider.selectionMode) {
                                      songProvider.enterSelectionMode(
                                        song.path,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 80,
                            width: 30,
                            child: GestureDetector(
                              onVerticalDragUpdate: (details) {
                                _handleScroll(
                                  details.localPosition.dy,
                                  constraints.maxHeight - 80,
                                );
                              },
                              onTapDown: (details) {
                                _handleScroll(
                                  details.localPosition.dy,
                                  constraints.maxHeight - 80,
                                );
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 4,
                                    color: Colors.white12,
                                    margin: const EdgeInsets.only(right: 5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _scrollController,
                            builder: (context, child) {
                              try {
                                if (!_scrollController.hasClients ||
                                    _scrollController
                                            .position
                                            .maxScrollExtent ==
                                        0) {
                                  return const SizedBox.shrink();
                                }
                                final maxScroll =
                                    _scrollController.position.maxScrollExtent;
                                final currentScroll =
                                    _scrollController.position.pixels;
                                final scrollFraction =
                                    (currentScroll / maxScroll).clamp(0.0, 1.0);
                                final availableHeight =
                                    constraints.maxHeight - 80;
                                final thumbOffset =
                                    scrollFraction * (availableHeight - 40);

                                return Positioned(
                                  right: 5,
                                  top: thumbOffset,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: 8,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MiniPlayer(
                  title: currentSong.title,
                  artist: currentSong.artist,
                  albumArt: currentSong.albumArt,
                  albumArtPath: currentSong.albumArtPath,
                  isPlaying: playbackProvider.isActuallyPlaying,
                  heroTag: "current-song-art-${playbackProvider.currentIndex}",
                  onPlayPause: () {
                    if (playbackProvider.isActuallyPlaying) {
                      playbackProvider.pause();
                    } else {
                      playbackProvider.play();
                    }
                  },
                  onNext: playbackProvider.skipToNext,
                  onTap: () {
                    Navigator.push(context, PlayerScreen.route());
                  },
                ),
              ),
            ),
          if (songProvider.selectionMode)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                child: BulkActionBar(
                  selectedCount: songProvider.selectedCount,
                  onAddToPlaylist: () {
                    final selectedPaths = List<String>.from(
                      songProvider.selectedSongs,
                    );
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          BulkAddToPlaylistDialog(songPaths: selectedPaths),
                    ).then((_) {
                      songProvider.exitSelectionMode();
                    });
                  },
                  onDelete: () {
                    final count = songProvider.selectedCount;
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text(
                          'Delete Songs',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Are you sure you want to delete $count song${count > 1 ? 's' : ''} from your device?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              final deletedCount = await songProvider
                                  .deleteSelectedSongs();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Deleted $deletedCount song${deletedCount > 1 ? 's' : ''}',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onSelectAll: () {
                    songProvider.selectAllSongs();
                  },
                  onCancel: () {
                    songProvider.exitSelectionMode();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
