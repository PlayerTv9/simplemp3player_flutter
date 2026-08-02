import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:metadata_god/src/rust/frb_generated.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';



import 'all_playlist.dart';
import 'Widgets_player.dart';
import 'Database.dart';
import 'addAPlaylits.dart';
import 'package:simplemp3pkayer/SearchPage.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final db = songDatabase();
  await db.init();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Navbar(),
    );
  }
}

class Navbar extends StatefulWidget{
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _navbarState();
}

class _navbarState extends State<Navbar>{
  int selectedIndex = 0;

  static List<Widget> widgetOptions = <Widget>[
    MyHomePage(title: "Simple MP3 Player"),
    searchPage(title: "Seach page"),
    allPlaylist(title: "All playlist"),
  ];

  void onTapped(int index){
    setState(() {
      selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
  return Scaffold(

    body: widgetOptions.elementAt(selectedIndex),
    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.blueAccent,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home", backgroundColor: Colors.indigo),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search", backgroundColor: Colors.indigo),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: "Playlist", backgroundColor: Colors.indigo)
        ],
    currentIndex: selectedIndex,
    onTap: onTapped,),
  );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isEspanded = false;
  final player = AudioPlayer();
  final db = songDatabase();
  final f = playlistManager();

  final OnAudioQuery audioQuery = OnAudioQuery();


  PlayerManager pl = PlayerManager();



  //Song? s;

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
      final audioSource = AudioSource.file(newFile.path);
      print("Path first,path: ${newFile.path}");





      //if(await db.isSongNotInserted(result.names[0]!)){
        final nSong = Song(Name: result.names[0]!, path: newFile.path,duration: 0);
        await db.insert(nSong);
        pl.queue.add(nSong);

        await pl.loadQueue(pl.queue, pl.currentIndex);

        setState(() {

        });
      //}


    }
    print(await db.getAllSongs());
  }
  void playAudio(){
    if(pl.player.playing){
      player.pause();
    }else{
      player.play();
    }


  }
  
  Future<void> selectASong(int id)async{
    final song = await db.getASongById(id);
    if (song != null){
      pl.queue.add(song);
      await pl.loadQueue(pl.queue, pl.currentIndex);
    }

    setState(() {

    });
  }

  Future<void> addPlaylist()async{
    await Navigator.push(context, MaterialPageRoute(builder: (_)=>addAPlaylist(title: "add A PLayist")));
  }
  Future<void> showPlaylistSelector(int songId)async{
    final playlists = await f.loadPlaylist();
    if(!mounted)return;
    showModalBottomSheet(context: context, builder: (context){
      return ListView.builder(
        itemCount: playlists.length,
          
          itemBuilder: (context, index){
          final playlist = playlists[index];
          return ListTile(
            title: Text(playlist.name),
            onTap: ()async{
              await f.addSongToPlaylist(playlist.name, songId);
              Navigator.pop(context);
            },

          );
          
          }
          );
    });
    
  }

  Future<void> showAddMenu()async{
    pl.queue.forEach((f)=>print(f.Name));
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
            leading: const Icon(Icons.album),
            title: const Text("Aggiungi playlist"),
            onTap: (){
              Navigator.pop(context);
              addPlaylist();
            },

          )
        ],
      ));
    });
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

    final songsType = songs.map((s) => Song(Name: s.title, path: s.data, duration: s.duration ?? 0)).toList();
    for(final s in songsType){
      print("Canzone con nome ${s.Name}! e path ${s.path}");
      if(await db.isSongNotInserted(s.Name)){
        await db.insert(s);
      }
    }


  }


  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSOngsIntoPhone();
    db.loadSong();


  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Stack(

        children: [
          /*Column(
            children: [
              TextButton(onPressed: addPlaylist, child: const Text("Agggiungi playlist")),
            ],
          ),*/
          StreamBuilder(
              stream: db.songStream,
              initialData: const[],
              builder: (context, snapshot){
                final songs = snapshot.data!;
                return Column(
                  children: List.generate(songs.length, (i){
                    return Row(
                      children: [
                        TextButton(onPressed: (){
                          selectASong(songs[i].id);
                          print("Path: ${songs[i].path}");

                        }, child: Text("${songs[i].Name} Durata: ${songs[i].duration~/60000}:${(songs[i].duration%60000)}")),
                        IconButton(onPressed: ()=>showPlaylistSelector(songs[i].id), icon: Icon(Icons.playlist_add)),
  
                    ],
                    );
                  }),
                );
              }),

          Align(
            alignment: Alignment.bottomCenter,

            child: Padding(padding: const EdgeInsets.only(bottom: 80),
            child: miniPlayer(audio: pl.player, expand: (){
              Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpandedPlayer(audio: pl.player, close: ()=>Navigator.pop(context),s:pl.currentSong)));
            },s: pl.currentSong,),)
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddMenu,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
