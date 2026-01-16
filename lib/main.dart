import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/authentication/splash_screen.dart';
import 'package:ncc_cadet/firebase_options.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/common/connectivity_wrapper.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
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
        builder: (context, child) => ConnectivityWrapper(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child ?? const SizedBox(),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
