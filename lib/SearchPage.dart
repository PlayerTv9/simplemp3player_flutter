import 'package:flutter/material.dart';
import 'package:simplemp3pkayer/Widgets_player.dart';
import 'Database.dart';
import 'songWidget.dart';
import 'openPlaylistPage.dart';


class searchPage extends StatefulWidget{
  final String title;
  const searchPage({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _searchPageState();
}

class _searchPageState extends State<searchPage>{

final pl = PlayerManager();
final controller = TextEditingController();

 List<Song> songSearched = [];
 List<PlayList> playlistSearched = [];
 List<PlayList> allPlaylist = [];
 List<Song> allSongs = [];
 final dbSong = songDatabase();
 final dbPlaylist = playlistManager();

 Future<void> load()async{
   allSongs = await dbSong.getAllSongs();
   allPlaylist = await dbPlaylist.loadPlaylist();

   if(mounted){
     setState(() {

     });
   }
 }

Future<void> searchListener()async{
  final txt = controller.text.trim().toLowerCase();

  if(txt.isEmpty){
    setState(() {
      songSearched.clear();
      playlistSearched.clear();

    });
    return;
  }


  songSearched = allSongs.where((s)=>s.Name.toLowerCase().contains(txt)).toList();
   playlistSearched = allPlaylist.where((p)=>p.name.toLowerCase().contains(txt)).toList();

   setState(() {

   });
}

Future<void> showPlaylistSelector(int songId)async{
  final playlists = await dbPlaylist.loadPlaylist();
  if(!mounted)return;
  showModalBottomSheet(context: context, builder: (context){
    return ListView.builder(
        itemCount: playlists.length,

        itemBuilder: (context, index){
          final playlist = playlists[index];
          return ListTile(
            title: Text(playlist.name),
            onTap: ()async{
              await dbPlaylist.addSongToPlaylist(playlist.name, songId);
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
          leading: const Icon(Icons.playlist_add),
          title: const Text("Aggiungi a una playlist"),
          onTap: (){
            showPlaylistSelector(s.id!);
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
            pl.queue.add(s);
            pl.loadQueue(pl.queue, 0);
          },
        )

      ],
    );
  });
}

Widget songsWidget(){
  if(songSearched.isNotEmpty){
    return Column(
      children: List.generate(songSearched.length, (index){
        return  InkWell(
          onTap: ()async{
            pl.queue.clear();
            pl.queue.add(songSearched[index]);
            pl.loadQueue(pl.queue, 0);

            setState(() {

            });

          },
          onLongPress: (){
            songMenu(context, songSearched[index]);
            setState(() {

            });
          },
          child: songWidget(songSearched[index],null),
        );
      })


    );




  }
  return const Text("");
}

Future<void> openAPLaylists(PlayList p, int id)async{
  await Navigator.push(context, MaterialPageRoute(builder: (_)=>openPlayListPage(playList: p,id: id,)));
}

Widget playlistsWidget(){
  if(playlistSearched.isNotEmpty){
    return Column(
      children:
        List.generate(
            playlistSearched.length,
           (index){
              final playlist = allPlaylist.firstWhere((p)=>p == playlistSearched[index]);
              int correctIndex = allPlaylist.indexOf(playlist);

                  return Card(
                      child: InkWell(
                        onTap: ()=>openAPLaylists(playlistSearched[index], correctIndex),
                        child: Column(
                          mainAxisAlignment: .center,
                          children: [
                            Icon(
                              Icons.queue_music,
                              size: 60,
                            ),
                            const SizedBox(height: 8,),
                            Text(
                              playlist.name,
                              textAlign: TextAlign.center,
                            )
                          ],
                        ),
                      ),
                    );



            })

    );
  }
  return const Text("");
}

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.addListener(searchListener);
    load();

  }



  @override
  void dispose() {

    super.dispose();
    controller.dispose();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsetsGeometry.all(10), child: SearchBar(
              hintText: "Inserisci la canzone/playlist da cercare...",
              controller: controller,
            ),),

            Expanded(child: ListView(
              children: [
                songsWidget(),
                const SizedBox(height: 20,),
                playlistsWidget(),
              ]

            )),



          ],
        )
    ),



    bottomNavigationBar:  miniPlayer(audio: pl.player, expand: (){
      Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpandedPlayer(audio: pl.player, close: ()=>Navigator.pop(context),s:pl.currentSong)));
    },s: pl.currentSong,),
    );


  }
}