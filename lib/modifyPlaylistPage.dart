import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
  String btnText = "Cambia/aggiungi copertina";
  String? pathImg;
  String? oldPathImg;




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





  Future<void> loadPlaylist()async{
    if(widget.id==null)return;
    playList = await db.getAPlaylistById(widget.id!);
    if(playList != null){
      controller.text = playList!.name;
      songsIds = List.from(playList!.songs);
      songs = await db.getSongsById(songsIds);
      oldPathImg = playList!.img;


      if(mounted){
        setState(() {
          hasLoaded = true;
        });
      }
    }


  }

  Future<String?> getImgPath()async{

    if(pathImg != null){
      final file = File(pathImg!);
      if(pathImg != "" && await file.exists()){
        if(oldPathImg != null && oldPathImg != ""){
          final oldFile = File(oldPathImg!);
          if(await oldFile.exists()){
            await oldFile.delete();
          }
        }
        return pathImg;
      }
    }
    return oldPathImg;



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
              TextButton.icon(onPressed: ()async{
                final file = await FilePicker.pickFiles(
                    type: FileType.image,
                    allowMultiple: false
                );
                if(file != null && file.files.single.path != null){
                  final originalFile = File(file.files.single.path!);

                  final appDir = await getApplicationDocumentsDirectory();
                  final fileName = "playlist_${DateTime.now().millisecondsSinceEpoch}.${file.files.single.extension}";
                  final savedImage = await originalFile.copy("${appDir.path}/$fileName");

                  setState(() {
                    pathImg = savedImage.path;
                    btnText = file.files.single.name;
                  });
                  print("path img salvata: ${pathImg}");
                }
              }, label: Text(btnText), icon: const Icon(Icons.image),)
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
          final img = await getImgPath();
          final newP = PlayList(name: controller.text, songs: songsIds, img: img, id: playList!.id, isPinned: playList!.isPinned);
          await db.updateAPlaylist(newP);
          await Navigator.push(context, MaterialPageRoute(builder: (_)=>openPlayListPage(id: playList!.id!,)));
        },
        tooltip: 'Salva',
        child: const Icon(Icons.save),

      ),
    );
  }
}