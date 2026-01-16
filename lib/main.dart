import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/authentication/splash_screen.dart';
import 'package:ncc_cadet/firebase_options.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CadetHub',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
