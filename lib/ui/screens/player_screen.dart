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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text("No song selected", style: TextStyle())),
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
            color: Theme.of(context).cardColor,
            child: Icon(
              Icons.music_note,
              color: Theme.of(context).textTheme.bodySmall?.color,
              size: 100,
            ),
          );
        },
      );
    } else if (currentSong.albumArtPath != null) {
      artWidget = Image.file(
        File(currentSong.albumArtPath!),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.9,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            color: Theme.of(context).cardColor,
            child: Icon(
              Icons.music_note,
              color: Theme.of(context).textTheme.bodySmall?.color,
              size: 100,
            ),
          );
        },
      );
    } else {
      artWidget = Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.9,
        color: Theme.of(context).cardColor,
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).iconTheme.color,
          size: 100,
        ),
      );
    }

    return Dismissible(
      key: const Key('player_screen_dismiss'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).iconTheme.color,
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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
                    _MarqueeText(
                      currentSong.title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MarqueeText(
                      currentSong.artist,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.lyrics_rounded,
                            color: showLyrics
                                ? Colors.redAccent
                                : Theme.of(context).iconTheme.color,
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
                                : Theme.of(context).iconTheme.color,
                          ),
                          onPressed: () async {
                            final songProvider = Provider.of<SongProvider>(
                              context,
                              listen: false,
                            );
                            final wasFavorite = songProvider.isFavorite(
                              currentSong.path,
                            );

                            await songProvider.toggleFavorite(currentSong.path);

                            // If we just unliked it AND we are playing from "favorites" queue, remove it.
                            if (wasFavorite &&
                                playbackService.currentQueueId == 'favorites') {
                              playbackService.removeSongFromQueue(
                                currentSong.path,
                              );
                            }
                          },
                          tooltip: 'Favorite',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                                  : position.inMilliseconds.toDouble().clamp(
                                      0.0,
                                      duration.inMilliseconds.toDouble(),
                                    ),
                              max: duration.inMilliseconds.toDouble(),
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
                                  Duration(milliseconds: value.toInt()),
                                );
                                setState(() {
                                  _isDragging = false;
                                });
                              },
                              activeColor: Colors.deepPurpleAccent,
                              inactiveColor: Theme.of(context).dividerColor,
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
                                    _formatDuration(
                                      _isDragging
                                          ? Duration(
                                              milliseconds: _dragValue.toInt(),
                                            )
                                          : position,
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
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
                                    : _getControlIconColor(context),
                                size: 30,
                              ),
                              onPressed: playbackService.toggleShuffle,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: _getControlIconColor(context),
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
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    color: _getPlayButtonIconColor(context),
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            } else if (!playing) {
                              return _buildControlButton(
                                onPressed: playbackService.play,
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: _getPlayButtonIconColor(context),
                                  size: 48,
                                ),
                              );
                            } else if (processingState !=
                                ProcessingState.completed) {
                              return _buildControlButton(
                                onPressed: playbackService.pause,
                                child: Icon(
                                  Icons.pause_rounded,
                                  color: _getPlayButtonIconColor(context),
                                  size: 48,
                                ),
                              );
                            } else {
                              return _buildControlButton(
                                onPressed: playbackService.play,
                                child: Icon(
                                  Icons.replay_rounded,
                                  color: _getPlayButtonIconColor(context),
                                  size: 48,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: _getControlIconColor(context),
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
                                ? _getControlIconColor(context)
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

  Color _getPlayButtonIconColor(BuildContext context) {
    // Use background color for play/pause button in both themes
    // This creates strong contrast on the purple circle
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color _getControlIconColor(BuildContext context) {
    // Use artist name color (bodySmall) in light theme for better contrast
    // Keep icon theme color (white) in dark theme
    return Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54
        : Theme.of(context).iconTheme.color ?? Colors.white;
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

    if (mounted) {
      setState(() {
        _lyrics = initial;
        _controller.text = initial ?? '';
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.3),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: "Paste lyrics here...",
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _lyrics ??
                            "No lyrics available.\nTap edit to add them.",
                        style: TextStyle(
                          color: _lyrics == null
                              ? Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.5)
                              : Theme.of(context).textTheme.bodyLarge?.color,
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

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _MarqueeText(this.text, {Key? key, this.style}) : super(key: key);

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(
            seconds:
                (_scrollController.position.maxScrollExtent / 30).round() + 5,
          ),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut,
        );
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
