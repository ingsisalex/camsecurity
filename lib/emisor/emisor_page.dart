import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:async'; // Añadido para el timer de grabación
import '../ui/widgets/glass_card.dart';
import '../services/motion_detector_service.dart';
import '../services/webrtc_service.dart';
import '../services/signaling_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'video_list_page.dart'; // Importación de la nueva pantalla de videos

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
  bool _isRecording = false; // Nuevo estado para saber si está grabando

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
        if (_isMonitoring) _startMotionDetection();
      }
    } catch (e) {
      debugPrint("Error al inicializar cámara: $e");
      setState(() => _isCameraError = true);
    }
  }

  void _startMotionDetection() {
    controller?.startImageStream((CameraImage image) async {
      if (_motionDetector.detectMotion(image) && !_isRecording && _isMonitoring) {
        debugPrint("MOTION DETECTED! INICIANDO GRABACIÓN...");
        _startAutomaticRecording();
      }
    });
  }

  // Lógica para grabar clips de video automáticamente
  Future<void> _startAutomaticRecording() async {
    if (controller == null || !controller!.value.isInitialized || _isRecording) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final String videoDir = '${directory.path}/recordings';
      await Directory(videoDir).create(recursive: true);

      final String fileName = 'CLIP_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String filePath = '$videoDir/$fileName';

      setState(() => _isRecording = true);
      await controller!.startVideoRecording();

      // Graba por 10 segundos y detente
      Timer(const Duration(seconds: 10), () async {
        if (_isRecording) {
          XFile videoFile = await controller!.stopVideoRecording();
          await videoFile.saveTo(filePath);
          debugPrint("Video guardado en: $filePath");
          if (mounted) setState(() => _isRecording = false);
        }
      });
    } catch (e) {
      debugPrint("Error en grabación automática: $e");
      setState(() => _isRecording = false);
    }
  }

  void _toggleMonitoring() async {
    final service = FlutterBackgroundService();
    if (_isMonitoring) {
      if (controller?.value.isStreamingImages ?? false) {
        await controller?.stopImageStream();
      }
      service.invoke("stopService");
    } else {
      _startMotionDetection();
      service.startService();
      _webRTCService.initialize();
    }
    setState(() => _isMonitoring = !_isMonitoring);
  }

  void _switchCamera() {
    if (widget.cameras.length < 2) return;
    cameraIndex = (cameraIndex + 1) % widget.cameras.length;
    _initCamera(cameraIndex);
  }

  Future<void> _openVideoDirectory() async {
    debugPrint("Navegando al Repositorio de Videos...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoListPage()),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).primaryColor;
    final magenta = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CYPHER-M // EMISOR',
          style: TextStyle(color: cyan, letterSpacing: 2, fontWeight: FontWeight.bold),
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
          if (_isCameraError)
            Center(child: Text("CAMERA_OFFLINE", style: TextStyle(color: magenta, fontSize: 20)))
          else if (controller != null && controller!.value.isInitialized)
            CameraPreview(controller!)
          else
            Center(child: CircularProgressIndicator(color: cyan)),

          // Visores de esquina
          Positioned(top: 100, left: 20, child: _buildCorner(cyan, true, true)),
          Positioned(top: 100, right: 20, child: _buildCorner(cyan, true, false)),
          Positioned(bottom: 300, left: 20, child: _buildCorner(cyan, false, true)),
          Positioned(bottom: 300, right: 20, child: _buildCorner(cyan, false, false)),

          // Indicador de GRABANDO
          if (_isRecording)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.red.withOpacity(0.8),
                  child: const Text("● REC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

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
                    colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.9)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('LINK DEVICE', style: TextStyle(color: cyan, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cyan, width: 2),
                          ),
                          child: QrImageView(data: deviceId, size: 100, backgroundColor: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("DEVICE_ID:", style: TextStyle(color: Colors.grey, fontSize: 10)),
                              Text(deviceId, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Courier')),
                              const SizedBox(height: 10),
                              Text(
                                _isMonitoring ? "STATUS: ARMED" : "STATUS: STANDBY",
                                style: TextStyle(color: _isMonitoring ? magenta : cyan, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _toggleMonitoring,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isMonitoring ? magenta : cyan,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 36),
                                ),
                                child: Text(_isMonitoring ? "DISARM" : "ARM SYSTEM"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _openVideoDirectory,
                      icon: Icon(Icons.folder_open, color: cyan),
                      label: Text("VIDEO REPOSITORY", style: TextStyle(color: cyan, letterSpacing: 1.5)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cyan, width: 1),
                        minimumSize: const Size(double.infinity, 45),
                      ),
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
