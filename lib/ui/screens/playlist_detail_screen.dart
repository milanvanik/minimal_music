import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/playback_provider.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({Key? key, required this.playlistId})
    : super(key: key);

  static Route route(String playlistId) {
    return MaterialPageRoute(
      builder: (_) => PlaylistDetailScreen(playlistId: playlistId),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Rename Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurpleAccent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Provider.of<PlaylistProvider>(
                  context,
                  listen: false,
                ).renamePlaylist(playlistId, controller.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist renamed'),
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                );
              }
            },
            child: const Text(
              'Rename',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);
    final playbackProvider = Provider.of<PlaybackProvider>(context);

    final playlist = playlistProvider.getPlaylistById(playlistId);

    if (playlist == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final songs = playlistProvider.getSongsInPlaylist(
      playlistId,
      songProvider.allSongs,
    );

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _showRenameDialog(context, playlist.name),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Delete Playlist',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Are you sure you want to delete "${playlist.name}"?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        playlistProvider.deletePlaylist(playlistId);
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Playlist deleted'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
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
          ),
        ],
      ),
      body: Stack(
        children: [
          songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.music_note_rounded,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No songs in this playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add songs using the menu on song tiles',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (songs.isNotEmpty) {
                            playbackProvider.setPlaylist(songs, 0);
                            Navigator.push(context, PlayerScreen.route());
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: EdgeInsets.only(
                          bottom: playbackProvider.currentSong != null
                              ? 92
                              : 16,
                        ),
                        itemCount: songs.length,
                        onReorder: (oldIndex, newIndex) {
                          playlistProvider.reorderSongs(
                            playlistId,
                            oldIndex,
                            newIndex,
                          );
                        },
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return Dismissible(
                            key: Key(song.path),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.redAccent,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) {
                              playlistProvider.removeSongFromPlaylist(
                                playlistId,
                                song.path,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed "${song.title}"'),
                                  backgroundColor: Colors.grey[800],
                                ),
                              );
                            },
                            child: SongListTile(
                              title: song.title,
                              artist: song.artist,
                              duration: _formatDuration(song.duration),
                              albumArt: song.albumArt,
                              albumArtPath: song.albumArtPath,
                              onTap: () {
                                playbackProvider.setPlaylist(songs, index);
                                Navigator.push(context, PlayerScreen.route());
                              },
                              onLongPress: () {},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          if (playbackProvider.currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MiniPlayer(
                  title: playbackProvider.currentSong!.title,
                  artist: playbackProvider.currentSong!.artist,
                  albumArt: playbackProvider.currentSong!.albumArt,
                  albumArtPath: playbackProvider.currentSong!.albumArtPath,
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
        ],
      ),
    );
  }
}
