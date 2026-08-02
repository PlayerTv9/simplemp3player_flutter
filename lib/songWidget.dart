import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:just_audio/just_audio.dart';

import 'Database.dart';

Widget image(Metadata? metadati){
  if(metadati?.picture?.data != null){
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        metadati!.picture!.data,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(
      Icons.music_note,
      size: 20,
    ),
  );
}

Future<Metadata?> getMetadata(String path)async{
  try{
    final m = await MetadataGod.readMetadata(file: path);
    return m;
  }catch(_){}
  return null;

}

Widget indexWidget(int? index){
  if(index == null){
    return const Text("");
  }else{
    return Text("${index+1}",style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold
    ),);
  }
}



Widget songWidget(Song s, int? index){
  final audio = AudioPlayer();

  return Row(
    mainAxisAlignment: .center,
    children: [
     indexWidget(index),

      FutureBuilder<Metadata?>(future:getMetadata(s.path), builder: (context,snapshot){
        return Row(
          children: [
            image(snapshot.data),
            Text(snapshot.data?.title ?? s.Name, style: TextStyle(
                fontSize: 16
            ),),

          ],
        );
      }),
      FutureBuilder(future: audio.setAudioSource(AudioSource.file(s.path)), builder: (context, snapshot){
        if(snapshot.hasError){
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error,
              size: 20,
            ),
          );
        }
        return const Text("");
      })



    ],
  );
}