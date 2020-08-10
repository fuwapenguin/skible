import 'package:flutter/material.dart';
import 'dart:io';
import 'package:adv_camera/adv_camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'gallery.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:skible/UnsafeDialog.dart';
import 'package:tflite/tflite.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  String imagePath;
  bool isTorch = false;
  bool isFrontCamera = false;
  bool _canWork = true;
  bool cameraIsSwitching = false;
  AdvCameraController cameraController;
  ProgressDialog pr;

  //accuracy for the local model
  double accuracy = 0.95;

  void choiceSetting(String choice) {
    switch (choice) {
      case "no":
        break;
      case "Low":
        setState(() {
          cameraController
              .setPreviewRatio(CameraPreviewRatio.r1);
          cameraController
              .setSessionPreset(CameraSessionPreset.low);
        });
        break;
      case "Medium":
        setState(() {
          cameraController
              .setPreviewRatio(CameraPreviewRatio.r4_3);
          cameraController.setSessionPreset(
              CameraSessionPreset.medium);
        });
        break;
      case "High":
        setState(() {
          cameraController
              .setPreviewRatio(CameraPreviewRatio.r11_9);
          cameraController
              .setSessionPreset(CameraSessionPreset.high);
        });
        break;
      case "Best":
        setState(() {
          cameraController
              .setPreviewRatio(CameraPreviewRatio.r16_9);
          cameraController.setSessionPreset(
              CameraSessionPreset.photo);
        });
        break;
    }
  }

  _onCameraCreated(AdvCameraController controller) {
    this.cameraController = controller;
    this.cameraController.setFlashType(FlashType.off);
  }

  void _onSwitchCamera() {
    cameraIsSwitching = true;
    cameraController.switchCamera();
    setState(() {
      isFrontCamera = isFrontCamera ? false : true;
      if(isFrontCamera) {
        cameraController.setPreviewRatio(CameraPreviewRatio.r16_9);
        cameraController.setSessionPreset(CameraSessionPreset.photo);
        turnOnFront();
      }
      else {
        showBackCamera();
      }
    });
  }

  Future showBackCamera() {
    return new Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        cameraIsSwitching = false;
      });
    });
  }

  Future turnOnFront() {
    return new Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        cameraController.setPreviewRatio(CameraPreviewRatio.r16_9);
        cameraController.setSessionPreset(CameraSessionPreset.photo);
        cameraIsSwitching = false;
      });
    });
  }

  void _onCapturePressed(context) async {
    pr = ProgressDialog(context);
    pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);

//    await _controller.takePicture(path);
    await cameraController.captureImage();

    await pr.show();
  }

  void processCapturedImage(BuildContext context2) async {
    if(imagePath == null || imagePath == '') return;

    bool isOk;

    //Check if we have internet
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        //Google cloud model
        isOk = await runGoogleCloudModel(File(imagePath));
      }
    } on SocketException catch (_) {
    }
    finally {
      
      if(isOk == null) {
        //Local ML model
        print(imagePath);
        isOk = await runModel(imagePath);
      }

      await pr.hide();
      if (isOk) {
        setState(() {
          _canWork = true;
        });
        await GallerySaver.saveImage(imagePath);
      } else {
        setState(() {
          _canWork = true;
        });
        await showDialog(
            context: context2,
            builder: (BuildContext context) => UnsafeDialog()).then((value) {
          cameraController.setPreviewRatio(CameraPreviewRatio.r16_9);
          cameraController.setSessionPreset(CameraSessionPreset.photo);
        });
        final dir = Directory(imagePath);
        dir.deleteSync(recursive: true);
        imagePath = '';
      }

      if(isFrontCamera) {
        cameraController.setPreviewRatio(CameraPreviewRatio.r16_9);
        cameraController.setSessionPreset(CameraSessionPreset.photo);
      }

      hidePreview();
    }
  }

  Future hidePreview() {
    return new Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        imagePath = '';
      });
    });
  }

  /// Run Model on Image
  Future<bool> runGoogleCloudModel(File imageFile) async {
    bool check = true;
    String base64Image = base64Encode(imageFile.readAsBytesSync());
    // string to uri
    var uri = Uri.parse("http://getskible.com/api/getSafe.php");
    await http.post(uri, body: {
      "image": base64Image,
    }).then((value) {
      print("Google model: " + value.body);
      if(value.body == "4" || value.body == "5") {
        check = false;
      }
    }).catchError((err) {
      print(err);
    });

    return check;
  }

  /// Run Model on Image
  Future<bool> runModel(String path) async {
    //load the model
    await Tflite.loadModel(
        model: "assets/model/nsfw.tflite", labels: "assets/model/labels.txt");

    //get the result from the model
    var output = await Tflite.runModelOnImage(
      path: path,
      asynch: true,
    );

    bool check;
    //get labels
    String outLabel = "${output[0]["label"]}";
    String outAcc = "${output[0]["confidence"]}";

    double outDouble = double.parse(outAcc.substring(0, 4));

    //make decision for sfw or nsfw
    if (outLabel == "sfw" && outDouble > accuracy) {
      check = true;
    } else {
      check = false;
    }
    print("result: $check");
    return check;
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    ClipOval galeryButtonBox = ClipOval(
      child: Material(
        color: Colors.transparent, // button color
        child: InkWell(
          splashColor: Colors.grey, // inkwell color
          child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.13,
              height: MediaQuery.of(context).size.width * 0.13,
              child: FlatButton(
                child: Image.asset("assets/images/Gallery.png"),
                onPressed: null,
              )),
          onTap: () async {
            final pick = ImagePicker();
            var pciked = await pick.getImage(source: ImageSource.gallery);
            File currentFile = File(pciked.path);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Gallery(currentFile),
              ),
            );
          },
        ),
      ),
    );

    Positioned galleryButton = Positioned(
      bottom: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.12,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[

          galeryButtonBox,
          SizedBox(width: MediaQuery.of(context).size.width * 0.08),
        ]),
      ),
    );
//
    Positioned upBar = Positioned(
      top: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.12,
        color: Colors.black.withOpacity(0.6),
      ),
    );
//
    ClipOval torchButtonBox = ClipOval(
      child: Material(
        color: Colors.transparent, // button color
        child: InkWell(
          splashColor: Colors.grey, // inkwell color
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.13,
            height: MediaQuery.of(context).size.width * 0.13,
            child: FlatButton(
                child: Image.asset(isTorch ? "assets/images/FlashIcon.png" : "assets/images/FlashIconOff.png"),
                onPressed: () async {
                  setState(() {
                    if (isFrontCamera == false) {
                      if(isTorch) {
                        isTorch = false;
                        cameraController.setFlashType(FlashType.off);
                      }
                      else{
                        isTorch = true;
                        cameraController.setFlashType(FlashType.on);
                      }
                    }
                  });
                }),
          ),
        ),
      ),
    );

    Positioned torchButton = Positioned(
      top: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.12,
        child:
        Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          SizedBox(width: MediaQuery.of(context).size.width * 0.08),
          torchButtonBox,
        ]),
      ),
    );
//
    ClipOval switchButtonBox = ClipOval(
      child: Material(
        color: Colors.transparent, // button color
        child: InkWell(
          splashColor: Colors.grey, // inkwell color
          child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.13,
              height: MediaQuery.of(context).size.width * 0.13,
              child: FlatButton(
                child: Image.asset("assets/images/SwitchCamera.png"),
                onPressed: null,
              )
          ),
          onTap: () {
            _onSwitchCamera();
          },
        ),
      ),
    );

    Positioned switchButton = Positioned(
      bottom: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.12,
        child:
        Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          SizedBox(width: MediaQuery.of(context).size.width * 0.08),
          switchButtonBox,
        ]),
      ),
    );
//
    Positioned downBar = Positioned(
      bottom: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.12,
        color: Colors.black.withOpacity(0.6),
      ),
    );

    PopupMenuButton<String> popupSettings = PopupMenuButton<String>(
        child: FlatButton(
          child: Image.asset("assets/images/Settings.png"),
          onPressed: null,
        ),
        onSelected: choiceSetting,
        itemBuilder: (BuildContext context) {
          var list = List<PopupMenuEntry<String>>();
          list.add(
            PopupMenuItem(
              child: Text("Setting Resolution"),
              value: "no",
            ),
          );
          list.add(
            PopupMenuDivider(
              height: 10,
            ),
          );
          list.add(
            PopupMenuItem(
              child: Text(
                "Low",
                style: TextStyle(color: Colors.white),
              ),
              value: "Low",
            ),
          );
          list.add(
            PopupMenuItem(
              child: Text(
                "Medium",
                style: TextStyle(color: Colors.white),
              ),
              value: "Medium",
            ),
          );
          list.add(
            PopupMenuItem(
              child: Text(
                "High",
                style: TextStyle(color: Colors.white),
              ),
              value: "High",
            ),
          );
          list.add(
            PopupMenuItem(
              child: Text(
                "Best",
                style: TextStyle(color: Colors.white),
              ),
              value: "Best",
            ),
          );
          return list;
        });

    ClipOval settingButtonBox = ClipOval(
      child: Material(
        color: Colors.transparent, // button color
        child: InkWell(
          splashColor: Colors.grey, // inkwell color
          child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.13,
              height: MediaQuery.of(context).size.width * 0.13,
              child: popupSettings),
        ),
      ),
    );

    Positioned settingButton = Positioned(
      top: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.12,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
          settingButtonBox,
          SizedBox(width: MediaQuery.of(context).size.width * 0.08),
        ]),
      ),
    );
//
    ClipOval captureButtonBox = ClipOval(
      child: Material(
        color: Colors.transparent, // button color
        child: InkWell(
          splashColor: Colors.grey, // inkwell color
          child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.28,
              height: MediaQuery.of(context).size.width * 0.28,
              child: Image.asset("assets/images/Logo.png")),
          onTap: () async {
            _onCapturePressed(context);
          },
        ),
      ),
    );

    Positioned captureButton = Positioned(
      bottom: 0.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              captureButtonBox,
            ]),
            SizedBox(height: 10)
          ],
        ),
      ),
    );

    Stack firstViewStack = Stack(children: <Widget>[
      SizedBox(
        height: size.height,
        width: size.width,
        child: RotatedBox(
          quarterTurns: isFrontCamera ? 1 : 0,
          child: Center(
            child: AdvCamera(
              cameraSessionPreset: CameraSessionPreset.photo,
              onCameraCreated: _onCameraCreated,
              onImageCaptured: (String path) {
                if (this.mounted) {
                  setState(() {
                    imagePath = path;
                    processCapturedImage(context);
                  });
                }
              },
              cameraPreviewRatio: CameraPreviewRatio.r16_9,
            ),
          ),
        ),
      ),
      cameraIsSwitching ? SizedBox(
        height: size.height,
        width: size.width,
        child: Material(
          color: cameraIsSwitching ? Colors.black : Colors.transparent,
        ),
      ) : SizedBox(height: 0, width: 0,),
      upBar,
      torchButton,
      settingButton,
      downBar,
      switchButton,
      captureButton,
      galleryButton,

      Positioned(
        bottom: 100.0,
        left: 16.0,
        child: imagePath != null
            ? Container(
          width: 100.0,
          height: 100.0,
          child: imagePath != "" ? Image.file(File(imagePath))
              : Icon(
            Icons.image,
            color: Colors.transparent,
          ),
        )
            : Icon(
          Icons.image,
          color: Colors.transparent,
        ),
      ),
    ]);

    Scaffold firstView = Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // here the desired height
          child: AppBar(
            backgroundColor: Colors.black,
          ),
        ),
        body: firstViewStack);

    return firstView;
  }
}
