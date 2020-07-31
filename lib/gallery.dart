import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_screen.dart';

//this Widget shows the image after picking it from gallery

class Gallery extends StatefulWidget {
  File currentFile;
  Gallery(this.currentFile);
  @override
  _GalleryState createState() => _GalleryState(currentFile);
}

class _GalleryState extends State<Gallery> {
  _GalleryState(this.currentFile);
  File currentFile;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Container(width: MediaQuery.of(context).size.width,height:MediaQuery.of(context).size.height,
        color:Colors.black,
        child: Image.file(currentFile),),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 56.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[

              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white,),
                onPressed: _goBack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _goBack() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(),
      ),
    );
  }



}