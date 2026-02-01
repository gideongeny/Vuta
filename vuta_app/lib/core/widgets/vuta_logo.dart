import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class VutaLogo extends StatelessWidget {
  final double size;
  const VutaLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/vuta_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            painter: VutaLogoPainter(),
          );
        },
      ),
    );
  }
}

class VutaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [Color(0xFF00FF85), Color(0xFF00A3FF)],
      )
      ..style = PaintingStyle.fill;

    // Draw a stylized 'V' bolt
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.3);
    path.lineTo(size.width * 0.4, size.height * 0.4);
    path.close();

    // Shadow/Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00FF85).withAlpha(77)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawPath(path, paint);

    // Glass overlay effect
    final glassPaint = Paint()
      ..color = Colors.white.withAlpha(26)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, size.width * 0.4, glassPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
