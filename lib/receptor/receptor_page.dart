import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async'; // Necesario para Future.delayed
import 'remote_view_page.dart';

class ReceptorPage extends StatefulWidget {
  const ReceptorPage({super.key});

  @override
  State<ReceptorPage> createState() => _ReceptorPageState();
}

class _ReceptorPageState extends State<ReceptorPage> with SingleTickerProviderStateMixin {
  String? qrResult;
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleQrResult(String? value) {
    if (value == null || _isProcessing) return;
    setState(() {
      qrResult = value;
      _isProcessing = true;
    });

    // Simulación de conexión
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CONNECTING TO: $value'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RemoteViewPage(remoteId: value),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).primaryColor;
    final magenta = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('CYPHER-M // RECEPTOR', style: TextStyle(color: cyan, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: magenta),
      ),
      body: Stack(
        children: [
          // 1. Escáner
          MobileScanner(
            fit: BoxFit.cover,
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _handleQrResult(barcode.rawValue);
              }
            },
          ),
          
          // 2. Overlay de Escaneo (Animación)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Marco fijo
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: cyan.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                // Esquinas brillantes
                _buildScannerCorners(magenta),
                // Línea de escaneo animada
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned(
                      top: 50 + (250 * _animationController.value), // Ajuste visual
                      child: Container(
                        width: 250,
                        height: 2,
                        decoration: BoxDecoration(
                          color: cyan,
                          boxShadow: [
                            BoxShadow(color: cyan, blurRadius: 10, spreadRadius: 2)
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. Resultado
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _isProcessing ? magenta : cyan),
              ),
              child: Text(
                qrResult == null
                    ? 'ALIGN QR CODE WITHIN FRAME'
                    : 'TARGET ACQUIRED: $qrResult',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isProcessing ? magenta : cyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCorners(Color color) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _corner(color, 0)),
          Align(alignment: Alignment.topRight, child: _corner(color, 1)),
          Align(alignment: Alignment.bottomLeft, child: _corner(color, 2)),
          Align(alignment: Alignment.bottomRight, child: _corner(color, 3)),
        ],
      ),
    );
  }

  Widget _corner(Color color, int rotation) {
    return RotatedBox(
      quarterTurns: rotation,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 4),
            left: BorderSide(color: color, width: 4),
          ),
        ),
      ),
    );
  }
}
