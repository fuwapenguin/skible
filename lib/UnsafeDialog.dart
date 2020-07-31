import 'dart:ui';

import 'package:flutter/material.dart';

class UnsafeDialog extends StatelessWidget {

  void closeDialog(context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  "assets/images/Warning.png",
                  height: 50,
                ),
                SizedBox(
                  height: 25,
                ),
                Text(
                  "This image contains no secure content. It will not be saved!",
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 25,
                ),
                Material(
                  elevation: 5.0,
                  color: Color.fromARGB(255, 113, 213, 159),
                  borderRadius: BorderRadius.circular(30.0),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: MaterialButton(
                      onPressed: () => closeDialog(context),
                      minWidth: 200,
                      height: 42,
                      child: Text(
                        "Ok",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
