import 'dart:math';
import 'package:flutter/material.dart';

class TossCoinWidget extends StatefulWidget {
  final bool isTossing;
  final VoidCallback onToss;

  const TossCoinWidget({
    super.key,
    required this.isTossing,
    required this.onToss,
  });

  @override
  State<TossCoinWidget> createState() => _TossCoinWidgetState();
}

class _TossCoinWidgetState extends State<TossCoinWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    // Rotate on X axis to simulate flip
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
  }

  @override
  void didUpdateWidget(TossCoinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTossing && !oldWidget.isTossing) {
      _controller.repeat();
    } else if (!widget.isTossing && oldWidget.isTossing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onTap: widget.isTossing ? null : widget.onToss,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_animation.value),
                alignment: Alignment.center,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.tertiary, // Gold
                        Colors.orangeAccent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.isTossing ? "?" : "TOSS",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!widget.isTossing)
          Text(
            "Tap coin to flip",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
      ],
    );
  }
}