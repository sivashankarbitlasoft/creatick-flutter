import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: TicketApp()));
}

class TicketApp extends StatelessWidget {
  const TicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BA Ticket App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Watches auth state and shows the right screen:
/// - checking   -> splash/loading spinner (first launch, reading local storage)
/// - loggedOut  -> AuthScreen (login/signup)
/// - loggedIn   -> HomeScreen (3 tabs)
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.loggedIn:
        return const HomeScreen();
      case AuthStatus.loggedOut:
        return const AuthScreen();
    }
  }
}
