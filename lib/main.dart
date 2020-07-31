import 'package:flutter/material.dart';
import 'package:skible/camera_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skible',
      theme: ThemeData.dark(),
      initialRoute: "MyHomePage",
      routes: {
        "MyHomePage": (context) => MyHomePage(),
        "camera_screen": (context) => CameraScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 40, 48, 78),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            children: <Widget>[
              Image.asset(
                "assets/images/SkibleLogo.png",
                height: 150,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 38.0),
            child: Material(
              elevation: 5.0,
              color: Color.fromARGB(255, 113, 213, 159),
              borderRadius: BorderRadius.circular(30.0),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: MaterialButton(
                  onPressed: () => Navigator.pushNamed(context, "camera_screen"),
                  minWidth: 200,
                  height: 42,
                  child: Text(
                    "Start",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
