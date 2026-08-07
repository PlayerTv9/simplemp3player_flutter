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


                  pl.queueSongs.clear();
                  pl.queueSongs.add(songs[index]);
                  pl.loadQueue(pl.queueSongs, 0);

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
  pl.queueSongs = List.from(newQueue);
  pl.loadQueue(pl.queueSongs, 0);},
    tooltip: 'Riproduci la playlist',
  child: const Icon(Icons.play_arrow_outlined),

  ),
    );
  }
}