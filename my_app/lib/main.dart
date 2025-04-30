// TaskFlow - Voice-Driven To-Do List App
// Main application file

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/task.dart';
import 'services/voice_command_service.dart';
import 'services/task_service.dart';
import 'services/speech_service.dart';
import 'services/sync_service.dart';
import 'views/home_screen.dart';
import 'controllers/providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(PendingCommandAdapter());
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<PendingCommand>('pendingCommands');

  // Initialize services
  final speechToText = SpeechToText();
  await speechToText.initialize();

  final flutterTts = FlutterTts();
  await flutterTts.setLanguage("en-US");
  await flutterTts.setSpeechRate(0.5);

  runApp(
    ProviderScope(
      child: TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for connectivity changes and sync when back online
    ref.listen<AsyncValue<ConnectivityResult>>(connectivityProvider,
        (previous, current) {
      if (previous?.value == ConnectivityResult.none &&
          current.value != ConnectivityResult.none) {
        // Back online - process pending commands
        ref.read(syncServiceProvider).processPendingCommands();
      }
    });

    return MaterialApp(
      title: 'TaskFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}
