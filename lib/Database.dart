import 'dart:async';
import 'dart:convert';

import 'dart:io';


import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class Song{
  final int? id;
  final String Name;
  final String path;
  final int duration;
  final String checkSum;
  const Song({required this.Name, required this.path,required this.duration,  required this.checkSum, this.id});

  Map<String, Object> toDict(){
    return {
      "Name": Name,
      "checksum": checkSum,
      "path": path,
      "duration": duration,

    };
  }
  factory Song.fromDict(Map<String, Object?> m){
    return Song(Name: m["name"] as String, path: m["path"] as String,checkSum: m["checksum"] as String, id: m["id"] as int, duration:  m["duration"] as int );
  }

  @override
  String toString() {
    // TODO: implement toString
    return "Nome: $Name, path: $path, duration: $duration, checksum: $checkSum";
  }
}

class songDatabase{
  songDatabase._();
  static songDatabase sD = songDatabase._();
  factory songDatabase(){
    return sD;
  }
  final String tableName = "Songs";
  final String playlistTableName = "Playlists";

  final StreamController<List<Song>> _controller = StreamController<List<Song>>.broadcast();
  final StreamController<List<PlayList>> _controllerPlaylist = StreamController<List<PlayList>>.broadcast();

  Future<void> loadSong()async{
    final data = await getAllSongs();
    _controller.add(data);
  }

  Future<void> loadPlaylists()async{
    final data = await getAllPlaylists();
    _controllerPlaylist.add(data);
  }

  Stream<List<Song>> get songStream => _controller.stream;
  Stream<List<PlayList>> get playlistStream => _controllerPlaylist.stream;

  late Database db;
  Future<void> init()async{
    db = await openDatabase(join(await getDatabasesPath(), 'database.db'),
    onCreate: (db, version)async{
      await db.execute('''
      CREATE TABLE IF NOT EXISTS ${tableName}(
        id INTEGER PRIMARY KEY,
        name TEXT,
        path TEXT,
        checksum TEXT,
        duration INTEGER
      );
     
      
      ''');
      await db.execute('''
       CREATE TABLE IF NOT EXISTS ${playlistTableName}(
        id INTEGER PRIMARY KEY,
        name TEXT,
        songs TEXT,
        img TEXT
      );
      
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
  Future<bool> isSongNotInserted(String checksum)async{
    final allS = await db.query(tableName,where: "checksum = ?",whereArgs: [checksum]);
    return allS.isEmpty;
  }

  Future<List<Song>> getSongsById(List<int> ids)async{
    final allS = await getAllSongs();
    return allS
          .where((s)=>ids.contains(s.id))
          .toList();
  }

  Future<List<PlayList>> getAllPlaylists()async{
    final m = await db.query(playlistTableName);

    return m.map((p)=>PlayList.fromJson(p)).toList();
  }

  Future<int> addAPlaylist(PlayList p)async{
    int id = await db.insert(playlistTableName, p.toJson());
    loadPlaylists();
    return id;
  }

  Future<void> removeAPlaylist(int id)async{
    await db.delete(playlistTableName, where: "id = ?", whereArgs: [id]);
    loadPlaylists();
  }

  Future<void> updateAPlaylist(PlayList p)async{
    if(p.id == null) return;

    await db.update(playlistTableName,p.toJson(), where: "id = ?", whereArgs: [p.id]);
    loadPlaylists();

  }
  Future<PlayList> getAPlaylistById(int id)async{
    final allP = await db.query(playlistTableName, where: "id = ?", whereArgs: [id]);
    return PlayList.fromJson(allP.first);
  }
  Future<void> addASongToAPlaylist(int pId, int songId)async{
    final playlist = await getAPlaylistById(pId);
    if(playlist.songs.contains(songId))return;
    final newP = PlayList(name: playlist.name, songs: [...playlist.songs, songId], img: playlist.img, id: playlist.id);
    await updateAPlaylist(newP);
  }

  Future<void> removeASongFromAPlaylist(int pId, int songId)async{
    final playlist = await getAPlaylistById(pId);
    if(!playlist.songs.contains(songId))return;
    final newP = PlayList(name: playlist.name, songs: playlist.songs.where((id)=>id!=songId).toList(), img: playlist.img, id: playlist.id);
    await updateAPlaylist(newP);
  }





}

class PlayList{
  final String name;
  final List<int> songs;
  final String? img;
  final int? id;

  const PlayList({required this.name, required this.songs, this.id, this.img});
  Map<String, dynamic> toJson(){
    return {
      'name': name,
      'songs': songs.join(','),
      'img': img,
    };
  }

  factory PlayList.fromJson(Map<String, dynamic> json){
	final songsString = json['songs'] as String;
    return PlayList(name: json['name'] as String,
        songs:songsString.isEmpty ? [] :  songsString.split(',').map((i)=>int.parse(i)).toList(),
        id: json['id'] as int, img: json['img'] as String?);
  }


}

/*class playlistManager{
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

}*/

Future<String> calculateChecksum(String filePath)async{
  final file = File(filePath);

  if(!await file.exists()){
    throw Exception("Il file con path $filePath non esiste");
  }

  final digest = await sha256.bind(file.openRead()).first;

  return digest.toString();

}

