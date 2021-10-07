import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:object_detection_practice/main.dart';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? cameraController;
  CameraImage? imgCamera;
  bool isWorking = false;
  double imgHeight = 0;
  double imgWidth = 0;
  List<dynamic>? recognitionList;

  initCamera() {
    cameraController = CameraController(
      cameras![0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
              if (!isWorking)
                {
                  isWorking = true,
                  imgCamera = imageFromStream,
                  runModelOnStreamFrame(),
                }
            });
      });
    });
  }

  runModelOnStreamFrame() async {
    imgHeight = imgCamera!.height + 0.0;
    imgWidth = imgCamera!.width + 0.0;
    recognitionList = await Tflite.detectObjectOnFrame(
      bytesList: imgCamera!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      model: "SSDMobileNet",
      imageHeight: imgCamera!.height,
      imageWidth: imgCamera!.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResultsPerClass: 1,
      threshold: 0.4,
    );
    isWorking = false;
    setState(() {
      imgCamera!;
    });
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String? response;
      response = await Tflite.loadModel(
          model: "assets/ssd_mobilenet.tflite",
          labels: "assets/ssd_mobilenet.txt");
      print("응답은? " + response!);
    } on PlatformException {
      print("Unable to Load Model");
    }
  }

  @override
  void dispose() {
    super.dispose();
    cameraController!.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (recognitionList == null) return [];
    if (imgHeight == null || imgWidth == null) return [];

    double factorX = screen.width;
    double factorY = imgHeight;
    return recognitionList!.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toString()}",
            style: TextStyle(
              color: Colors.pink,
              fontSize: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildrenWidgets = [];
    stackChildrenWidgets.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: (!cameraController!.value.isInitialized)
            ? Container()
            : AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              )));
    if (imgCamera != null) {
      stackChildrenWidgets.addAll(displayBoxesAroundRecognizedObjects(size));
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: EdgeInsets.only(top: 50),
          color: Colors.black,
          child: Stack(
            children: stackChildrenWidgets,
          ),
        ),
      ),
    );
  }
}
