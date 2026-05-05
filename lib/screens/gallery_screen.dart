import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:page_flip/page_flip.dart';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import '../providers/wedding_provider.dart';
import 'dart:async';

class GalleryScreen extends StatefulWidget {
  final String slug;
  const GalleryScreen({super.key, required this.slug});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  Map<String, dynamic>? _galleryData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final provider = Provider.of<WeddingProvider>(context, listen: false);
    final data = await provider.fetchPublicGallery(widget.slug);

    if (!mounted) return;

    setState(() {
      _galleryData = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// LOADING
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ERROR
    if (_galleryData == null || _galleryData!["_error"] != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            _galleryData?["_error"] ?? "Gallery not found",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final data = _galleryData!;
    final title = data['title'] ?? "Wedding Album";
    final coverImage = data['coverImage'];
    final List photos = (data['photos'] as List?) ?? [];
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                /// 🔥 FORCE FULL WIDTH IMAGE
                Positioned.fill(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: coverImage != null
                        ? Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                    )
                        : Container(color: Colors.black),
                  ),
                ),

                /// 🔥 OVERLAY
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),

                /// 🔥 CENTER CONTENT (ABSOLUTE CENTER FIX)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// TITLE
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: photos.isEmpty
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookFlipScreen(photos: photos),
                              ),
                            );
                          },
                          child: const Text(
                            "View Album",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}





class BookFlipScreen extends StatefulWidget {
  final List photos;

  const BookFlipScreen({super.key, required this.photos});

  @override
  State<BookFlipScreen> createState() => _BookFlipScreenState();
}

class _BookFlipScreenState extends State<BookFlipScreen>
    with TickerProviderStateMixin {
  int currentSheet = 0;

  late List<List> sheets;

  @override
  void initState() {
    super.initState();

    /// 👉 2 pages per sheet
    sheets = [];
    for (int i = 0; i < widget.photos.length; i += 2) {
      sheets.add(widget.photos.sublist(
          i, i + 2 > widget.photos.length ? widget.photos.length : i + 2));
    }
  }

  void next() {
    if (currentSheet < sheets.length) {
      setState(() => currentSheet++);
    }
  }

  void prev() {
    if (currentSheet > 0) {
      setState(() => currentSheet--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f1ea),
      body: Center(
        child: Stack(
          children: List.generate(sheets.length, (index) {
            bool flipped = index < currentSheet;

            return Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(flipped ? -pi : 0),
                transformAlignment: Alignment.centerLeft,
                child: _buildSheet(sheets[index], index),
              ),
            );
          }).reversed.toList(), // zIndex logic
        ),
      ),

      /// CONTROLS
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(onPressed: prev, child: const Text("Prev")),
            ElevatedButton(onPressed: next, child: const Text("Next")),
          ],
        ),
      ),
    );
  }

  /// 🔥 SHEET (2 PAGE)
  Widget _buildSheet(List sheet, int index) {
    return Row(
      children: [
        /// FRONT PAGE
        Expanded(
          child: _page(sheet[0], isFront: true),
        ),

        /// BACK PAGE
        Expanded(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(pi),
            child: sheet.length > 1
                ? _page(sheet[1], isFront: false)
                : Container(color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// 🔥 SINGLE PAGE UI
  Widget _page(Map photo, {required bool isFront}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black12,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CachedNetworkImage(
          imageUrl: photo['imageUrl'],
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// class FlipBookScreen extends StatefulWidget {
//   final List photos;
//
//   const FlipBookScreen({super.key, required this.photos});
//
//   @override
//   State<FlipBookScreen> createState() => _FlipBookScreenState();
// }
//
// class _FlipBookScreenState extends State<FlipBookScreen>
//     with SingleTickerProviderStateMixin {
//   late PageController _pageController;
//   late AnimationController _animController;
//   late AudioPlayer _audioPlayer;
//   late Timer _timer;
//
//   int currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _pageController = PageController();
//
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//
//     /// 🎵 INIT MUSIC
//     _audioPlayer = AudioPlayer();
//     _playMusic();
//
//     /// ⏱ AUTO FLIP START
//     _startAutoFlip();
//   }
//
//   /// 🎵 PLAY MUSIC
//   Future<void> _playMusic() async {
//     await _audioPlayer.setReleaseMode(ReleaseMode.loop);
//     await _audioPlayer.play(AssetSource('audio/wedding.mp3'));
//   }
//
//   /// ⏱ AUTO PAGE CHANGE EVERY 3s
//   void _startAutoFlip() {
//     _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
//       if (currentIndex < widget.photos.length - 1) {
//         _animController.forward(from: 0);
//
//         await _pageController.nextPage(
//           duration: const Duration(seconds: 3),
//           curve: Curves.easeInOut,
//         );
//
//         setState(() => currentIndex++);
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer.cancel();
//     _audioPlayer.dispose();
//     _pageController.dispose();
//     _animController.dispose();
//     super.dispose();
//   }
//
//   void _prevPage() async {
//     if (currentIndex <= 0) return;
//
//     _animController.forward(from: 0);
//
//     await _pageController.previousPage(
//       duration: const Duration(seconds: 3),
//       curve: Curves.easeInOut,
//     );
//
//     setState(() => currentIndex--);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// 🔥 FLIPBOOK VIEW
//           PageView.builder(
//             controller: _pageController,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: widget.photos.length,
//             itemBuilder: (context, index) {
//               return AnimatedBuilder(
//                 animation: _pageController,
//                 builder: (context, child) {
//                   double value = 1;
//
//                   if (_pageController.position.haveDimensions) {
//                     value = _pageController.page! - index;
//                     value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
//                   }
//
//                   return Transform(
//                     alignment: Alignment.center,
//                     transform: Matrix4.identity()
//                       ..setEntry(3, 2, 0.001)
//                       ..rotateY(pi * (1 - value)),
//                     child: child,
//                   );
//                 },
//                 child: Container(
//                   color: Colors.black,
//                   child: Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(16),
//                         child: CachedNetworkImage(
//                           imageUrl: widget.photos[index]['imageUrl'],
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           /// 🔥 TAP CONTROL
//           Positioned.fill(
//             child: Row(
//               children: [
//                 Expanded(
//                   child: GestureDetector(onTap: _prevPage),
//                 ),
//                 Expanded(
//                   child: GestureDetector(onTap: () {}),
//                 ),
//               ],
//             ),
//           ),
//
//           /// 🔥 CLOSE BUTTON
//           Positioned(
//             top: 50,
//             right: 20,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 30),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//
//           /// 🔥 PAGE COUNT
//           Positioned(
//             bottom: 40,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Text(
//                 "${currentIndex + 1} / ${widget.photos.length}",
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



//
// class FlipBookScreen extends StatefulWidget {
//   final List photos;
//
//   const FlipBookScreen({super.key, required this.photos});
//
//   @override
//   State<FlipBookScreen> createState() => _FlipBookScreenState();
// }
//
// class _FlipBookScreenState extends State<FlipBookScreen>
//     with SingleTickerProviderStateMixin {
//   late PageController _pageController;
//   late AnimationController _animController;
//
//   int currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _pageController = PageController();
//
//     /// 🔥 3 SECOND FLIP ANIMATION
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     _animController.dispose();
//     super.dispose();
//   }
//
//   void _nextPage() async {
//     if (currentIndex >= widget.photos.length - 1) return;
//
//     _animController.forward(from: 0);
//
//     await _pageController.nextPage(
//       duration: const Duration(seconds: 3),
//       curve: Curves.easeInOut,
//     );
//
//     setState(() => currentIndex++);
//   }
//
//   void _prevPage() async {
//     if (currentIndex <= 0) return;
//
//     _animController.forward(from: 0);
//
//     await _pageController.previousPage(
//       duration: const Duration(seconds: 3),
//       curve: Curves.easeInOut,
//     );
//
//     setState(() => currentIndex--);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// 🔥 PAGE VIEW WITH 3D ROTATION EFFECT
//           PageView.builder(
//             controller: _pageController,
//             physics: const NeverScrollableScrollPhysics(), // manual control
//             itemCount: widget.photos.length,
//             itemBuilder: (context, index) {
//               return AnimatedBuilder(
//                 animation: _pageController,
//                 builder: (context, child) {
//                   double value = 1;
//
//                   if (_pageController.position.haveDimensions) {
//                     value = _pageController.page! - index;
//                     value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
//                   }
//
//                   /// 🔥 3D BOOK FLIP EFFECT
//                   return Transform(
//                     alignment: Alignment.center,
//                     transform: Matrix4.identity()
//                       ..setEntry(3, 2, 0.001) // perspective
//                       ..rotateY(pi * (1 - value)),
//                     child: child,
//                   );
//                 },
//                 child: Container(
//                   color: Colors.black,
//                   child: Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(16),
//                         child: CachedNetworkImage(
//                           imageUrl: widget.photos[index]['imageUrl'],
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           /// 🔥 LEFT TAP AREA (PREVIOUS)
//           Positioned.fill(
//             child: Row(
//               children: [
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: _prevPage,
//                   ),
//                 ),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: _nextPage,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           /// 🔥 CLOSE BUTTON
//           Positioned(
//             top: 50,
//             right: 20,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 30),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//
//           /// 🔥 PAGE COUNTER
//           Positioned(
//             bottom: 40,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Text(
//                 "${currentIndex + 1} / ${widget.photos.length}",
//                 style: const TextStyle(color: Colors.white70),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

