import 'package:flutter/material.dart';
import 'Widgets_player.dart';
import 'songWidget.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


import 'Database.dart';

class FavoritesSong extends StatefulWidget{
  const FavoritesSong({super.key});

  @override
  State<FavoritesSong> createState() => _FavoritesSongState();
}

class _FavoritesSongState extends State<FavoritesSong>{

  final db = songDatabase();
  final pl = PlayerManager();

  final OnAudioQuery audioQuery = OnAudioQuery();







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
        title: const Text("Canzoni favorite"),
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
            child:FutureBuilder<List<Song>>(
              future: db.getAllFavoritesSongs(),
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

      bottomNavigationBar:  miniPlayer(audio: pl.player, expand: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpandedPlayer(audio: pl.player, close: ()=>Navigator.pop(context),s:pl.currentSong)));
      },s: pl.currentSong,),
    );
  }
}