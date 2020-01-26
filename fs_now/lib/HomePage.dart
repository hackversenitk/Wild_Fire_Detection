import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fs_now/Camera.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String model;

  HomePage(this.cameras,this.model);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    print(widget.model);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: Camera(
        widget.cameras,
        widget.model,
      ),
    );
  }
}
