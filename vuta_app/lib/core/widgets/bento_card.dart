import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vuta/core/theme.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? accentColor;

  const BentoCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: VutaTheme.glassWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: VutaTheme.glassBorder,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
