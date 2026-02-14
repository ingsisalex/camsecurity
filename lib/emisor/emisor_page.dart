import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../ui/widgets/glass_card.dart';
import '../services/motion_detector_service.dart';
import '../services/webrtc_service.dart';
import '../services/signaling_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class EmisorPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const EmisorPage({super.key, required this.cameras});

  @override
  State<EmisorPage> createState() => _EmisorPageState();
}

class _EmisorPageState extends State<EmisorPage> {
  CameraController? controller;
  String deviceId = "ANALYZING HARDWARE...";
  int cameraIndex = 0;
  bool _isCameraError = false;
  bool _isMonitoring = false;

  final MotionDetectorService _motionDetector = MotionDetectorService();
  final WebRTCService _webRTCService = WebRTCService();
  final SignalingService _signalingService = SignalingService();

  @override
  void initState() {
    super.initState();
    _initId();
    _initCamera(cameraIndex);
  }

  Future<void> _initId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String info = "ERROR_ID";
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info = "${androidInfo.model}_${androidInfo.hardware}_${androidInfo.id}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info = "${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}";
      }
    } catch (e) {
      info = "ID_UNKNOWN";
    }
    if (mounted) setState(() => deviceId = info);
  }

  Future<void> _initCamera(int index) async {
    if (widget.cameras.isEmpty) {
      setState(() => _isCameraError = true);
      return;
    }
    controller?.dispose();
    controller = CameraController(
      widget.cameras[index],
      ResolutionPreset.medium,
      enableAudio: true,
    );
    try {
      await controller!.initialize();
      if (mounted) {
        setState(() => _isCameraError = false);
        // Start streaming frames for motion detection if monitoring is active
        if (_isMonitoring) _startMotionDetection();
      }
    } catch (e) {
      debugPrint("Error al inicializar cámara: $e");
      setState(() => _isCameraError = true);
    }
  }

  void _startMotionDetection() {
    controller?.startImageStream((CameraImage image) {
      if (_motionDetector.detectMotion(image)) {
        debugPrint("MOTION DETECTED!");
        // Logic to trigger notification/recording
      }
    });
  }

  void _toggleMonitoring() async {
    final service = FlutterBackgroundService();
    if (_isMonitoring) {
      controller?.stopImageStream();
      service.invoke("stopService");
    } else {
      _startMotionDetection();
      service.startService();
      _webRTCService.initialize(); // Start WebRTC signaling
    }
    setState(() => _isMonitoring = !_isMonitoring);
  }

  void _switchCamera() {
    if (widget.cameras.length < 2) return;
    cameraIndex = (cameraIndex + 1) % widget.cameras.length;
    _initCamera(cameraIndex);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colores del tema
    final cyan = Theme.of(context).primaryColor;
    final magenta = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CYPHER-M // EMISOR',
          style: TextStyle(
            color: cyan,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cameraswitch, color: magenta),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Capa de Cámara (Fondo)
          if (_isCameraError)
             Center(
              child: Text(
                "CAMERA_MODULE_OFFLINE",
                style: TextStyle(color: magenta, fontSize: 20),
              ),
            )
          else if (controller != null && controller!.value.isInitialized)
            CameraPreview(controller!)
          else
             Center(child: CircularProgressIndicator(color: cyan)),

          // 2. Capa de HUD (Overlays de diseño)
          // Bordes de esquina (tipo visor)
          Positioned(
            top: 100,
            left: 20,
            child: _buildCorner(cyan, true, true),
          ),
          Positioned(
            top: 100,
            right: 20,
            child: _buildCorner(cyan, true, false),
          ),
          Positioned(
            bottom: 250, // Dejar espacio para el panel inferior
            left: 20,
            child: _buildCorner(cyan, false, true),
          ),
          Positioned(
            bottom: 250,
            right: 20,
            child: _buildCorner(cyan, false, false),
          ),

          // 3. Panel Inferior (QR y Datos)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassCard(
              opacity: 0.2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: magenta, width: 2)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LINK DEVICE',
                      style: TextStyle(
                        color: cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // QR Generado
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cyan, width: 2),
                            boxShadow: [
                              BoxShadow(color: cyan.withOpacity(0.5), blurRadius: 10)
                            ],
                          ),
                          child: QrImageView(
                            data: deviceId,
                            size: 100,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(0),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Información del dispositivo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DEVICE_ID:",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 10),
                              ),
                              Text(
                                deviceId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isMonitoring ? "STATUS: ARMED & MONITORING" : "STATUS: STANDBY",
                                style: TextStyle(
                                  color: _isMonitoring ? magenta : cyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _toggleMonitoring,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isMonitoring ? magenta : cyan,
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(_isMonitoring ? "DISARM" : "ARM SYSTEM"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Color color, bool top, bool left) {
    const double size = 30;
    const double thickness = 3;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }
}
