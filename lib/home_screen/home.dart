import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image;
  List<Face> faces = [];
  bool _isLoading = false;
  double? eyeDistance, mouthWidth, noseToMouth;

  Future _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;
      setState(() {
        _image = File(image.path);
        _isLoading = true;
      });
      await _detectFaces(_image!);
    } catch (e) {
      _showError("Failed to pick image.");
    }
  }

  Future _detectFaces(File img) async {
    try {
      final options = FaceDetectorOptions(enableContours: true);
      final faceDetector = FaceDetector(options: options);
      final inputImage = InputImage.fromFilePath(img.path);
      faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        analyzeFace(faces.first);
      } else {
        _showError("No face detected.");
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError("Failed to detect faces.");
    }
  }

  double calculateDistance(Offset p1, Offset p2) {
    return sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
  }

  void analyzeFace(Face face) {
    final leftEyePoints = face.contours[FaceContourType.leftEye]?.points;
    final rightEyePoints = face.contours[FaceContourType.rightEye]?.points;
    final mouthLeftPoints = face.contours[FaceContourType.upperLipTop]?.points;
    final mouthRightPoints = face.contours[FaceContourType.upperLipBottom]?.points;
    final nosePoints = face.contours[FaceContourType.noseBridge]?.points;

    final leftEye = leftEyePoints != null && leftEyePoints.isNotEmpty ? leftEyePoints.first : null;
    final rightEye = rightEyePoints != null && rightEyePoints.isNotEmpty ? rightEyePoints.last : null;
    final mouthLeft = mouthLeftPoints != null && mouthLeftPoints.isNotEmpty ? mouthLeftPoints.first : null;
    final mouthRight = mouthRightPoints != null && mouthRightPoints.isNotEmpty ? mouthRightPoints.last : null;
    final nose = nosePoints != null && nosePoints.isNotEmpty ? nosePoints.first : null;

    setState(() {
      if (leftEye != null && rightEye != null) {
        eyeDistance = calculateDistance(
          Offset(leftEye.x.toDouble(), leftEye.y.toDouble()),
          Offset(rightEye.x.toDouble(), rightEye.y.toDouble()),
        );
      }
      if (mouthLeft != null && mouthRight != null) {
        mouthWidth = calculateDistance(
          Offset(mouthLeft.x.toDouble(), mouthLeft.y.toDouble()),
          Offset(mouthRight.x.toDouble(), mouthRight.y.toDouble()),
        );
      }
      if (nose != null && mouthRight != null) {
        noseToMouth = calculateDistance(
          Offset(nose.x.toDouble(), nose.y.toDouble()),
          Offset(mouthRight.x.toDouble(), mouthRight.y.toDouble()),
        );
      }
    });
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      faces.clear(); // حذف الوجوه السابقة لضمان عدم عرض بيانات خاطئة
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Face Detector"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _image == null
                  ? Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey)
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(color: Colors.blueAccent)
                : Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Take a Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.image),
                  label: Text("Upload a Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (faces.isNotEmpty) ...[
              Text(
                'Faces detected: ${faces.length}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              if (eyeDistance != null)
                Text("Eye Distance: ${eyeDistance!.toStringAsFixed(2)} px", style: TextStyle(fontSize: 16)),
              if (mouthWidth != null)
                Text("Mouth Width: ${mouthWidth!.toStringAsFixed(2)} px", style: TextStyle(fontSize: 16)),
              if (noseToMouth != null)
                Text("Nose to Mouth: ${noseToMouth!.toStringAsFixed(2)} px", style: TextStyle(fontSize: 16)),
            ]
          ],
        ),
      ),
    );
  }
}
