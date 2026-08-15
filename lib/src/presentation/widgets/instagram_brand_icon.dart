import 'package:flutter/material.dart';

class InstagramBrandIcon extends StatelessWidget {
  const InstagramBrandIcon({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _InstagramBrandPainter(),
    );
  }
}

class _InstagramBrandPainter extends CustomPainter {
  const _InstagramBrandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final tile = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(size.shortestSide * 0.27),
    );
    final gradient = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF833AB4),
        Color(0xFFC13584),
        Color(0xFFE1306C),
        Color(0xFFF77737),
        Color(0xFFFCAF45),
      ],
      stops: [0, 0.27, 0.5, 0.76, 1],
    );
    canvas.drawRRect(tile, Paint()..shader = gradient.createShader(bounds));

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cameraBounds = Rect.fromLTRB(
      size.width * 0.23,
      size.height * 0.23,
      size.width * 0.77,
      size.height * 0.77,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cameraBounds,
        Radius.circular(size.shortestSide * 0.15),
      ),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.13,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.67, size.height * 0.34),
      size.shortestSide * 0.036,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
