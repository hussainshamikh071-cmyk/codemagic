import 'package:flutter/material.dart';

class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double delay;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeIn,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
}

class SlideUpAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const SlideUpAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.2), end: Offset.zero),
      duration: duration,
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return FractionalTranslation(translation: value, child: child);
      },
      child: child,
    );
  }
}
