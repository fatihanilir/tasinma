import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/homes_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EvHesapApp());
}

class EvHesapApp extends StatelessWidget {
  const EvHesapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomesProvider()),
      ],
      child: MaterialApp(
        title: 'Cebinden Eve',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, HomesProvider>(
      builder: (context, auth, homes, _) {
        if (!auth.isReady) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            ),
          );
        }

        // Auth durumu değişince veri kaynağını güncelle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homes.setCloudMode(auth.isAuthenticated);
        });

        if (auth.canUseApp) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
