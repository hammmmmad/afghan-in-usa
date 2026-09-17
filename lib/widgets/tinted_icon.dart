import 'package:flutter/material.dart';

/// Renders one of the bundled PNG icons in a single flat colour, so the
/// user's own artwork behaves like a proper icon font.
class TintedIcon extends StatelessWidget {
  const TintedIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
  });

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Image image = Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined,
          size: size, color: color ?? Theme.of(context).colorScheme.onSurface),
    );
    if (color == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      child: image,
    );
  }
}

/// Original-colour version with a soft rounded container behind it.
class AssetGlyph extends StatelessWidget {
  const AssetGlyph(
    this.asset, {
    super.key,
    this.size = 34,
    this.padding = 8,
    this.background,
    this.radius = 14,
  });

  final String asset;
  final double size;
  final double padding;
  final Color? background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background ??
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Icons.folder_outlined, size: size),
      ),
    );
  }
}
