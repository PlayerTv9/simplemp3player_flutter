import 'package:flutter/material.dart';
import 'allSongsPage.dart';
import 'Database.dart';
import 'openPlaylistPage.dart';
import 'addAPlaylits.dart';


class allPlaylist extends StatefulWidget{
  final String title;
  const allPlaylist({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _allPlaylistState();
}

class _allPlaylistState extends State<allPlaylist>{

  final db = songDatabase();
  
  Future<void> openAPLaylists(int id)async{
    await Navigator.push(context, MaterialPageRoute(builder: (_)=>openPlayListPage(id: id,)));
  }

  Future<void> addPlaylist()async{
    await Navigator.push(context, MaterialPageRoute(builder: (_)=>addAPlaylist(title: "add A PLayist")));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    db.loadPlaylists();

  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<PlayList>>(
          stream: db.playlistStream,
          initialData: const[],
          builder: (context, snapshot){
              final playlists = snapshot.data!;
              return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: playlists.length+1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index){
                    if(index==0){
                      return Card(
                        color: Colors.blueAccent,
                        child: InkWell(
                          onTap: ()async{
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_)=>allSongPage()));
                          },
                          child: Column(
                            mainAxisAlignment: .center,
                            children: [
                              Icon(
                                Icons.library_music,
                                size: 60,
                              ),
                              const SizedBox(height: 8,),
                              Text(
                                "Tutte le canzoni",
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      );

                    }
                    final playlist = playlists[index-1];
                    return Card(
                      child: InkWell(
                        onTap: ()=>openAPLaylists(playlist.id!),
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
                  });
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: addPlaylist,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),

    );


  }
}