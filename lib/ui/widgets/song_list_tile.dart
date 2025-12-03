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
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuTap;
  final bool selectionMode;
  final bool isSelected;

  const SongListTile({
    Key? key,
    required this.title,
    required this.artist,
    required this.duration,
    this.albumArt,
    this.albumArtPath,
    required this.onTap,
    this.onLongPress,
    this.onMenuTap,
    this.selectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

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
      child: Container(
        color: isSelected
            ? Colors.deepPurpleAccent.withOpacity(0.15)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(width: 55, height: 55, child: artWidget),
                ),
                if (selectionMode && isSelected)
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
              ],
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
            if (onMenuTap != null && !selectionMode) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: onMenuTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
