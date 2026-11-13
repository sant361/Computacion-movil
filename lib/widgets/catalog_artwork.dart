import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class CatalogArtwork extends StatelessWidget {
  const CatalogArtwork({super.key, required this.url, this.child});
  final String url;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final valid = uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: AppColors.surface),
      if (valid)
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.movie_outlined, color: Colors.white54)),
        )
      else
        const Center(child: Icon(Icons.movie_outlined, color: Colors.white54)),
      if (child != null) child!,
    ]);
  }
}
