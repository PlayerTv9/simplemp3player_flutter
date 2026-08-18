import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioSeekBar extends StatefulWidget {
  final AudioPlayer player;
  final Color color;

  const AudioSeekBar({super.key, required this.player, this.color=Colors.white});

  @override
  State<AudioSeekBar> createState() => _AudioSeekBarState();
}

class _AudioSeekBarState extends State<AudioSeekBar> {
  double? dragValue;


  String formatDuraton(Duration d) {
    final minuetes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minuetes:${seconds.toString().padLeft(2, '0')}';
  }

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
        final currentDuration = Duration(milliseconds: value.round());



        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)
              ),
              child: Semantics(
                excludeSemantics: true,
                child: Slider(
                  key: const ValueKey("audio_seek_slider"),
                  min: 0.0,
                  max: max>0 ? max : 1.0,
                  value: value.isNaN ? 0.0 : value,
                  onChanged: (v) {
                    setState(() {
                      dragValue = v;
                    });
                  },
                  onChangeEnd: (v) async {
                    await widget.player.seek(Duration(milliseconds: v.round()));
                    setState(() {
                      dragValue = null;
                    });
                  },
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  Text("${formatDuraton(currentDuration)}/${formatDuraton(duration)}",style:  TextStyle(color: widget.color, fontSize: 12),),

                ],
              ),
            )
          ],
        );
      },
    );
  }
}
