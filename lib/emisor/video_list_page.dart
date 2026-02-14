import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../ui/widgets/glass_card.dart';
import '../ui/widgets/video_player_widget.dart'; // Importación del nuevo widget

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<File> videoFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String videoDir = '${directory.path}/recordings';
      final dir = Directory(videoDir);

      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        setState(() {
          videoFiles = entities
              .whereType<File>()
              .where((file) => file.path.endsWith('.mp4'))
              .toList()
            ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        });
      }
    } catch (e) {
      debugPrint("Error cargando videos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVideo(File file) async {
    try {
      await file.delete();
      _loadVideos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ARCHIVO ELIMINADO")),
      );
    } catch (e) {
      debugPrint("Error al borrar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).primaryColor;
    final magenta = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: cyan),
        title: Text(
          'SECURE_STORAGE // VIDEOS',
          style: TextStyle(color: cyan, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cyan))
          : videoFiles.isEmpty
              ? Center(
                  child: Text(
                    "NO_DATA_FOUND",
                    style: TextStyle(color: magenta.withOpacity(0.5), fontSize: 18, letterSpacing: 4),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: videoFiles.length,
                  itemBuilder: (context, index) {
                    final file = videoFiles[index];
                    final date = file.lastModifiedSync();
                    final size = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: GlassCard(
                        opacity: 0.1,
                        child: ListTile(
                          leading: Icon(Icons.videocam, color: cyan),
                          title: Text(
                            DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "SIZE: $size MB",
                            style: TextStyle(color: cyan.withOpacity(0.7), fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            onPressed: () => _deleteVideo(file),
                          ),
                          onTap: () {
                            // Ahora navegamos al reproductor real
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerWidget(videoFile: file),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
