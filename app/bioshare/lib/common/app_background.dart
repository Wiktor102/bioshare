import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.1, 0.7],
            colors: [
              Theme.of(context).colorScheme.secondary.withAlpha(150),
              Colors.white,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
