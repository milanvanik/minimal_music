import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/playback_provider.dart';
import '../widgets/mini_player.dart';
import 'playlist_detail_screen.dart';
import 'player_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute(builder: (_) => const PlaylistsScreen());
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Create Playlist', style: TextStyle()),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
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
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final success = await Provider.of<PlaylistProvider>(
                  context,
                  listen: false,
                ).createPlaylist(controller.text.trim());

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playlist created'),
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playlist with this name already exists'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Create',
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
    final playlists = playlistProvider.playlists;
    final currentSong = playbackProvider.currentSong;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Playlists', style: TextStyle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play_rounded,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists yet',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first playlist to get started',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreatePlaylistDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Playlist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: currentSong != null ? 92 : 8,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final songs = playlistProvider.getSongsInPlaylist(
                      playlist.id,
                      songProvider.allSongs,
                    );

                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.playlist_play_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          playlist.name,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.7),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PlaylistDetailScreen.route(playlist.id),
                          );
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              title: const Text(
                                'Delete Playlist',
                                style: TextStyle(),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${playlist.name}"?',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    playlistProvider.deletePlaylist(
                                      playlist.id,
                                    );
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
                    );
                  },
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
        ],
      ),
    );
  }
}
