import 'package:flutter/material.dart';

class GameAnimations {
  static Animation<double> createShakeAnimation(
      AnimationController controller) {
    return Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticIn,
      ),
    );
  }

  static Animation<double> createScaleAnimation(
      AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  static Animation<double> createBounceAnimation(
      AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  static Animation<double> createRotateAnimation(
      AnimationController controller) {
    return Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }
}
