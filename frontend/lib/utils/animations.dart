import 'package:flutter/material.dart';

class AppAnimations {
  // Durações padrão
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Curvas de animação
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fastCurve = Curves.easeOut;

  // Animações de entrada
  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 1.0, end: 0.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * 50),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget slideInFromRight({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 1.0, end: 0.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * 50, 0),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget fadeIn({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget scaleIn({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = bounceCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animações de hover
  static Widget hoverScale({
    required Widget child,
    double scale = 1.05,
    Duration duration = shortDuration,
  }) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      child: AnimatedContainer(
        duration: duration,
        child: child,
      ),
    );
  }

  // Animações de loading
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Animações de status
  static Widget statusAnimation({
    required Widget child,
    required bool isActive,
    Duration duration = mediumDuration,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: defaultCurve,
      child: AnimatedOpacity(
        duration: duration,
        opacity: isActive ? 1.0 : 0.6,
        child: child,
      ),
    );
  }

  // Animações de card
  static Widget cardAnimation({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Animações de botão
  static Widget buttonAnimation({
    required Widget child,
    required VoidCallback onTap,
    Duration duration = shortDuration,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: duration,
        tween: Tween(begin: 1.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }

  // Animações de lista
  static Widget listItemAnimation({
    required Widget child,
    required int index,
    Duration duration = mediumDuration,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration.inMilliseconds + (index * 100)),
      curve: defaultCurve,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Animações de progresso
  static Widget progressAnimation({
    required double progress,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 0.0, end: progress),
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  // Animações de ícone
  static Widget iconAnimation({
    required IconData icon,
    required bool isActive,
    Duration duration = shortDuration,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      child: Icon(
        icon,
        key: ValueKey(isActive),
        color: isActive ? Colors.green : Colors.grey,
      ),
    );
  }

  // Animações de texto
  static Widget textAnimation({
    required String text,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Text(text),
    );
  }
}
