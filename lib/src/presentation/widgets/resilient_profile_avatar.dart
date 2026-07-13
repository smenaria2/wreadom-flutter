import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular network avatar that falls back when a response is not an image.
class ResilientProfileAvatar extends StatelessWidget {
  const ResilientProfileAvatar({
    super.key,
    required this.radius,
    required this.initial,
    required this.backgroundColor,
    required this.foregroundColor,
    this.imageUrl,
    this.fontWeight = FontWeight.w700,
  });

  final double radius;
  final String initial;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? imageUrl;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.76,
            fontWeight: fontWeight,
            color: foregroundColor,
          ),
        ),
      ),
    );
    final url = imageUrl?.trim();

    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
