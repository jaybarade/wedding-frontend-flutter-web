import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../providers/wedding_provider.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UploadPhotosScreen extends StatefulWidget {
  final int weddingId;
  const UploadPhotosScreen({super.key, required this.weddingId});

  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  List<PlatformFile> _selectedFiles = [];
  PlatformFile? _selectedMusic;

  void _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      setState(() => _selectedFiles = result.files);
    }
  }

  void _pickMusic() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (result != null) {
      setState(() => _selectedMusic = result.files.first);
    }
  }

  void _upload() async {
    if (_selectedFiles.isEmpty) return;

    final provider = Provider.of<WeddingProvider>(context, listen: false);
    final success = await provider.uploadPhotos(
      widget.weddingId,
      _selectedFiles,
      musicFile: _selectedMusic,
    );

    if (success && mounted) {
      final wedding = provider.myWeddings.firstWhere((w) => w.id == widget.weddingId);
      _showSuccessDialog(wedding.slug);
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.redAccent),
      );
    }
  }



  void _showSuccessDialog(String slug) {
    final url = '${Uri.base.origin}/gallery/$slug';
    final GlobalKey qrKey = GlobalKey();

    Future<void> downloadQR() async {
      try {
        final boundary =
        qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        final pngBytes = byteData!.buffer.asUint8List();

        final blob = html.Blob([pngBytes]);
        final urlBlob = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: urlBlob)
          ..setAttribute("download", "wedding_${slug}_qr.png")
          ..click();

        html.Url.revokeObjectUrl(urlBlob);
      } catch (e) {
        print("Download error: $e");
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E1E2C),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ✅ ICON + TITLE
              const Icon(Icons.check_circle, color: Colors.green, size: 70),
              const SizedBox(height: 10),
              const Text(
                "Upload Successful!",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),

              const SizedBox(height: 16),

              /// 🔗 LINK + COPY
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        url,
                        style: const TextStyle(color: Colors.deepPurpleAccent),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Link Copied")),
                        );
                      },
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔳 QR CODE (IMPORTANT WRAP)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    color: Colors.white, // 🔥 IMPORTANT FIX
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: url,
                      size: 180,
                      backgroundColor: Colors.white, // 🔥 FORCE WHITE
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔥 BUTTONS
              Row(
                children: [
                  /// VIEW
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/gallery/$slug');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                      child: const Text("View" ,style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// DASHBOARD
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.go('/dashboard');
                      },
                      child: const Text("Dashboard", style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// DOWNLOAD QR
                  Expanded(
                    child: ElevatedButton(
                      onPressed: downloadQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("QR", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _showSuccessDialog(String slug) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Upload Successful!'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Icon(Icons.check_circle, color: Colors.green, size: 64),
  //           const SizedBox(height: 16),
  //           const Text('Your photos are now live.', textAlign: TextAlign.center),
  //           const SizedBox(height: 16),
  //           SelectableText(
  //             'http://localhost:3000/gallery/$slug',
  //             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => context.go('/dashboard'),
  //           child: const Text('Back to Dashboard'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => context.push('/gallery/$slug'),
  //           child: const Text('View Gallery'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Colors.deepPurpleAccent,
          title: const Text('Upload Photos' ,style: TextStyle(
            color:Colors.white,
            fontWeight: FontWeight.bold
          ),)),
      body: Consumer<WeddingProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.isLoading) ...[
                  const Text('Uploading...', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: provider.uploadProgress, minHeight: 10, borderRadius: BorderRadius.circular(5)),
                  const SizedBox(height: 8),
                  Text('${(provider.uploadProgress * 100).toInt()}%', textAlign: TextAlign.center),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_photo_alternate ,color: Colors.white),
                    label: const Text('Select Multiple Photos'
                        ,style: TextStyle(color: Colors.white)),
                    ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                    onPressed: _pickMusic,
                    icon: const Icon(Icons.music_note ,color: Colors.white),
                    label: Text(_selectedMusic != null ? 'Music: ${_selectedMusic!.name}' : 'Add Background Music (MP3)'
                        ,style: const TextStyle(color: Colors.white)),
                  ),

                  const SizedBox(height: 24),
                  if (_selectedFiles.isNotEmpty) ...[
                    Text('${_selectedFiles.length} photos selected', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                           child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                          ? Image.memory(
                          _selectedFiles[index].bytes!,
                          fit: BoxFit.cover,
                          )
                              : Image.file(
                          File(_selectedFiles[index].path!),
                          fit: BoxFit.cover,
                          ),
                          ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _upload,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Start Upload' ,style: TextStyle(color: Colors.white)),
                    ),
                  ] else
                    const Expanded(child: Center(child: Text('No photos selected', style: TextStyle(color: Colors.white24)))),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
