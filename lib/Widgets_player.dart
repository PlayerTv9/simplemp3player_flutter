import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';

import 'Queue.dart';
import 'Database.dart';
import "sekkbar.dart";

String formatDuraton(Duration d){
  final minuetes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minuetes:${seconds.toString().padLeft(2, '0')}';
}

class PlayerManager{
  PlayerManager._(){
    player.currentIndexStream.listen((index){
      if(index!=null){
        currentIndex = index;

      }
    });
  }
  static final PlayerManager _istance = PlayerManager._();
  factory PlayerManager() => _istance;

  final AudioPlayer player = AudioPlayer();


  List<Song> queueSongs = [];
  int currentIndex = 0;

  Song? get currentSong => queueSongs.isEmpty ? null : queueSongs[currentIndex];

  Future<void> loadQueue(
      List<Song> songs,
      int startIndex,
      ) async {

    queueSongs = List.from(songs);
    currentIndex = startIndex;

    final playlist = await Future.wait(
        queueSongs.map((s)async=>await getAudioSource(s))
    );


    await player.setAudioSources(
      playlist,
      initialIndex: startIndex,
    );



    player.play();
    if(songs.isNotEmpty){
      final db = songDatabase();
      final c = chrono_element(type: crono_type.song, element_id: songs[0].id!);
      await db.insertChronoElement(c);
      final allCEleem = await db.getAllChronoElements();
      for(final el in allCEleem){
        print(el);
      }
    }


  }

  Future<void> addASongsToQueue(List<Song> newSongs)async{

    queueSongs.addAll(newSongs);

    final currentPlaylist = player.audioSource;
    if(currentPlaylist != null){
      final newSources = await Future.wait(
        newSongs.map((s)async=>await getAudioSource(s))
      );

      await player.addAudioSources(newSources);
    }else{
      await loadQueue(queueSongs, currentIndex);
    }
  }

  Future<void> removeSongAt(int index)async{
    if(index<0 || index>=queueSongs.length)return;
    queueSongs.removeAt(index);
    await player.removeAudioSourceAt(index);
  }

  Future<void> moveSong(int oldIndex, int newIndex)async{
    if(oldIndex<0 || oldIndex>=queueSongs.length)return;
    if(newIndex<0 || newIndex>=queueSongs.length)return;
    if(oldIndex==newIndex)return;
    final song = queueSongs.removeAt(oldIndex);
    queueSongs.insert(newIndex, song);
    await player.moveAudioSource(oldIndex, newIndex);

  }

  Future<Uri?> getUriByTempFile(Metadata m, Song s)async{
    if(m.picture != null && m.picture!.data.isNotEmpty){
      final tempDIr = await getTemporaryDirectory();
      final file = File('${tempDIr.path}/cover_${s.id ?? s.path.hashCode}.jpg');
      if(!await file.exists()){
        await file.writeAsBytes(m.picture!.data);

      }
      return Uri.file(file.path);
    }
    return null;
  }

  Future<UriAudioSource> getAudioSource(Song s)async{

    final metadati = await MetadataGod.readMetadata(file: s.path);
    final picture = await getUriByTempFile(metadati, s);
    return AudioSource.file(
      s.path,
      tag: MediaItem(
          id: s.path,
          title: metadati.title ?? s.Name,
          artist: metadati.artist ?? "Autore sconosciuto",
          album: metadati.album ?? "--",
          duration: metadati.duration ?? Duration(milliseconds: 0),
          artUri: picture

      )
    );
  }




}




class miniPlayer extends StatefulWidget{
  final AudioPlayer audio;
  final VoidCallback expand;
  final Song? s;
  const miniPlayer({
    super.key,
    required this.audio,
    required this.expand,
    this.s
});

  @override
  State<miniPlayer> createState() => _miniPLayerState();
}

class _miniPLayerState extends State<miniPlayer>{

  Metadata? metadata;
  final pl = PlayerManager();

  void play(){
    if (widget.audio.audioSource != null){
      if(widget.audio.playing){
        widget.audio.pause();
      }else{
        widget.audio.play();
      }
    }

  }
 /* Future<void> setMetadata() async {
    if (widget.s == null) return;

    try {
      final m = await MetadataGod.readMetadata(file: widget.s!.path);
      if (!mounted) return;

      setState(() {
        metadata = m;
      });
    } catch (_) {
      // evita crash se file/audio non valido
    }
  }*/

  Future<void> setMetadata() async {
    final song = PlayerManager().currentSong;
    if (song == null) return;

    try {
      final m = await MetadataGod.readMetadata(file: song.path);
      if (!mounted) return;

      setState(() {
        metadata = m;
      });
    } catch (_) {
      // evita crash se file/audio non valido
    }
  }

  Widget artworkWidget() {
    final pic = metadata?.picture;

    if (pic != null && pic.data.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          pic.data,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.music_note,
        size: 20,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant miniPlayer oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if(oldWidget.s?.path != widget.s?.path){
      setMetadata();
    }
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setMetadata();

    widget.audio.currentIndexStream.listen((_){
      if(!mounted)return;
      setMetadata();
      setState(() {

      });
    });
  }
  
  Widget songTitle(String title){
    const style = TextStyle(
      color: Colors.white,
      fontSize: 16
    );
    
    const maxWidth = 180.0;
    final painter = TextPainter(
      text: TextSpan(text: title, style: style),
      maxLines: 1,
      textDirection: .ltr
    )..layout();
    if(painter.width<=maxWidth){
      return SizedBox(
        width: maxWidth,
        child: Text(
          title,
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return SizedBox(
      width: maxWidth,
      height: 20,
      child: Marquee(text: title,
      style: style,
      velocity: 20,
        blankSpace: 40,
        pauseAfterRound: const Duration(seconds: 1),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: widget.expand,
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
          artworkWidget(),
            SizedBox(width: 10,),



            Column(
              children: [
                Expanded(
                    child: Row(
                      mainAxisAlignment: .center,
                      crossAxisAlignment: .center,
                      children: [
                        songTitle( metadata != null && metadata!.title != null  ? metadata!.title! : "Nessuna canzone scelta")

                      ],
                    )),
                Expanded(

                  child: Row(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .center,
                    children: [
                      IconButton(onPressed: ()async {
                        if(widget.audio.hasPrevious) await widget.audio.seekToPrevious();
                      }, icon: Icon(Icons.navigate_before_outlined), color: widget.audio.hasPrevious ? Colors.blueAccent : Theme.of(context).colorScheme.secondary,),
                      StreamBuilder<PlayerState>(
                          stream: widget.audio.playerStateStream,
                          builder: (context, snapshot){
                            final playing = snapshot.data?.playing ?? false;
                            return IconButton(onPressed: play, icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation){
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,);
                              },
                              child: Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                key: ValueKey(playing),
                                color: Colors.blueAccent,
                              ),
                            ),color: Colors.blueAccent,);
                          }),
                      IconButton(onPressed: ()async {
                        if(widget.audio.hasNext) await widget.audio.seekToNext();
                      }, icon: Icon(Icons.navigate_next),
                        color: widget.audio.hasNext ? Colors.blueAccent : Theme.of(context).colorScheme.secondary,),
                      IconButton(onPressed: ()async{
                        if(widget.audio.loopMode == LoopMode.off) {
                          await widget.audio.setLoopMode(LoopMode.one);
                        }
                        else {
                          await widget.audio.setLoopMode(LoopMode.off);
                        }
                      }, icon: Icon(Icons.repeat),
                        color: widget.audio.loopMode == LoopMode.one ? Colors.blueAccent :  Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 40,
                  child: AudioSeekBar(player: widget.audio),
                ),



              ],



            ),
          ],
        )
      ),
    );
  }
}

class ExpandedPlayer extends StatefulWidget{
  final AudioPlayer audio;
  final VoidCallback close;
  final Song? s;
  const ExpandedPlayer({
    super.key,
    required this.audio,
    required this.close,
    this.s
  });
  @override
  State<ExpandedPlayer> createState() => _expandedPLayerState();
}

class _expandedPLayerState extends State<ExpandedPlayer> {
Metadata? metadata;

void play() {
  if (widget.audio.audioSource != null) {
    if (widget.audio.playing) {
      widget.audio.pause();
    } else {
      widget.audio.play();
    }
  }
}

/*Future<void> setMetadata() async {
  if (widget.s == null) return;

  try {
    final m = await MetadataGod.readMetadata(file: widget.s!.path);
    if (!mounted) return;

    setState(() {
      metadata = m;
    });
  } catch (_) {
    // evita crash se file/audio non valido
  }
}*/

  Future<void> setMetadata() async {
    final song = PlayerManager().currentSong;
    if (song == null) return;

    try {
      final m = await MetadataGod.readMetadata(file: song.path);
      if (!mounted) return;

      setState(() {
        metadata = m;
      });
    } catch (_) {
      // evita crash se file/audio non valido
    }
  }


Widget artworkWidget() {
  final pic = metadata?.picture;

  if (pic != null && pic.data.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        pic.data,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }

  return Container(
    width: 250,
    height: 250,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(
      Icons.music_note,
      size: 100,
    ),
  );
}

@override
void initState() {
  super.initState();
  setMetadata();

  widget.audio.currentIndexStream.listen((_){
    if(!mounted)return;
    setMetadata();
    setState(() {

    });
  });


}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          IconButton(
            onPressed: widget.close,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              metadata != null && metadata!.title != null  ? metadata!.title! : "Nessuna canzone scelta",
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 20),

          artworkWidget(),


          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [

              IconButton(onPressed: ()async {
                if(widget.audio.hasPrevious) await widget.audio.seekToPrevious();
              }, icon: Icon( Icons.navigate_before_outlined), color: widget.audio.hasPrevious ? Colors.blueAccent : Theme.of(context).colorScheme.secondary,),

              StreamBuilder<PlayerState>(
                stream: widget.audio.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;

                  return IconButton(
                    onPressed: play,
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.blueAccent,
                    ),
                  );
                },
              ),
              IconButton(onPressed: ()async {
                if(widget.audio.hasNext) await widget.audio.seekToNext();
              }, icon: Icon(Icons.navigate_next),
                color: widget.audio.hasNext ? Colors.blueAccent : Theme.of(context).colorScheme.secondary,),

            ],
          ),

          IconButton(onPressed: ()async{
            if(widget.audio.loopMode == LoopMode.off) {
              await widget.audio.setLoopMode(LoopMode.one);
            }
            else {
              await widget.audio.setLoopMode(LoopMode.off);
            }
          }, icon: Icon(Icons.repeat),
            color: widget.audio.loopMode == LoopMode.one ? Colors.blueAccent :  Theme.of(context).colorScheme.secondary,
          ),




          const SizedBox(height: 10),

          // 🔥 SEEK BAR ISOLATA (NON CRASHA PIÙ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AudioSeekBar(player: widget.audio, color: Colors.black,),
          ),

          const SizedBox(height: 10),


          IconButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>Queue())), icon: Icon(Icons.queue)),
        ],
      ),
    ),
  );
}
}