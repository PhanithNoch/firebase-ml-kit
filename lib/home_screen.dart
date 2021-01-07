import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedItem = 'Label Scanner';

  File pickedImage;
  var imageFile;

  var result = '';

  bool isImageLoaded = false;
  bool isFaceDetected = false;

  List<Rect> rect = new List<Rect>();

  getImageFromGallery() async {
    var tempStore = await ImagePicker().getImage(source: ImageSource.gallery);
//    var tempStore = await ImagePicker().getImage(source: ImageSource.camera);

    imageFile = await tempStore.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);

    setState(() {
      pickedImage = File(tempStore.path);
      isImageLoaded = true;
      isFaceDetected = false;
      imageFile = imageFile;
    });
  }

  getImageFromCamera() async {
    var tempStore = await ImagePicker().getImage(source: ImageSource.camera);

    imageFile = await tempStore.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);

    setState(() {
      pickedImage = File(tempStore.path);
      isImageLoaded = true;
      isFaceDetected = false;
      imageFile = imageFile;
    });
  }

  readTextFromImage() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(myImage);

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            result = result + ' ' + word.text;
          });
        }
      }
    }
  }

  decodeBarCode() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector();
    List barCodes = await barcodeDetector.detectInImage(myImage);

    for (Barcode readableCode in barCodes) {
      setState(() {
        result = readableCode.displayValue;
      });
    }
  }

  Future labelsread() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
    List labels = await labeler.processImage(myImage);

    for (ImageLabel label in labels) {
      final String text = label.text;
      final double confidence = label.confidence;
      List confidenceLst= new List();
      confidenceLst.add(confidence);

      // Declaring and assigning the
      // largestGeekValue and smallestGeekValue
      double largestGeekValue = confidenceLst[0];

      for (var i = 0; i < confidenceLst.length; i++) {
        print(confidenceLst[i]);
        // Checking for largest value in the list
        if (largestGeekValue < confidenceLst[i]) {
          largestGeekValue = confidenceLst[i] * 100;
        }

      }

//      result = '';
      setState(() {
        result = result + ' ' + '$text     ${confidence}' + '\n';
      });

    }
  }

  Future detectFace() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(myImage);

    if (rect.length > 0) {
      rect = new List<Rect>();
    }

    for (Face face in faces) {
      rect.add(face.boundingBox);
    }

    setState(() {
      isFaceDetected = true;
    });
  }

  void detectMLFeature(String selectedFeature) {
    switch (selectedFeature) {
      case 'Text Scanner':
        readTextFromImage();
        break;
      case 'Barcode Scanner':
        decodeBarCode();
        break;
      case 'Label Scanner':
        labelsread();
        break;
      case 'Face Detection':
        detectFace();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
//    selectedItem = ModalRoute.of(context).settings.arguments.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem),
        actions: [
          RaisedButton(
            onPressed: getImageFromGallery,
            child: Icon(
              Icons.add_a_photo,
              color: Colors.white,
            ),
            color: Colors.blue,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isImageLoaded && !isFaceDetected
              ? Expanded(
                child: Center(
            child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: FileImage(pickedImage), fit: BoxFit.cover,
                  ),
                ),
            ),
          ),
              )
              : isImageLoaded && isFaceDetected
              ? Expanded(
            child: Center(
              child: Container(
                child: FittedBox(
                  child: SizedBox(
                    width: imageFile.width.toDouble(),
                    height: imageFile.height.toDouble(),
                    child: CustomPaint(
                      painter:
                      FacePainter(rect: rect, imageFile: imageFile),
                    ),
                  ),
                ),
              ),
            ),
          )
              : Container(child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image,size: 200,),


            ],
          ),),
          SizedBox(height: 30),
          FlatButton(onPressed: (){
            getImageFromCamera();
          }, child: Icon(Icons.camera_front,size: 50,)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(result,style: TextStyle(fontSize: 22,fontWeight: FontWeight.w300),),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          detectMLFeature(selectedItem);
        },
        child: Icon(Icons.check),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Rect> rect;
  var imageFile;

  FacePainter({@required this.rect, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(
        imageFile,
        Offset.zero,
        Paint(),
      );
    }

    for (Rect rectange in rect) {
      canvas.drawRect(
        rectange,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    throw UnimplementedError();
  }
}
