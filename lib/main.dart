import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'emisor/emisor_page.dart';
import 'receptor/receptor_page.dart';
import 'ui/widgets/neon_button.dart';
import 'ui/widgets/glass_card.dart';
import 'services/background_service.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initializeService();
  try {
    _cameras = await availableCameras();
  } catch (e) {
    _cameras = [];
    debugPrint('Error al inicializar cámaras: $e');
  }
  runApp(const CamSecurityApp());
}

class CamSecurityApp extends StatelessWidget {
  const CamSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CYPHER-M SECURE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050A18), // Deep Space Blue
        primaryColor: const Color(0xFF00F2EA), // Cyan Neon
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2EA),
          secondary: Color(0xFFFF0055), // Magenta Neon
          surface: Color(0xFF121A2D),
        ),
        textTheme: GoogleFonts.orbitronTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: MainMenu(cameras: _cameras),
    );
  }
}

class MainMenu extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MainMenu({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Color(0xFF0D1D45),
                  Color(0xFF050A18),
                ],
              ),
            ),
          ),
          // Elementos decorativos de fondo (círculos difusos)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2EA).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2EA).withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Título con efecto
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00F2EA), Color(0xFFFF0055)],
                    ).createShader(bounds),
                    child: const Text(
                      'CYPHER-M',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const Text(
                    'SECURITY SOLUTIONS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      letterSpacing: 5,
                    ),
                  ),
                  const Spacer(),
                  
                  // Menú Principal en tarjeta de cristal
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeonButton(
                            text: 'MODO EMISOR',
                            icon: Icons.videocam,
                            color: const Color(0xFF00F2EA),
                            onPressed: cameras.isNotEmpty
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmisorPage(cameras: cameras),
                                      ),
                                    )
                                : () => _showNoCameraDialog(context),
                          ),
                          const SizedBox(height: 25),
                          NeonButton(
                            text: 'MODO RECEPTOR',
                            icon: Icons.qr_code_scanner,
                            color: const Color(0xFFFF0055),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReceptorPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'SECURE CONNECTION ESTABLISHED',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoCameraDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121A2D),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFF0055), width: 1)),
        title: const Text('ERROR DE SISTEMA', style: TextStyle(color: Color(0xFFFF0055))),
        content: const Text('No se detectaron módulos de cámara activos en este dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF00F2EA))),
          ),
        ],
      ),
    );
  }
}
