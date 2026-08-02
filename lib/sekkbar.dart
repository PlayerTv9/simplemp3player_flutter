import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioSeekBar extends StatefulWidget {
  final AudioPlayer player;

  const AudioSeekBar({
    super.key,
    required this.player,
  });

  @override
  State<AudioSeekBar> createState() => _AudioSeekBarState();
}

class _AudioSeekBarState extends State<AudioSeekBar> {
  double? dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;

        final duration = widget.player.duration;
        if (duration == null || duration.inMilliseconds <= 0) {
          return const SizedBox.shrink();
        }

        final max = duration.inMilliseconds.toDouble();

        final rawValue = dragValue ?? pos.inMilliseconds.toDouble();

        final value = rawValue.clamp(0.0, max);

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
          ),
          child: Semantics(
            excludeSemantics: true,
            child: Slider(
              key: const ValueKey("audio_seek_slider"),
              min: 0.0,
              max: max,
              value: value.isNaN ? 0.0 : value,
              onChanged: (v) {
                setState(() {
                  dragValue = v;
                });
              },
              onChangeEnd: (v) async {
                await widget.player.seek(
                  Duration(milliseconds: v.toInt()),
                );
                setState(() {
                  dragValue = null;
                });
              },
            ),
          )

        );
      },
    );
  }
}