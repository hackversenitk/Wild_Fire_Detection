import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fs_now/HomePage.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;
String _model = "";

loadModel() async {
  _model = await Tflite.loadModel(
    model: "assets/yolov2_tiny.tflite",
    labels: "assets/yolov2_tiny.txt",
    numThreads: 2,
  );
}

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
    await loadModel();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NFS',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(cameras, _model),
      // home: Container(),
    );
  }
}
