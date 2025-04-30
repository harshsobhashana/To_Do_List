// controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../services/voice_command_service.dart';
import '../services/speech_service.dart';
import '../services/sync_service.dart';

// Service Providers
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

final speechToTextProvider = Provider<SpeechToText>((ref) {
  return SpeechToText();
});

final ttsProvider = Provider<FlutterTts>((ref) {
  return FlutterTts();
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final speechToText = ref.watch(speechToTextProvider);
  final tts = ref.watch(ttsProvider);
  return SpeechService(speechToText: speechToText, tts: tts);
});

final voiceCommandServiceProvider = Provider<VoiceCommandService>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  final speechService = ref.watch(speechServiceProvider);
  return VoiceCommandService(
      taskService: taskService, speechService: speechService);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return SyncService(taskService: taskService);
});

// State Providers
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TasksNotifier(taskService);
});

final listeningStateProvider = StateProvider<bool>((ref) => false);

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// For handling loading states during voice processing
final processingCommandProvider = StateProvider<bool>((ref) => false);

// Feedback message for voice interactions
final feedbackMessageProvider = StateProvider<String?>((ref) => null);

// Task state notifier
class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskService _taskService;

  TasksNotifier(this._taskService) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.getAllTasks();
    state = tasks;
  }

  Future<void> addTask(Task task) async {
    await _taskService.addTask(task);
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _taskService.updateTask(task);
    _loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
    _loadTasks();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await _taskService.updateTask(updatedTask);
    _loadTasks();
  }

  void refresh() {
    _loadTasks();
  }
}
