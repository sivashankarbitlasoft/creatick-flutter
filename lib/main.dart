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
    const brandPrimary = Color(0xFF4F6BFF);
    const brandDark = Color(0xFF2E3A59);
    const brandMuted = Color(0xFF6E7A95);
    const pageBg = Color(0xFFF4F5FA);
    const cardBg = Colors.white;

    return MaterialApp(
      title: 'BA Ticket App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPrimary,
          primary: brandPrimary,
          onPrimary: Colors.white,
          surface: cardBg,
          onSurface: brandDark,
          onSurfaceVariant: brandMuted,
          secondary: brandPrimary,
          tertiary: const Color(0xFF2E9E5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: pageBg,
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: cardBg,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintStyle: TextStyle(color: Color(0xFFB5B9C9), fontSize: 15),
          labelStyle: TextStyle(color: brandDark),
          floatingLabelStyle: TextStyle(color: brandPrimary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFCAD3F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFCAD3F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: brandPrimary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.red, width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.red, width: 1.8),
          ),
          prefixIconColor: brandMuted,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brandPrimary,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBg,
          foregroundColor: brandDark,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class MyApp extends TicketApp {
  const MyApp({super.key});
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
