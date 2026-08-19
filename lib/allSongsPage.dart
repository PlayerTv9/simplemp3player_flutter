import 'package:flutter/material.dart';
import 'Widgets_player.dart';
import 'songWidget.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


import 'Database.dart';

class allSongPage extends StatefulWidget{
  const allSongPage({super.key});

  @override
  State<allSongPage> createState() => allSongsState();
}

class allSongsState extends State<allSongPage>{

  final db = songDatabase();
  final pl = PlayerManager();

  final OnAudioQuery audioQuery = OnAudioQuery();

  Future<void> pickAMusicFile ()async{
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if(result!=null){
      final file = File(result.files.single.path!);

      final dir = await getApplicationDocumentsDirectory();

      final newFile = await file.copy(
          "${dir.path}/${result.files.single.name}"
      );


      print(result.paths[0]);

      print("Path first,path: ${newFile.path}");

      final checkSum = await calculateChecksum(newFile.path);





      //if(await db.isSongNotInserted(result.names[0]!)){
      final nSong = Song(Name: result.names[0]!, path: newFile.path,duration: 0, checkSum: checkSum);
      await db.insert(nSong);


      await pl.addASongsToQueue([nSong]);

      setState(() {

      });
      //}


    }
    print(await db.getAllSongs());
  }

  Future<void> getSOngsIntoPhone()async{


    bool permission = await audioQuery.permissionsRequest();
    print("Richiesta permesso audioQuery: $permission}");
    bool status = await audioQuery.permissionsStatus();
    print("status audioQuery: $status}");
    if(!status){
      permission = await audioQuery.permissionsRequest();
      print("Richiesta permesso audioQuery: $permission}");
    }
    status = await audioQuery.permissionsStatus();
    print("status audioQuery: $status}");
    if (!await audioQuery.permissionsStatus())return;

    final songs = await audioQuery.querySongs();
    print("Numero di canzoni: ${songs.length}");

    final songsType = await Future.wait(songs.map((s)async{
      return Song(Name: s.title, path: s.data, duration: s.duration ?? 0, checkSum: await calculateChecksum(s.data));
    }));
    for(final s in songsType){
      print(s.toString());
      if(await db.isSongNotInserted(s.checkSum)){
        await db.insert(s);
      }
    }


  }

  Future<void> showAddMenu()async{
    pl.queueSongs.forEach((f)=>print(f.Name));
    showModalBottomSheet(context: context, builder: (context){
      return SafeArea(child: Column(
        mainAxisSize: .min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("Agiungi canzone"),
            onTap: (){
              Navigator.pop(context);
              pickAMusicFile();
            },
          ),

          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text("Sincoranizza con la cartella 'music' del dispositivo"),
            onTap: (){
              Navigator.pop(context);
              getSOngsIntoPhone();
            },
          )
        ],
      ));
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    db.loadSong();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutte le canzoni"),
      ),
      body: Column(
        children: [
          // -------------------------------------------------------------
          // 1. INSERISCI QUI LA ROBA CHE VUOI AGGIUNGERE SOPRA
          // -------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Esempio: Riproduci casuale
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text("Riproduci Casuale"),
                ),
                Text(
                  "Totale elementi",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const Divider(height: 1), // Una linea di separazione facoltativa

          // -------------------------------------------------------------
          // 2. LA LISTA DELLE CANZONI (AVVOLTA IN EXPANDED)
          // -------------------------------------------------------------
          Expanded(
            child: StreamBuilder<List<Song>>(
              stream: db.songStream,
              initialData: const [],
              builder: (context, snapshot) {
                final songs = snapshot.data ?? [];

                if (songs.isEmpty) {
                  return const Center(
                    child: Text("Nessuna canzone disponibile"),
                  );
                }

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, i) {
                    final song = songs[i];
                    return InkWell(
                      onTap: () async {
                        pl.queueSongs.clear();
                        pl.queueSongs.add(song);
                        await pl.loadQueue(pl.queueSongs, 0);
                        setState(() {});
                      },
                      onLongPress: () {
                        songMenu(context, song);
                        setState(() {});
                      },
                      child: songWidget(song, i),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddMenu,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: .endFloat,
      bottomNavigationBar:  miniPlayer(audio: pl.player, expand: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpandedPlayer(audio: pl.player, close: ()=>Navigator.pop(context),s:pl.currentSong)));
      },s: pl.currentSong,),
    );
  }
}