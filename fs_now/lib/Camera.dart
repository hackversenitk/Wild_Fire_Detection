import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String model;

  Camera(this.cameras, this.model);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }

        controller.startImageStream((CameraImage img) async {
          if (!isDetecting) {
            isDetecting = true;

            int startTime = new DateTime.now().millisecondsSinceEpoch;

            Tflite.detectObjectOnFrame(
              // asynch: true,
              bytesList: img.planes.map((plane) {
                return plane.bytes;
              }).toList(),
              model: "image_classifier",
              // imageHeight: img.height,
              // imageWidth: img.width,
            ).then((recognitions) async {
              print(recognitions);
              try {
                Position position = await Geolocator()
                    .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                await http.patch("https://fsnow-516.firebaseio.com/NITK.json",
                    body:
                        '''{"Lat":${position.latitude},"Long":${position.longitude}}''').then(
                    (onValue) {
                  print(onValue.body);
                });
              } catch (e) {
                print(e);
              }
              int endTime = new DateTime.now().millisecondsSinceEpoch;
              print("Detection took ${endTime - startTime}");

              isDetecting = false;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }
}
