import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rescueeats/core/appTheme/apptheme.dart';
import 'package:rescueeats/features/routes/approute.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only for mobile platforms
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      debugPrint("✅ Firebase initialized successfully");
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } else {
      debugPrint("ℹ️ Running on web - Firebase skipped");
    }
  } catch (e) {
    debugPrint("⚠️ Firebase initialization failed: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Rescue Eats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Ensure proper text scaling and prevent oversized text on different devices
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
