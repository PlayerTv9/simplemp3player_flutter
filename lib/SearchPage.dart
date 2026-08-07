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



Widget songsWidget(){
  if(songSearched.isNotEmpty){
    return Column(
      children: List.generate(songSearched.length, (index){
        return  InkWell(
          onTap: ()async{
            pl.queueSongs.clear();
            pl.queueSongs.add(songSearched[index]);
            pl.loadQueue(pl.queueSongs, 0);

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