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
  final bool isInFavorites;
  const Song({required this.Name, required this.path,required this.duration,  required this.checkSum,this.isInFavorites=false, this.id,});

  Map<String, Object> toDict(){
    return {
      "Name": Name,
      "checksum": checkSum,
      "path": path,
      "duration": duration,
      "isInFavorites": !isInFavorites ? 0 : 1

    };
  }
  factory Song.fromDict(Map<String, Object?> m){
    return Song(Name: m["name"] as String, path: m["path"] as String,checkSum: m["checksum"] as String, id: m["id"] as int, duration:  m["duration"] as int,
        isInFavorites: (m["isInFavorites"] as int == 0 ? false : true) );
  }

  Song changeFavorites(bool value){
    return Song(Name: Name, path: path, duration: duration, checkSum: checkSum, id: id, isInFavorites: value);
  }

  @override
  String toString() {
    // TODO: implement toString
    return "Nome: $Name, path: $path, duration: $duration, checksum: $checkSum, isFavorites: $isInFavorites";
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
        duration INTEGER,
        isInFavorites INTEGER
      );
     
      
      ''');
      await db.execute('''
       CREATE TABLE IF NOT EXISTS ${playlistTableName}(
        id INTEGER PRIMARY KEY,
        name TEXT,
        songs TEXT,
        img TEXT,
        isPinned INTEGER
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
    List<Song> songs = [];
    for(final id in ids){
      final s = await getASongById(id);
      if(s!=null) songs.add(s);
    }
    return songs;
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

  Future<List<Song>> getAllFavoritesSongs()async{
    final m = await db.query(tableName, where: "isInFavorites = ?", whereArgs: [1]);
    return m.map((m)=>Song.fromDict(m)).toList();
  }





}

class PlayList{
  final String name;
  final List<int> songs;
  final String? img;
  final int? id;
  final bool isPinned;

  const PlayList({required this.name, required this.songs,this.isPinned=false, this.id, this.img});
  Map<String, dynamic> toJson(){
    return {
      'name': name,
      'songs': songs.join(','),
      'img': img,
      "isPinned": !isPinned ? 0 : 1
    };
  }

  factory PlayList.fromJson(Map<String, dynamic> json){
	final songsString = json['songs'] as String;
    return PlayList(name: json['name'] as String,
        songs:songsString.isEmpty ? [] :  songsString.split(',').map((i)=>int.parse(i)).toList(),
        id: json['id'] as int, img: json['img'] as String?, isPinned: json["isPinned"] as int == 0 ? false : true);
  }


}



Future<String> calculateChecksum(String filePath)async{
  final file = File(filePath);

  if(!await file.exists()){
    throw Exception("Il file con path $filePath non esiste");
  }

  final digest = await sha256.bind(file.openRead()).first;

  return digest.toString();

}

