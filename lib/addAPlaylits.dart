import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'Database.dart';

class addAPlaylist extends StatefulWidget{
  final String title;
  const addAPlaylist({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _addPlaylistState();
}

class _addPlaylistState extends State<addAPlaylist>{
  final db = songDatabase();
  final textEditing = TextEditingController();
  final d = songDatabase();
  String btnText = "Seleziona un'immagine da mettere come copertina dell'album";
  String pathImg = "";

  Future<void> addAPlaylist()async{
    if (textEditing.text.isNotEmpty){
      final p = PlayList(name: textEditing.text, songs: [], img: pathImg);
      await db.addAPlaylist(p);
    }

  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    db.loadPlaylists();
  }

  Future<void> showSongsIntoAPLaylist(int id)async{
    final p = await db.getAPlaylistById(id);

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
          StreamBuilder<List<PlayList>>(stream: db.playlistStream,
              initialData: [],

              builder: (context, snapshot){
              final playlist = snapshot.data!;
              return Column(
                children: List.generate(playlist.length, (i){
                  final p = playlist[i];
                  return TextButton(onPressed:()=>showSongsIntoAPLaylist(p.id!) , child: Text(playlist[i].name));
                }),
              );
              }),
          Padding(padding: const EdgeInsets.all(10),
          child: TextField(
              controller: textEditing,
              decoration: InputDecoration(
                labelText: "Inserisci il titolo della playlist"
              ),
          ),),
          Padding(padding: const EdgeInsets.all(10),
            child: TextButton.icon(onPressed: ()async{
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

            }, label: Text(btnText), icon: Icon(Icons.image),),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: addAPlaylist,
        child: const Icon(Icons.add),
      ),
    );

  }
}