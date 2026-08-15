import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';

import 'providers/book_provider.dart';
import 'providers/reading_provider.dart';
import 'screens/home_screen.dart';

void main() {
  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: true,
  );
  runApp(const KidsEnglishApp());
}

class KidsEnglishApp extends StatelessWidget {
  const KidsEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
      ],
      child: MaterialApp(
        title: '영어 동화 읽기',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.orange,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
