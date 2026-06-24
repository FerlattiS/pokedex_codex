import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_destination.dart';

GoRouter createAppRouter({
  required Widget Function(
    BuildContext context,
    MainMenuDestination destination,
  )
  shellBuilder,
}) {
  return GoRouter(
    initialLocation: MainMenuDestination.home.path,
    routes: [
      for (final destination in MainMenuDestination.values)
        GoRoute(
          path: destination.path,
          builder: (context, state) => shellBuilder(context, destination),
        ),
    ],
    errorBuilder: (context, state) {
      return shellBuilder(context, MainMenuDestination.home);
    },
  );
}
