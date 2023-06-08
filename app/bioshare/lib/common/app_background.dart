import 'package:bioshare/models/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeModel, Brightness>(
      selector: (context, themeProvider) => themeProvider.brightness,
      builder: (context, b, child) {
        return Container(
          color: b == Brightness.light ? Colors.white : Theme.of(context).primaryColorDark,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.1, 0.7],
                colors: [
                  Theme.of(context).colorScheme.secondary.withAlpha(150),
                  b == Brightness.light ? Colors.white : Theme.of(context).primaryColorDark,
                ],
              ),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
