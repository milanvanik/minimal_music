import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SongListTile extends StatelessWidget {
  final String title;
  final String artist;
  final String duration;
  final Uint8List? albumArt;
  final String? albumArtPath;
  final VoidCallback onTap;

  const SongListTile({
    Key? key,
    required this.title,
    required this.artist,
    required this.duration,
    this.albumArt,
    this.albumArtPath,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    Widget artWidget;
    if (albumArt != null) {
      artWidget = Image.memory(
        albumArt!,
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 55,
            height: 55,
            color: Colors.grey[800],
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
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 55,
            height: 55,
            color: Colors.grey[800],
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
        width: 55,
        height: 55,
        color: Colors.grey[800],
        child: const Icon(Icons.music_note, color: Colors.white70, size: 28),
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(width: 55, height: 55, child: artWidget),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              duration,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
