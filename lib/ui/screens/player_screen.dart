import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../models/song_model.dart';
import '../../providers/playback_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  static Route<void> route() {
    return PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlayerScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatDuration(Duration? d) {
    if (d == null) return "-:--";
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final playbackService = Provider.of<PlaybackProvider>(context);
    final currentSong = playbackService.currentSong;
    final audioPlayer = playbackService.player;
    final showLyrics = playbackService.showLyrics;

    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No song selected",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    Widget artWidget;
    if (currentSong.albumArt != null) {
      artWidget = Image.memory(
        currentSong.albumArt!,
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.9,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            color: Colors.grey[800],
            child: const Icon(
              Icons.music_note,
              color: Colors.white70,
              size: 100,
            ),
          );
        },
      );
    } else if (currentSong.albumArtPath != null &&
        File(currentSong.albumArtPath!).existsSync()) {
      artWidget = Image.file(
        File(currentSong.albumArtPath!),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.9,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            color: Colors.grey[800],
            child: const Icon(
              Icons.music_note,
              color: Colors.white70,
              size: 100,
            ),
          );
        },
      );
    } else {
      artWidget = Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.9,
        color: Colors.grey[800],
        child: const Icon(Icons.music_note, color: Colors.white70, size: 100),
      );
    }

    return Dismissible(
      key: const Key('player_screen_dismiss'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [],
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(),
                    Hero(
                      tag: "current-song-art-${playbackService.currentIndex}",
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                child: child,
                                builder: (context, child) {
                                  final isEntering =
                                      (ValueKey(showLyrics) == child?.key);

                                  if (animation.value < 0.5) {
                                    return Visibility(
                                      visible: false,
                                      maintainSize: true,
                                      maintainState: true,
                                      maintainAnimation: true,
                                      child: child!,
                                    );
                                  }

                                  double angle;
                                  if (isEntering) {
                                    angle = (1.0 - animation.value) * 3.14159;
                                  } else {
                                    angle = (1.0 - animation.value) * -3.14159;
                                  }

                                  return Transform(
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateY(angle),
                                    alignment: Alignment.center,
                                    child: child,
                                  );
                                },
                              );
                            },
                        child: showLyrics
                            ? _LyricsCard(
                                key: const ValueKey(true),
                                song: currentSong,
                                size: MediaQuery.of(context).size.width * 0.9,
                              )
                            : SizedBox(
                                key: const ValueKey(false),
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.width * 0.9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: artWidget,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      currentSong.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSong.artist,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.lyrics_rounded,
                            color: showLyrics
                                ? Colors.deepPurpleAccent
                                : Colors.white70,
                          ),
                          onPressed: () => playbackService.toggleLyrics(),
                          tooltip: 'Lyrics',
                        ),
                        const SizedBox(width: 32),
                        IconButton(
                          icon: Icon(
                            Provider.of<SongProvider>(
                                  context,
                                ).isFavorite(currentSong.path)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color:
                                Provider.of<SongProvider>(
                                  context,
                                ).isFavorite(currentSong.path)
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                          onPressed: () {
                            Provider.of<SongProvider>(
                              context,
                              listen: false,
                            ).toggleFavorite(currentSong.path);
                          },
                          tooltip: 'Favorite',
                        ),
                      ],
                    ),
                    const Spacer(),
                    StreamBuilder<Duration>(
                      stream: audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = audioPlayer.duration ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              value: _isDragging
                                  ? _dragValue
                                  : position.inSeconds.toDouble().clamp(
                                      0.0,
                                      duration.inSeconds.toDouble(),
                                    ),
                              max: duration.inSeconds.toDouble(),
                              onChangeStart: (value) {
                                setState(() {
                                  _isDragging = true;
                                  _dragValue = value;
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  _dragValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                audioPlayer.seek(
                                  Duration(seconds: value.toInt()),
                                );
                                setState(() {
                                  _isDragging = false;
                                });
                              },
                              activeColor: Colors.deepPurpleAccent,
                              inactiveColor: Colors.grey[700],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StreamBuilder<bool>(
                          stream: audioPlayer.shuffleModeEnabledStream,
                          builder: (context, snapshot) {
                            final shuffleEnabled = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: shuffleEnabled
                                    ? Colors.deepPurpleAccent
                                    : Colors.white70,
                                size: 30,
                              ),
                              onPressed: playbackService.toggleShuffle,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: playbackService.skipToPrevious,
                        ),
                        StreamBuilder<PlayerState>(
                          stream: audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState =
                                playerState?.processingState;
                            final playing = playerState?.playing ?? false;

                            if (processingState == ProcessingState.loading) {
                              return _buildControlButton(
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            } else if (!playing) {
                              return _buildControlButton(
                                onPressed: playbackService.play,
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              );
                            } else if (processingState !=
                                ProcessingState.completed) {
                              return _buildControlButton(
                                onPressed: playbackService.pause,
                                child: const Icon(
                                  Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              );
                            } else {
                              return _buildControlButton(
                                onPressed: playbackService.play,
                                child: const Icon(
                                  Icons.replay_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: playbackService.skipToNext,
                        ),
                        StreamBuilder<LoopMode>(
                          stream: audioPlayer.loopModeStream,
                          builder: (context, snapshot) {
                            final loopMode = snapshot.data ?? LoopMode.off;
                            final icons = {
                              LoopMode.off: Icons.repeat_rounded,
                              LoopMode.all: Icons.repeat_rounded,
                              LoopMode.one: Icons.repeat_one_rounded,
                            };
                            final color = loopMode == LoopMode.off
                                ? Colors.white70
                                : Colors.deepPurpleAccent;

                            return IconButton(
                              icon: Icon(
                                icons[loopMode],
                                color: color,
                                size: 30,
                              ),
                              onPressed: playbackService.toggleLoopMode,
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({Widget? child, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.deepPurpleAccent,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LyricsCard extends StatefulWidget {
  final Song song;
  final double size;
  const _LyricsCard({Key? key, required this.song, required this.size})
    : super(key: key);

  @override
  State<_LyricsCard> createState() => _LyricsCardState();
}

class _LyricsCardState extends State<_LyricsCard> {
  final AudioHandler _audioService = AudioHandler();
  String? _lyrics;
  bool _isEditing = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lyrics = widget.song.lyrics;
    _controller.text = _lyrics ?? '';
    _loadLyrics();
  }

  @override
  void didUpdateWidget(_LyricsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song.path != oldWidget.song.path) {
      _loadLyrics();
    }
  }

  Future<void> _loadLyrics() async {
    final saved = await _audioService.getLyrics(widget.song.path);
    final initial = saved ?? widget.song.lyrics;

    if (mounted && saved != null) {
      setState(() {
        _lyrics = saved;
        _controller.text = saved;
      });
    }
  }

  Future<void> _saveLyrics() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await _audioService.saveLyrics(widget.song.path, text);
      if (mounted) {
        setState(() {
          _lyrics = text;
          _isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lyrics",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                      color: Colors.deepPurpleAccent,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_isEditing) {
                        _saveLyrics();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Paste lyrics here...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _lyrics ??
                            "No lyrics available.\nTap edit to add them.",
                        style: TextStyle(
                          color: _lyrics == null
                              ? Colors.white38
                              : Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
