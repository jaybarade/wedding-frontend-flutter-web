import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';

class ImageGrid extends StatelessWidget {
  final List<dynamic> imageUrls;
  final Function(String) onImageTap;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final url = imageUrls[index];
        final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}/public/photos/$url';
        
        return GestureDetector(
          onTap: () => onImageTap(url),
          child: Hero(
            tag: url,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white10),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }
}
