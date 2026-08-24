import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:metadata_god/metadata_god.dart';
import 'Widgets_player.dart';
import 'Database.dart';
import 'songWidget.dart';
import 'modifyPlaylistPage.dart';

class openPlayListPage extends StatefulWidget{
  final int? id;
  const openPlayListPage({super.key,this.id});

  @override
  State<StatefulWidget> createState() => _openPlaylistState();

}

class _openPlaylistState extends State<openPlayListPage>{
  final db = songDatabase();
  //final pDb = playlistManager();
  PlayerManager pl = PlayerManager();
  PlayList? playList;
  bool hasLoaded = false;




  Widget getSongsInsideAPlaylist(PlayList? p){
      if(p != null){
        return FutureBuilder(future: db.getSongsById(p.songs), builder: (context, snapshot){
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
                  songMenu(context, songs[index], pId: widget.id!, type: menuType.Playlist);
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



  Future<void> loadPlaylist()async{
    playList = await db.getAPlaylistById(widget.id!);
    setState(() {
      hasLoaded = true;
    });

  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPlaylist();

  }

  @override
  Widget build(BuildContext context) {

    if(!hasLoaded) return CircularProgressIndicator();
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(playList?.name ?? "Nessuna playlist selezionata"),
        actions: [
          TextButton.icon(
              onPressed: ()async{
                await Navigator.push(context, MaterialPageRoute(builder: (_)=>modifyPlaylistPage(id: widget.id,)));
              },
              label: const Text("Modifica la playlist"),
              icon: const Icon(Icons.mode_edit_outline_outlined),
          )
        ],


      ),
      body: Stack(
        children: [



          getSongsInsideAPlaylist(playList),

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
  if(playList == null) return;
  List<Song> newQueue = await db.getSongsById(playList!.songs);
  pl.queueSongs = List.from(newQueue);
  pl.loadQueue(pl.queueSongs, 0);},
    tooltip: 'Riproduci la playlist',
  child: const Icon(Icons.play_arrow_outlined),

  ),
    );
  }
}