import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:simplemp3pkayer/openPlaylistPage.dart';
import 'Widgets_player.dart';
import 'Database.dart';
import 'songWidget.dart';

class modifyPlaylistPage extends StatefulWidget{
  final int? id;
  const modifyPlaylistPage({super.key,this.id});

  @override
  State<modifyPlaylistPage> createState() => _modifyPlaylistPageState();

}

class _modifyPlaylistPageState extends State<modifyPlaylistPage>{
  final db = songDatabase();
  //final pDb = playlistManager();
  PlayerManager pl = PlayerManager();
  PlayList? playList;
  bool hasLoaded = false;
  final controller = TextEditingController();
  List<int> songsIds = [];
  List<Song> songs = [];




  Widget buildSongList(){
    if(songs.isEmpty)return const Text("Nessuna canzone inserita!");

    return ReorderableListView.builder(
        itemBuilder: (context, index){
          final song = songs[index];
          return ListTile(
            key: ValueKey(song.id ?? "${song.Name}_$index"),
            title: songWidget(song, index),
          );
        },
        itemCount: songs.length,
        onReorder: (int oldIndex, int newIndex){
          if(newIndex>oldIndex)newIndex--;
          final Song movedSong = songs.removeAt(oldIndex);
          songs.insert(newIndex, movedSong);

          final int movedId = songsIds.removeAt(oldIndex);
          songsIds.insert(newIndex, movedId);
        });
  }


  /*Widget getSongsInsideAPlaylist(PlayList? p){
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
        return Column(
          children: [
        ReorderableListView.builder(
        itemCount: songs.length,
          itemBuilder: (context, index){
            return songWidget(songs[index], index);
          },
            onReorder:(oldIndex,newIndex){
              if(oldIndex<0 || oldIndex>=p.songs.length) return;
              if(newIndex<0 || newIndex>=p.songs.length)return;
              final id = songsIds.removeAt(oldIndex);
              songsIds.insert(newIndex, id);
              
              
            } ,
        )
          ],
        );
       
      });
    }
    return const Text("Nessuna playlist inserita!");

  }*/



  Future<void> loadPlaylist()async{
    if(widget.id==null)return;
    playList = await db.getAPlaylistById(widget.id!);
    if(playList != null){
      controller.text = playList!.name;
      songsIds = List.from(playList!.songs);
      songs = await db.getSongsById(songsIds);

      if(mounted){
        setState(() {
          hasLoaded = true;
        });
      }
    }


  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPlaylist();

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!hasLoaded) return CircularProgressIndicator();
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(

      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child:  TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Nome playlist",
                  border: OutlineInputBorder()
                ),
              ),
              ),
              const SizedBox(width: 10,),
              TextButton(onPressed: ()=>{}, child: const Text("Cambia copertina"))
            ],
            ),
          ),



          const Divider(height: 1),
          Expanded(child: buildSongList())



          


        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()async {
          if(playList == null)return;
          final newP = PlayList(name: controller.text, songs: songsIds, img: playList!.img, id: playList!.id, isPinned: playList!.isPinned);
          await db.updateAPlaylist(newP);
          await Navigator.push(context, MaterialPageRoute(builder: (_)=>openPlayListPage(id: playList!.id!,)));
        },
        tooltip: 'Salva',
        child: const Icon(Icons.save),

      ),
    );
  }
}