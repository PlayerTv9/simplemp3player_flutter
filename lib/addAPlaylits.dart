import 'package:flutter/material.dart';
import 'Database.dart';

class addAPlaylist extends StatefulWidget{
  final String title;
  const addAPlaylist({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _addPlaylistState();
}

class _addPlaylistState extends State<addAPlaylist>{
  final f = playlistManager();
  final textEditing = TextEditingController();
  final d = songDatabase();

  Future<void> addAPlaylist()async{
    if (textEditing.text.isNotEmpty){
      final p = PlayList(name: textEditing.text, songs: [], id: await f.createANewId());
      await f.saveNewplayList(p);
    }

  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    f.load();
  }

  Future<void> showSongsIntoAPLaylist(int pos)async{
    final pls = await f.loadPlaylist();
    final p = pls[pos];
    final songs = await d.getSongsById(p.songs);
    songs.forEach((s)=> print(s.Name));


  }

  @override
  void dispose() {
    textEditing.dispose();
    super.dispose();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: .center,
        children: [
          StreamBuilder(stream: f.playStream,
              initialData: [],

              builder: (context, snapshot){
              final playlist = snapshot.data!;
              return Column(
                children: List.generate(playlist.length, (i){
                  return TextButton(onPressed:()=>showSongsIntoAPLaylist(i) , child: Text(playlist[i].name));
                }),
              );
              }),
          Padding(padding: const EdgeInsets.all(10),
          child: TextField(
              controller: textEditing,
              decoration: InputDecoration(
                labelText: "Inserisci il titolo della playlist"
              ),
          ),)
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: addAPlaylist,
        child: const Icon(Icons.add),
      ),
    );

  }
}