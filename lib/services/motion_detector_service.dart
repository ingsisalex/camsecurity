import 'package:camera/camera.dart';
import 'dart:typed_data';

class MotionDetectorService {
  Uint8List? _previousFrame;
  final double threshold = 20.0; // Sensitivity

  bool detectMotion(CameraImage image) {
    if (_previousFrame == null) {
      _previousFrame = image.planes[0].bytes;
      return false;
    }

    final currentFrame = image.planes[0].bytes;
    int diffCount = 0;
    
    // Simple pixel-by-pixel difference on Y plane (luminosity)
    // Sampling every 10th pixel for performance
    for (int i = 0; i < currentFrame.length; i += 10) {
      if ((currentFrame[i] - _previousFrame![i]).abs() > threshold) {
        diffCount++;
      }
    }

    _previousFrame = currentFrame;
    
    // If more than 1% of pixels changed significantly, detect motion
    return diffCount > (currentFrame.length / 1000);
  }
}
