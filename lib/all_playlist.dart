import 'package:flutter/material.dart';
import 'Database.dart';
import 'openPlaylistPage.dart';


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
                  itemCount: playlists.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index){
                    final playlist = playlists[index];
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
          }));


  }
}