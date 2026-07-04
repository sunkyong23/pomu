import 'package:flutter/material.dart';

import '../../theme/pomu_colors.dart';

class PomuLogo extends StatelessWidget {
  final double size;

  const PomuLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PomuLogoPainter()),
    );
  }
}

class _PomuLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [PomuColors.gradientStart, PomuColors.gradientEnd],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    path.moveTo(size.width * 0.28, size.height * 0.88);

    path.lineTo(size.width * 0.28, size.height * 0.18);

    path.lineTo(size.width * 0.60, size.height * 0.18);

    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.18,
      size.width * 0.82,
      size.height * 0.40,
    );

    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.60,
      size.width * 0.60,
      size.height * 0.60,
    );

    path.lineTo(size.width * 0.42, size.height * 0.60);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
