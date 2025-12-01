import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../providers/playback_provider.dart';

class MiniPlayer extends StatelessWidget {
  final String title;
  final String artist;
  final Uint8List? albumArt;
  final String? albumArtPath;
  final bool isPlaying;
  final String heroTag;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onTap;

  const MiniPlayer({
    Key? key,
    required this.title,
    required this.artist,
    this.albumArt,
    this.albumArtPath,
    required this.isPlaying,
    required this.heroTag,
    required this.onPlayPause,
    required this.onNext,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playbackService = Provider.of<PlaybackProvider>(context);
    final player = playbackService.player;

    Widget artWidget;
    if (albumArt != null) {
      artWidget = Image.memory(
        albumArt!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[700],
            child: const Icon(
              Icons.music_note,
              color: Colors.white70,
              size: 28,
            ),
          );
        },
      );
    } else if (albumArtPath != null && File(albumArtPath!).existsSync()) {
      artWidget = Image.file(
        File(albumArtPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[700],
            child: const Icon(
              Icons.music_note,
              color: Colors.white70,
              size: 28,
            ),
          );
        },
      );
    } else {
      artWidget = Container(
        color: Colors.grey[700],
        child: const Icon(Icons.music_note, color: Colors.white70, size: 28),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 52, height: 52, child: artWidget),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final isPlayingLive = playerState?.playing ?? false;
                final processing = playerState?.processingState;

                Widget icon;
                if (processing == ProcessingState.loading) {
                  icon = const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                } else if (isPlayingLive) {
                  icon = const Icon(
                    Icons.pause_rounded,
                    color: Colors.white,
                    size: 32,
                  );
                } else {
                  icon = Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  );
                }

                return Row(
                  children: [
                    IconButton(icon: icon, onPressed: onPlayPause),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: onNext,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
