import 'package:flutter/material.dart';

class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return const FadePageTransitionsBuilder()
        .buildTransitions(this, context, animation, secondaryAnimation, child);
  }

  @override
  bool canTransitionFrom(TransitionRoute previousRoute) {
    return false;
  }

}

class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    return _FadePageTransition(routeAnimation: animation, child: child);
  }
}

class _FadePageTransition extends StatelessWidget {
  _FadePageTransition({
    required Animation<double>
        routeAnimation, // The route's linear 0.0 - 1.0 animation.
    required this.child,
  }) : _opacityAnimation = routeAnimation.drive(_easeInTween);

  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);

  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: child,
    );
  }
}
