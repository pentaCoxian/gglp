import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/timeline_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/timeline',
    routes: [
      GoRoute(
        path: '/timeline',
        builder: (_, __) => const TimelineScreen(),
      ),
    ],
  );
});
