import 'dart:math';

import 'package:flutter/material.dart';

/// 完了時のパーティクルエフェクト
class CompletionParticles extends StatefulWidget {
  const CompletionParticles({super.key});

  @override
  State<CompletionParticles> createState() => _CompletionParticlesState();
}

class _CompletionParticlesState extends State<CompletionParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // パーティクルを生成
    for (int i = 0; i < 30; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * 300,
          y: _random.nextDouble() * 300,
          vx: (_random.nextDouble() - 0.5) * 4,
          vy: (_random.nextDouble() - 0.5) * 4,
          color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
          size: _random.nextDouble() * 8 + 4,
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

/// パーティクルデータ
class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
}

/// パーティクルペインター
class ParticlePainter extends CustomPainter {
  ParticlePainter({required this.particles, required this.progress});

  final List<Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      final x = particle.x + particle.vx * progress * 100;
      final y = particle.y + particle.vy * progress * 100;
      final particleSize = particle.size * (1.0 - progress * 0.5);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
