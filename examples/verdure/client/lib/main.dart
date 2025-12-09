// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/logging.dart';
import 'core/theme/theme.dart';
import 'features/screens/order_confirmation_screen.dart';
import 'features/screens/presentation_screen.dart';
import 'features/screens/questionnaire_screen.dart';
import 'features/screens/shopping_cart_screen.dart';
import 'features/screens/upload_photo_screen.dart';
import 'features/screens/welcome_screen.dart';
import 'features/widgets/app_navigator.dart';
import 'features/widgets/global_progress_indicator.dart';

void main() {
  initLogging();
  runApp(const ProviderScope(child: VerdureApp()));
}

class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    appLogger.info('GoRouter didPush: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    appLogger.info('GoRouter didPop: ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    appLogger.info('GoRouter didRemove: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    appLogger.info('GoRouter didReplace: ${newRoute?.settings.name}');
  }
}

final _router = GoRouter(
  observers: [GoRouterObserver()],
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(
      path: '/upload_photo',
      builder: (context, state) => const UploadPhotoScreen(),
    ),
    GoRoute(
      path: '/questionnaire',
      builder: (context, state) => const QuestionnaireScreen(),
    ),
    GoRoute(
      path: '/presentation',
      builder: (context, state) => const PresentationScreen(),
    ),
    GoRoute(
      path: '/shopping_cart',
      builder: (context, state) => const ShoppingCartScreen(),
    ),
    GoRoute(
      path: '/order_confirmation',
      builder: (context, state) => const OrderConfirmationScreen(),
    ),
  ],
);

class VerdureApp extends ConsumerWidget {
  const VerdureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Verdure',
      themeMode: ThemeMode.light,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: _router,
      builder: (context, child) => GlobalProgressIndicator(
        child: AppNavigator(router: _router, child: child!),
      ),
    );
  }
}
