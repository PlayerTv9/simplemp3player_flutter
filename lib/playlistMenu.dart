import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathDart;
import 'Database.dart';
import 'openPlaylistPage.dart';
import 'modifyPlaylistPage.dart';
import 'Widgets_player.dart';

void playlistMenu(BuildContext context, PlayList p){
  final dbSong = songDatabase();
  final pl = PlayerManager();
  
  showModalBottomSheet(context: context, builder: (context){
    return Column(
      mainAxisSize: .min,
      children: [
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: const Text("Apri"),
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (_)=>openPlayListPage(id: p.id,)));
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.mode_edit),
          title: const Text("Modifica"),
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (_)=>modifyPlaylistPage(id: p.id,)));
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.copy),
          title: const Text("Copia"),
          onTap: ()async{
            String img = "";

            if(p.img != null || p.img != ""){
              final file = File(p.img!);
              if(await file.exists()){
                final appDir = await getApplicationDocumentsDirectory();
                final fileName = "playlist_${DateTime.now().millisecondsSinceEpoch}${pathDart.extension(p.img!)}";
                final newFile = await file.copy(fileName);
                img = newFile.path;
              }
            }
            final newP = PlayList(
                name: p.name,
                songs: p.songs,
                img: img,

            );
            await dbSong.addAPlaylist(newP);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text("Elimina"),
          onTap: ()async{
            if(p.id==null)return;
            await dbSong.removeAPlaylist(p.id!);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_to_queue),
          title: const Text("Aggiungi canzoni alla coda"),
          onTap: ()async{
            final songs = await dbSong.getSongsById(p.songs);
            await pl.addASongsToQueue(songs);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.play_arrow),
          title: const Text("Fai partire la playlist"),
          onTap: ()async{
            final songs = await dbSong.getSongsById(p.songs);
            await pl.loadQueue(songs, 0);

            Navigator.pop(context);
          },
        ),
      ],
    );
  });
}