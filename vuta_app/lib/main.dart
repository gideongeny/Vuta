import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/features/home/home_screen.dart';
import 'package:vuta/services/ads_service.dart';
import 'package:vuta/services/background_tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'VUTA';
  await AdsService.instance.init();
  BackgroundTaskService.init();
  
  runApp(
    const ProviderScope(
      child: VutaApp(),
    ),
  );
}

class VutaApp extends StatelessWidget {
  const VutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VUTA',
      debugShowCheckedModeBanner: false,
      theme: VutaTheme.darkTheme(context),
      home: const HomeScreen(),
    );
  }
}
