import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:just_audio/just_audio.dart';

import 'Widgets_player.dart';
import 'Database.dart';

Widget image(Metadata? metadati){
  if(metadati?.picture?.data != null){
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        metadati!.picture!.data,
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

Future<Metadata?> getMetadata(String path)async{
  try{
    final m = await MetadataGod.readMetadata(file: path);
    return m;
  }catch(_){}
  return null;

}

Widget indexWidget(int? index){
  if(index == null){
    return const Text("");
  }else{
    return Text("${index+1}",style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold
    ),);
  }
}



Widget songWidget(Song s, int? index){


  return Row(
    mainAxisAlignment: .center,
    children: [
     indexWidget(index),

      FutureBuilder<Metadata?>(future:getMetadata(s.path), builder: (context,snapshot){
        return Row(
          children: [
            image(snapshot.data),
            Text(snapshot.data?.title ?? s.Name, style: TextStyle(
                fontSize: 16
            ),),

          ],
        );
      }),
     



    ],
  );
}

Future<void> showPlaylistSelector(int songId, BuildContext context)async{
  //final pl = playlistManager();
  final dbSong = songDatabase();
  final playlists = await dbSong.getAllPlaylists();
  if(!context.mounted)return;
  showModalBottomSheet(context: context, builder: (context){
    return ListView.builder(
        itemCount: playlists.length,

        itemBuilder: (context, index){
          final playlist = playlists[index];
          return ListTile(
            title: Text(playlist.name),
            onTap: ()async{
              await dbSong.addASongToAPlaylist(playlist.id!, songId);
              Navigator.pop(context);
            },

          );

        }
    );
  });

}

enum menuType{
  normal,
  queue,
  Playlist
}

void songMenu(BuildContext context, Song s, {menuType type = menuType.normal, int index=-1, int pId = -1}){
  final pl = PlayerManager();
  final dbSong = songDatabase();
  showModalBottomSheet(context: context, builder: (context){
    return Column(
      mainAxisSize: .min,
      children: [

        ListTile(
          leading: const Icon(Icons.playlist_add),
          title: const Text("Aggiungi a una playlist"),
          onTap: (){
            showPlaylistSelector(s.id!, context);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.music_off),
          title: const Text("Rimuovi dall player"),
          onTap: ()async{
            //await pDb.removeASongFromAPLaylist(widget.playList!.name, s.id!);
            await dbSong.remove(s.id!);

            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_to_queue_outlined),
          title: const Text("Aggiungi in coda"),
          onTap: ()async{
            await pl.addASongsToQueue([s]);
            Navigator.pop(context);
          },
        ),
        menuAdded(context, index, type, pId, s.id!),


      ],
    );
  });
}

Widget menuAdded(BuildContext context, int index, menuType tipo, int pId, int songId){
  if(tipo==menuType.queue){
    return ListTile(
      leading: const Icon(Icons.remove_from_queue),
      title: const Text("Rimuovi dalla coda"),
      onTap: ()async{
        Navigator.pop(context);
        final pl = PlayerManager();
        await pl.removeSongAt(index);

      },
    );
  }else if(tipo == menuType.Playlist){
    return ListTile(
      leading: const Icon(Icons.remove),
      title: const Text("Rimuovi dalla playlist"),
      onTap: ()async{
        Navigator.pop(context);
        final db = songDatabase();
        await db.removeASongFromAPlaylist(pId, songId);

      },
    );
  }
  return const Text("");
}