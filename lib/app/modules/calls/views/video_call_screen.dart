

// import 'dart:async';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:wisper/app/core/others/custom_size.dart';
// import 'package:wisper/app/core/widgets/common/circle_icon.dart';
// import 'package:wisper/app/modules/calls/widget/call_feature.dart';
// import 'package:wisper/gen/assets.gen.dart';

// class VideoCallScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;

//   const VideoCallScreen({super.key, required this.cameras});

//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }

// class _VideoCallScreenState extends State<VideoCallScreen> {
//   CameraController? controller;
//   bool isRearCamera = true;
//   double _currentScale = 1.0;
//   double _baseScale = 1.0;
//   double _minZoom = 1.0;
//   double _maxZoom = 1.0;
//   int _pointers = 0;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera(isRearCamera ? 0 : 1);
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeCamera(int cameraIndex) async {
//     final cameras = widget.cameras;

//     if (cameras.isEmpty) {
//       debugPrint("No cameras available");
//       return;
//     }

//     controller = CameraController(
//       cameras[cameraIndex],
//       ResolutionPreset.high,
//       enableAudio: false,
//     );

//     await controller!.initialize();
//     _minZoom = await controller!.getMinZoomLevel();
//     _maxZoom = await controller!.getMaxZoomLevel();

//     if (!mounted) return;
//     setState(() {});
//   }

//   void toggleCamera() {
//     setState(() {
//       isRearCamera = !isRearCamera;
//     });
//     _initializeCamera(isRearCamera ? 0 : 1);
//   }

//   void takePicture() async {
//     if (controller == null || !controller!.value.isInitialized) return;

//     try {
//       final image = await controller!.takePicture();
//       debugPrint("Image saved at: ${image.path}");
//     } catch (e) {
//       debugPrint("Error capturing image: $e");
//     }
//   }

//   void _handleScaleStart(ScaleStartDetails details) {
//     _baseScale = _currentScale;
//   }

//   Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
//     if (controller == null || _pointers != 2) return;
//     _currentScale = (_baseScale * details.scale).clamp(_minZoom, _maxZoom);
//     await controller!.setZoomLevel(_currentScale);
//   }

//   @override
//   Widget build(BuildContext context) {
//     double height = MediaQuery.of(context).size.height;
//     double width = MediaQuery.of(context).size.width;
//     if (controller == null || !controller!.value.isInitialized) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return SafeArea(
//       child: Scaffold(
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             GestureDetector(
//               onScaleStart: _handleScaleStart,
//               onScaleUpdate: _handleScaleUpdate,
//               child: CameraPreview(controller!),
//             ),

//             /// 📌 Floating Capture Button
//             Positioned(
//               bottom: height / 20,
//               left: 00,
//               right: 0,

//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 40),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     CallFeature(
//                       onTap: () {},
//                       imagePath: Assets.images.userAdd.keyName,
//                       title: 'Add Call',
//                     ),
//                     widthBox15,
//                     CallFeature(
//                       onTap: () {},
//                       imagePath: Assets.images.mic.keyName,
//                       title: 'Speaker',
//                     ),
//                     widthBox15,
//                     CallFeature(
//                       onTap: () {},
//                       imagePath: Assets.images.mic.keyName,
//                       title: 'Mute',
//                     ),
//                     widthBox15,
//                     CallFeature(
//                       color: Colors.red,
//                       onTap: () {},
//                       imagePath: Assets.images.callOff.keyName,
//                       title: 'End Call',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
