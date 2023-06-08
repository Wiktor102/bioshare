import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FullScreenLoader extends StatefulWidget {
  const FullScreenLoader({super.key});

  @override
  State<FullScreenLoader> createState() => _FullScreenLoaderState();
}

class _FullScreenLoaderState extends State<FullScreenLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Positioned(
              bottom: 350 - 40,
              height: MediaQuery.of(context).size.height - 350 + 40,
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/fridgeBG.jpg'),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              height: 350,
              width: MediaQuery.of(context).size.width,
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(180 / 360),
                child: ClipPath(
                  clipper: Clipper(),
                  child: Container(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 350 - 40,
              height: MediaQuery.of(context).size.height - 350 + 40,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(100, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LoadingAnimationWidget.dotsTriangle(
                    color: Theme.of(context).primaryColor,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 350 / 2,
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Ładowanie...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 24,
                  decorationStyle: null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Clipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 4, size.height - 40, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 / 4 * size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(Clipper oldClipper) => false;
}
