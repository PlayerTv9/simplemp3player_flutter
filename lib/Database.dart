import 'dart:async';
import 'dart:convert';

import 'dart:io';


import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class Song{
  final int? id;
  final String Name;
  final String? img;
  final String path;
  final int duration;
  const Song({required this.Name, required this.path,required this.duration,  this.img, this.id});

  Map<String, Object> toDict(){
    return {
      "Name": Name,
      "img": img ?? "",
      "path": path,
      "duration": duration,

    };
  }
  factory Song.fromDict(Map<String, Object?> m){
    return Song(Name: m["name"] as String, path: m["path"] as String,img: m["img"] as String, id: m["id"] as int, duration:  m["duration"] as int );
  }
}

class songDatabase{
  songDatabase._();
  static songDatabase sD = songDatabase._();
  factory songDatabase(){
    return sD;
  }
  final String tableName = "Songs";

  final StreamController<List<Song>> _controller = StreamController<List<Song>>.broadcast();

  Future<void> loadSong()async{
    final data = await getAllSongs();
    _controller.add(data);
  }

  Stream<List<Song>> get songStream => _controller.stream;


  late Database db;
  Future<void> init()async{
    db = await openDatabase(join(await getDatabasesPath(), 'database.db'),
    onCreate: (db, version){
      return db.execute('''
      CREATE TABLE IF NOT EXISTS ${tableName}(
        id INTEGER PRIMARY KEY,
        name TEXT,
        path TEXT,
        img TEXT,
        duration INTEGER
      )
      ''');
    },version: 1);
  }

  Future<int> insert(Song s)async{
    int id = await db.insert(tableName, s.toDict(),conflictAlgorithm: .replace);
    loadSong();
    return id;
  }
  Future<void> remove(int id)async{
    await db.delete(tableName, where: "id = ?",whereArgs: [id]);
    loadSong();
  }
  Future<void> update(Song s)async{
    await db.update(tableName, s.toDict(),where: "id = ?", whereArgs: [s.id!]);
    loadSong();
  }
  Future<List<Song>> getAllSongs()async{
    final m =  await db.query(tableName);
    return m.map((e){
      return Song.fromDict(e);
    }).toList();
  }
  Future<Song?> getASongById(int id)async{
    final allS = await db.query(tableName, where: "id = ?",whereArgs: [id]);
    return Song.fromDict(allS.first);
  }
  Future<bool> isSongNotInserted(String name)async{
    final allS = await db.query(tableName,where: "name = ?",whereArgs: [name]);
    return allS.isEmpty;
  }

  Future<List<Song>> getSongsById(List<int> ids)async{
    final allS = await getAllSongs();
    return allS
          .where((s)=>ids.contains(s.id))
          .toList();
  }

}

class PlayList{
  final String name;
  final List<int> songs;
  final String? img;
  final int id;

  const PlayList({required this.name, required this.songs, required this.id, this.img});
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'songs': songs,
      'img': img,
    };
  }

  factory PlayList.fromJson(Map<String, dynamic> json){
    return PlayList(name: json['name'] as String, songs: List.from(json['songs']),id: json['id'] as int, img: json['img'] as String?);
  }


}

class playlistManager{
  playlistManager._();
  static final playlistManager pl = playlistManager._();
  factory playlistManager(){
    return pl;
  }

  final StreamController<List<PlayList>> _controller = StreamController<List<PlayList>>.broadcast();

  Future<void> load()async{
    final data = await loadPlaylist();
    _controller.add(data);
  }

  Stream<List<PlayList>> get playStream => _controller.stream;


  Future<File> getFileName()async{
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/playlists.json");
  }

  Future<List<PlayList>> loadPlaylist()async{
    final file = await getFileName();
    if(!await file.exists()) return[];

    final content = await file.readAsString();
    final List<dynamic> json = jsonDecode(content);
    return json.map((e)=>PlayList.fromJson(e)).toList();
  }

  Future<void> saveNewplayList(PlayList p)async{
      final file = await getFileName();
      final playlists = await loadPlaylist();
      playlists.add(p);

      await file.writeAsString(jsonEncode(
          playlists.map((p)=>p.toJson()).toList()
      ));
      load();
  }

  Future<void> updateAPlayList(int id, PlayList p)async{
    final file = await getFileName();
    final playlists = await loadPlaylist();
    playlists[id] = p;
    await file.writeAsString(jsonEncode(
        playlists.map((p)=>p.toJson()).toList()
    ));
    load();
  }
  Future<PlayList> deleteAPLaylist(int id)async{
    final file = await getFileName();
    final playlists = await loadPlaylist();
    final p = playlists[id];
    playlists.removeAt(id);
    await file.writeAsString(jsonEncode(
        playlists.map((p)=>p.toJson()).toList()
    ));
    load();
    return p;
  }
  Future<void> removeASongFromAPLaylist(String playlistName, int songId)async{
    final playlists = await loadPlaylist();
    final i = playlists.indexWhere((p)=>p.name==playlistName);
    if(i==-1)return;

    final playlist = playlists[i];
    if(playlist.songs.contains(songId)){
      playlist.songs.remove(songId);
      await updateAPlayList(i, playlist);
    }
  }
  Future<void> addSongToPlaylist(String playlistName, int songId)async{
    final playlists = await loadPlaylist();
    final i = playlists.indexWhere((p)=>p.name==playlistName);
    if (i==-1)return;

    final playlist = playlists[i];
    if(!playlist.songs.contains(songId)){
        final newP = PlayList(name: playlist.name, songs: [...playlist.songs, songId],id:playlist.id, img: playlist.img);
        await updateAPlayList(i,newP);
      }
    }

    Future<int> createANewId()async{
      int id = 0;

      while(await isIdAlreadyUsed(id)) {
        id++;
      }

      return id;
    }

    Future<bool> isIdAlreadyUsed(int id)async{
      final ids = (await loadPlaylist()).map((p) => p.id).toList();
      return ids.contains(id);
      
      
    }

}

