import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:metadata_god/metadata_god.dart';
import 'Widgets_player.dart';
import 'Database.dart';
import 'songWidget.dart';

class openPlayListPage extends StatefulWidget{
  final PlayList? playList;
  final int? id;
  const openPlayListPage({super.key,this.playList,this.id});

  @override
  State<StatefulWidget> createState() => _openPlaylistState();

}

class _openPlaylistState extends State<openPlayListPage>{
  final db = songDatabase();
  final pDb = playlistManager();
  PlayerManager pl = PlayerManager();

  Future<void> showPlaylistSelector(int songId)async{
    final playlists = await pDb.loadPlaylist();
    if(!mounted)return;
    showModalBottomSheet(context: context, builder: (context){
      return ListView.builder(
          itemCount: playlists.length,

          itemBuilder: (context, index){
            final playlist = playlists[index];
            return ListTile(
              title: Text(playlist.name),
              onTap: ()async{
                await pDb.addSongToPlaylist(playlist.name, songId);
                Navigator.pop(context);
              },

            );

          }
      );
    });

  }

  void songMenu(BuildContext context, Song s){
    showModalBottomSheet(context: context, builder: (context){
    return Column(
      mainAxisSize: .min,
      children: [
        ListTile(
          leading: const Icon(Icons.playlist_remove),
          title: const Text("Rimuovi dalla playlist"),
          onTap: ()async{
            await pDb.removeASongFromAPLaylist(widget.playList!.name, s.id!);

            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.playlist_add),
          title: const Text("Aggiungi a un'altra playlist"),
          onTap: (){
            showPlaylistSelector(s.id!);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.music_off),
          title: const Text("Rimuovi dall player"),
          onTap: ()async{
            await pDb.removeASongFromAPLaylist(widget.playList!.name, s.id!);
            await db.remove(s.id!);

            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_to_queue_outlined),
          title: const Text("Aggiungi in coda"),
          onTap: ()async{
            pl.queue.add(s);
            pl.loadQueue(pl.queue, 0);
          },
        )

      ],
    );
    });
  }
  Widget getSongsInsideAPlaylist(){
      if(widget.playList != null){
        return FutureBuilder(future: db.getSongsById(widget.playList!.songs), builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting)return CircularProgressIndicator();
          if(!snapshot.hasData || snapshot.data!.isEmpty){
            return const Text("La playlist è ancora vuota!");
          }
          if(snapshot.hasError){
            return Text(snapshot.error.toString());
          }
          final songs = snapshot.data!;
          return ListView.builder(
            itemCount: songs.length,
              itemBuilder: (context, index){
            return Row(
              children: [
              InkWell(
                onTap: ()async{


                  pl.queue.clear();
                  pl.queue.add(songs[index]);
                  pl.loadQueue(pl.queue, 0);

                  setState(() {

                  });
                },
                onLongPress: (){
                  songMenu(context, songs[index]);
                  setState(() {

                  });
                  },
                child: songWidget(songs[index], index),
              )
              ],
            );
          });
        });
      }
        return const Text("Nessuna playlist inserita!");

  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playList?.name ?? "Nessuna playlist selezionata"),

      ),
      body: Stack(
        children: [



          getSongsInsideAPlaylist(),

          Align(
              alignment: Alignment.bottomCenter,

              child: Padding(padding: const EdgeInsets.only(bottom: 80),
                child: miniPlayer(audio: pl.player, expand: (){
                  Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpandedPlayer(audio: pl.player, close: ()=>Navigator.pop(context),s:pl.currentSong)));
                },s: pl.currentSong,),)
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: ()async{
  if(widget.playList == null) return;
  List<Song> newQueue = await db.getSongsById(widget.playList!.songs);
  pl.queue = List.from(newQueue);
  pl.loadQueue(pl.queue, 0);},
    tooltip: 'Riproduci la playlist',
  child: const Icon(Icons.play_arrow_outlined),

  ),
    );
  }
}