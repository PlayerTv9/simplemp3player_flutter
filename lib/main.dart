import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import 'package:metadata_god/src/rust/frb_generated.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:uri_content/uri_content.dart';
import 'dart:io';
import 'dart:math';



import 'all_playlist.dart';
import 'Widgets_player.dart';
import 'Database.dart';
import 'addAPlaylits.dart';
import 'SearchPage.dart';
import 'songWidget.dart';
import 'openPlaylistPage.dart';
import 'playlistMenu.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final db = songDatabase();
  await db.init();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tommaso.simplemp3player.channel.audio',
    androidNotificationChannelName: 'audio playback',
    androidNotificationOngoing: true
  );

  await initIncomingAudioFiles();



  runApp(const MyApp());
}

Future<void> initIncomingAudioFiles()async{
  final appLinks = AppLinks();
  appLinks.getInitialLink().then((uri)async{
    if(uri != null){
      await playExternalFile(uri);
    }
  });
  appLinks.uriLinkStream.listen((uri)async{
    await playExternalFile(uri);
  });
}

Future<void> playExternalFile(Uri filePath)async{
  final pl = PlayerManager();
  IOSink? outputStream;
  print("Path importato: $filePath");
  try{

    //final newSOng = Song(Name: filePath.pathSegments.last, path: "", duration: 0);


    /*final audioSource = AudioSource.uri(filePath,tag: MediaItem(
          id: filePath.toString(),
          title: filePath.pathSegments.last,
          artist: "Autore sconosciuto",
          album: "--",
          duration: Duration(milliseconds: 0),

      )

      );

      await pl.player.addAudioSource(audioSource);*/

    final uriContent = UriContent();

    final tempDir = await getTemporaryDirectory();

    final trackName = filePath.pathSegments.last.isNotEmpty ? filePath.pathSegments.last : "Audio Esterno";

    String path = "${tempDir.path}/$trackName.mp3";
    File tempFile = File(path);

    Stream<List<int>> inputStream = uriContent.getContentStream(filePath);

    outputStream = tempFile.openWrite();

    await for(final chunk in inputStream){
      outputStream.add(Uint8List.fromList(chunk));
    }

    await outputStream.flush();
    await outputStream.close();

    final checksum = await calculateChecksum(tempFile.path);


    final newSong = Song(Name: trackName, path: tempFile.path, duration: 0, checkSum: checksum);


    await pl.addASongsToQueue([newSong]);








  }catch(e){
    outputStream?.close();
    print("Errore apertura del file $e");
  }

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
  final homeElementsUtility = recommadedELementsUtility();
  List<int> songs = [];
  List<int> playlists = [];
  bool isLoading = true;
  //final f = playlistManager();





  PlayerManager pl = PlayerManager();



  //Song? s;



  
  Future<void> selectASong(int id)async{
    final song = await db.getASongById(id);
    if (song != null){
      pl.queueSongs.add(song);
      await pl.loadQueue(pl.queueSongs, pl.currentIndex);
    }

    setState(() {

    });
  }


  Future<void> showPlaylistSelector(int songId)async{
    final playlists = await db.getAllPlaylists();
    if(!mounted)return;
    showModalBottomSheet(context: context, builder: (context){
      return ListView.builder(
        itemCount: playlists.length,
          
          itemBuilder: (context, index){
          final playlist = playlists[index];
          return ListTile(
            title: Text(playlist.name),
            onTap: ()async{
              await db.addASongToAPlaylist(playlist.id!, songId);
              Navigator.pop(context);
            },

          );
          
          }
          );
    });
    
  }

  Future<homeElements> getElements()async{
    final el = await homeElementsUtility.loadElements();
    if(el == null || el.time_record.difference(DateTime.now()) > Duration(days: 1)){
      final allSongs = (await db.getAllSongs()).map((s)=>s.id!).toList();
      final allPlaylists = (await db.getAllPlaylists()).map((p)=>p.id!).toList();
      allSongs.shuffle(Random());
      allPlaylists.shuffle(Random());
      setState(() {
        songs = allSongs.sublist(0,min(6,allSongs.length));
        playlists = allPlaylists.sublist(0,min(6, allPlaylists.length));
        isLoading = false;
      });

      final newHomeElem = homeElements(
          recom_playlist: playlists,
          recom_songs: songs,
          time_record: DateTime.now());
      await homeElementsUtility.saveElements(newHomeElem);
      return newHomeElem;

    }
    setState(() {
      songs = el.recom_songs;
      playlists = el.recom_playlist;
      isLoading = false;
    });
    return el;
  }

  Future<void> openAPLaylists(int id)async{
    await Navigator.push(context, MaterialPageRoute(builder: (_)=>openPlayListPage(id: id,)));
  }

  Widget coverImage(String path){
    final file = File(path);
    if(path != "" && file.existsSync()){
      return ClipRRect(
          borderRadius: .circular(16),
    child: Image.memory(
    file.readAsBytesSync(),
    width: 60,
    height: 60,
    fit: .cover,
    )
    );
    }else{
    return Icon(
    Icons.queue_music,
    size: 60,
    );
    }
  }



  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //getSOngsIntoPhone();
    db.loadSong();
    db.loadPlaylists();
    getElements();
    //initIncomingAudioFiles();


  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Column(

        children: [
          if(isLoading)CircularProgressIndicator(),
          Expanded(child:
          FutureBuilder<List<Song>>(future: db.getSongsById(songs),
              builder: (context, snapshot){
                if(snapshot.connectionState == ConnectionState.waiting)return CircularProgressIndicator();
                if(!snapshot.hasData || snapshot.data!.isEmpty){
                  return const Text("La playlist è ancora vuota!");
                }
                if(snapshot.hasError){
                  return Text(snapshot.error.toString());
                }
                final songsElements = snapshot.data!;

                return GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: songsElements.length,

                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                    ),
                    itemBuilder: (context, index){
                      final song = songsElements[index];
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
                        child: songWidget(song,null),
                      );
                    });

              })),



        Expanded(child: FutureBuilder<List<PlayList>>(future: db.getPlaylistsById(playlists),
                builder: (context, snapshot){
                  if(snapshot.connectionState == ConnectionState.waiting)return CircularProgressIndicator();
                  if(!snapshot.hasData || snapshot.data!.isEmpty){
                    return const Text("La playlist è ancora vuota!");
                  }
                  if(snapshot.hasError){
                    return Text(snapshot.error.toString());
                  }
                  final elements = snapshot.data!;
                  return SizedBox(
                    height: 64,
                    child: ListView.builder(
                        itemCount: elements.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context,index){
                          final playlist = elements[index];
                          return Container(
                            height: 120,
                            width: 120,
                            margin: const EdgeInsets.all(8.0),
                            child: Card(
                              child: InkWell(
                                onTap: ()=>openAPLaylists(playlist.id!),
                                child: Column(
                                  mainAxisAlignment: .center,
                                  children: [
                                    coverImage(playlist.img ?? ""),
                                    const SizedBox(height: 8,),
                                    Text(
                                      playlist.name,
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                                onLongPress: (){
                                  playlistMenu(context, playlist);
                                },
                              ),
                            ),
                          );
                        }
                    ),
                  );
                }),
          )



        ],
      ),
      bottomNavigationBar: miniPlayer(audio: pl.player, expand: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>ExpandedPlayer(audio: pl.player, close: ()=>Navigator.pop(context),s:pl.currentSong)));
      },s: pl.currentSong,),

    );
  }
}
