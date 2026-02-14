import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class RemoteViewPage extends StatefulWidget {
  final String remoteId;
  const RemoteViewPage({super.key, required this.remoteId});

  @override
  State<RemoteViewPage> createState() => _RemoteViewPageState();
}

class _RemoteViewPageState extends State<RemoteViewPage> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final WebRTCService _webRTCService = WebRTCService();

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _remoteRenderer.initialize();
    // In a real implementation, we would connect to the remoteId via signaling here
    debugPrint('Connecting to remote stream: ${widget.remoteId}');
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _webRTCService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('REMOTE VIEW: ${widget.remoteId}', 
                   style: TextStyle(color: cyan, fontSize: 14)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
      ),
    );
  }
}
