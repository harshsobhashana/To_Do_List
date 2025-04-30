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

// Filter state provider
final filterProvider =
    StateProvider<PriorityFilter>((ref) => PriorityFilter.all);

enum PriorityFilter {
  all,
  high,
  medium,
  low,
  none,
}

// Task state notifier
class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskService _taskService;
  Task? _lastDeletedTask;

  TasksNotifier(this._taskService) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.getAllTasks();
    state = tasks;
  }

  List<Task> getFilteredTasks(PriorityFilter filter) {
    if (filter == PriorityFilter.all) return state;

    return state.where((task) {
      switch (filter) {
        case PriorityFilter.high:
          return task.priority == 1;
        case PriorityFilter.medium:
          return task.priority == 2;
        case PriorityFilter.low:
          return task.priority == 3;
        case PriorityFilter.none:
          return task.priority == null;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> addTask(Task task) async {
    // Update state immediately
    state = [...state, task];

    // Then sync with backend
    try {
      await _taskService.addTask(task);
    } catch (e) {
      // If sync fails, revert the state
      state = state.where((t) => t.id != task.id).toList();
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    // Update state immediately
    state = state.map((t) => t.id == task.id ? task : t).toList();

    // Then sync with backend
    try {
      await _taskService.updateTask(task);
    } catch (e) {
      // If sync fails, reload the state
      _loadTasks();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    // Store the task for potential undo
    _lastDeletedTask = state.firstWhere((t) => t.id == taskId);

    // Update state immediately
    state = state.where((t) => t.id != taskId).toList();

    // Then sync with backend
    try {
      await _taskService.deleteTask(taskId);
    } catch (e) {
      // If sync fails, revert the state
      state = [...state, _lastDeletedTask!];
      rethrow;
    }
  }

  Future<void> undoDelete() async {
    if (_lastDeletedTask != null) {
      // Restore the task
      state = [...state, _lastDeletedTask!];

      // Then sync with backend
      try {
        await _taskService.addTask(_lastDeletedTask!);
        _lastDeletedTask = null;
      } catch (e) {
        // If sync fails, remove the task again
        state = state.where((t) => t.id != _lastDeletedTask!.id).toList();
        rethrow;
      }
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    // Update state immediately
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();

    // Then sync with backend
    try {
      final task = state.firstWhere((t) => t.id == taskId);
      await _taskService.updateTask(task);
    } catch (e) {
      // If sync fails, reload the state
      _loadTasks();
      rethrow;
    }
  }

  void refresh() {
    _loadTasks();
  }
}
