import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../providers/playback_provider.dart';
import '../screens/player_screen.dart';
import 'song_list_tile.dart';

class SongSearchDelegate extends SearchDelegate {
  final List<Song> songs;
  final PlaybackProvider playbackProvider;

  SongSearchDelegate(this.songs, this.playbackProvider);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.grey[900],
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final results = songs.where((song) {
      final titleLower = song.title.toLowerCase();
      final artistLower = song.artist.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower) ||
          artistLower.contains(queryLower);
    }).toList();

    return Container(
      color: Colors.grey[900],
      child: results.isEmpty
          ? Center(
              child: Text(
                query.isEmpty ? "Search your library" : "No results found",
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final song = results[index];
                return SongListTile(
                  title: song.title,
                  artist: song.artist,
                  duration: _formatDuration(song.duration),
                  albumArt: song.albumArt,
                  albumArtPath: song.albumArtPath,
                  onTap: () {
                    // Find the index of this song in the main playlist
                    // to keep the context of the full library
                    final originalIndex = songs.indexOf(song);
                    if (originalIndex != -1) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      playbackProvider.setPlaylist(songs, originalIndex);
                      Navigator.push(context, PlayerScreen.route());
                    }
                  },
                );
              },
            ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "-:--";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
