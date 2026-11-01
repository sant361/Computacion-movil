import 'package:flutter/material.dart';

class CatalogArtwork extends StatelessWidget {
  const CatalogArtwork({super.key, required this.url, this.child});
  final String url;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xFF142338)),
        const Center(child: Icon(Icons.movie_outlined, color: Colors.white54)),
        if (child != null) child!,
      ]);
}
