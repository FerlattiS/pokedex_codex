import 'package:flutter/material.dart';

class GameRevealPanel extends StatelessWidget {
  const GameRevealPanel({
    super.key,
    required this.isRevealed,
    required this.hidden,
    required this.revealed,
  });

  final bool isRevealed;
  final Widget hidden;
  final Widget revealed;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(isRevealed),
          child: isRevealed ? revealed : hidden,
        ),
      ),
    );
  }
}
