import 'package:flutter/material.dart';
import 'songWidget.dart';

import 'Database.dart';
import 'Widgets_player.dart';

class Queue extends StatefulWidget{
  const Queue({super.key});
  
  @override
  State<StatefulWidget> createState() => _QueueState();
}

class _QueueState extends State<Queue>{
  
  final pl = PlayerManager();
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 40,),
          miniPlayer(audio: pl.player, expand: (){
            Navigator.pop(context);
          }),
          const SizedBox(height: 40,),
          Expanded(child:
          ReorderableListView.builder(

              itemBuilder:(context, index){
                final song = pl.queueSongs[index];

                return ListTile(
                  key: ValueKey(song.id),
                  leading: index == pl.currentIndex ? const Icon(Icons.volume_up) : Text("${index+1}"),
                  title: Text(song.Name),
                  onTap: ()async{
                    await pl.loadQueue(pl.queueSongs, index);
                    setState(() {

                    });

                  },
                  onLongPress: (){
                    songMenu(context, song, type: menuType.queue, index: index);
                    setState(() {

                    });
                  },

                );
              } , itemCount: pl.queueSongs.length,
              onReorder: (oldIndex, newIndex)async{
                if(newIndex>oldIndex){
                  newIndex--;
                }
                await pl.moveSong(oldIndex, newIndex);
            setState(() {


            });
          }),
          ),

        ],
      )

    );
  }
}