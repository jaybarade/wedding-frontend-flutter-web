import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/wedding_provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import 'dart:ui' as ui;
import 'dart:html' as html; // Web के लिए
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeddingProvider>(context, listen: false).fetchMyWeddings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.deepPurpleAccent ,
        title: const Text('My Collections',

            style: TextStyle(
              color:Colors.white,
                fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                color: Colors.white)
            ,
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.go('/login');
            },
          ),
        ],
      ),

      body: Consumer<WeddingProvider>(
        builder: (context, weddingProv, _) {
          if (weddingProv.isLoading && weddingProv.myWeddings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (weddingProv.myWeddings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No weddings yet',
                      style: TextStyle(color: Colors.white24, fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                    onPressed: () => context.push('/create'),
                    icon: const Icon(Icons.add ,
                    color: Colors.white),
                    label: const Text('Create Your First Wedding'
                    ,style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => weddingProv.fetchMyWeddings(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: weddingProv.myWeddings.length,
              itemBuilder: (context, index) {
                final wedding = weddingProv.myWeddings[index];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12) ,),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        /// 🔥 IMAGE SECTION
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (wedding.coverImage != null)
                                CachedNetworkImage(
                                  imageUrl: wedding.coverImage!.startsWith('http')
                                      ? wedding.coverImage!
                                      : '${ApiConfig.baseUrl}/public/photos/${wedding.coverImage}',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.white10),
                                  errorWidget: (context, url, error) =>
                                  const Icon(Icons.image_not_supported ,color: Colors.white ,),
                                )
                              else
                                Container(
                                    color: Colors.deepPurple.withOpacity(0.2)),

                              /// Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),

                              /// Title
                              Positioned(
                                bottom: 10,
                                left: 10,
                                right: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wedding.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Text(
                                      wedding.slug,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10,),

                        /// 🔥 BUTTONS SECTION
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/gallery/${wedding.slug}');
                                },
                                icon: const Icon(Icons.photo, color: Colors.white),
                                label: const Text("View", style: TextStyle(color: Colors.white,
                                fontSize: 12)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/upload/${wedding.id}');
                                },
                                icon: const Icon(Icons.upload, color: Colors.white),
                                label: const Text("Upload" ,style: TextStyle(color: Colors.white,
                                fontSize: 10)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showQrDialog(context, wedding.slug);
                                },
                                icon: const Icon(Icons.qr_code, color: Colors.white),
                                label: const Text("QR" ,style: TextStyle(color: Colors.white
                                ,fontSize: 12)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create'),
        label: const Text('New Wedding'
        ,style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }
}

void _showQrDialog(BuildContext context, String slug) {
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
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1E1E2C),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔗 URL + COPY
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

            /// 🔳 QR (WHITE BACKGROUND FIX)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: RepaintBoundary(
                key: qrKey,
                child: QrImageView(
                  data: url,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ⬇️ DOWNLOAD BUTTON
            ElevatedButton.icon(
              onPressed: downloadQR,
              icon: const Icon(Icons.download , color: Colors.white),
              label: const Text("Download QR" ,style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}