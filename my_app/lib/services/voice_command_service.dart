// services/voice_command_service.dart
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/task.dart';
import 'task_service.dart';
import 'speech_service.dart';

class VoiceCommandService {
  final TaskService taskService;
  final SpeechService speechService;

  VoiceCommandService({
    required this.taskService,
    required this.speechService,
  });

  Future<void> processVoiceCommand(String command) async {
    command = command.toLowerCase().trim();

    // Extract intent and entities from the command
    if (_isAddTaskCommand(command)) {
      await _handleAddTask(command);
    } else if (_isCompleteTaskCommand(command)) {
      await _handleCompleteTask(command);
    } else if (_isDeleteTaskCommand(command)) {
      await _handleDeleteTask(command);
    } else if (_isListTasksCommand(command)) {
      await _handleListTasks(command);
    } else if (_isSearchTaskCommand(command)) {
      await _handleSearchTasks(command);
    } else {
      await speechService
          .speak("I didn't understand that command. Please try again.");
    }
  }

  bool _isAddTaskCommand(String command) {
    return command.startsWith('add') ||
        command.startsWith('create') ||
        command.startsWith('new task');
  }

  bool _isCompleteTaskCommand(String command) {
    return command.contains('complete') ||
        command.contains('finish') ||
        command.contains('mark as done');
  }

  bool _isDeleteTaskCommand(String command) {
    return command.contains('delete') || command.contains('remove');
  }

  bool _isListTasksCommand(String command) {
    return command.contains('list') ||
        command.contains('show') ||
        command == 'tasks';
  }

  bool _isSearchTaskCommand(String command) {
    return command.startsWith('search') || command.startsWith('find');
  }

  Future<void> _handleAddTask(String command) async {
    // Extract task title from command
    String taskTitle = command;

    if (command.startsWith('add')) {
      taskTitle = command.substring(3).trim();
    } else if (command.startsWith('create')) {
      taskTitle = command.substring(6).trim();
    } else if (command.startsWith('new task')) {
      taskTitle = command.substring(8).trim();
    }

    // Extract optional due date if present
    DateTime? dueDate;
    final dueDatePatterns = [
      RegExp(r'due (tomorrow|today|next week|next month)'),
      RegExp(r'by (tomorrow|today|next week|next month)'),
      // Could add more sophisticated date parsing here
    ];

    for (var pattern in dueDatePatterns) {
      final match = pattern.firstMatch(taskTitle);
      if (match != null) {
        final dateStr = match.group(1);
        if (dateStr == 'today') {
          dueDate = DateTime.now();
        } else if (dateStr == 'tomorrow') {
          dueDate = DateTime.now().add(Duration(days: 1));
        } else if (dateStr == 'next week') {
          dueDate = DateTime.now().add(Duration(days: 7));
        } else if (dateStr == 'next month') {
          dueDate = DateTime.now().add(Duration(days: 30));
        }

        // Remove the date part from the task title
        taskTitle = taskTitle.replaceAll(match.group(0)!, '').trim();
        break;
      }
    }

    // Extract priority if present
    int? priority;
    final priorityPattern = RegExp(r'priority (high|medium|low)');
    final priorityMatch = priorityPattern.firstMatch(taskTitle);

    if (priorityMatch != null) {
      final priorityStr = priorityMatch.group(1);
      if (priorityStr == 'high') {
        priority = 1;
      } else if (priorityStr == 'medium') {
        priority = 2;
      } else if (priorityStr == 'low') {
        priority = 3;
      }

      // Remove the priority part from the task title
      taskTitle = taskTitle.replaceAll(priorityMatch.group(0)!, '').trim();
    }

    // Create and add the task
    final task = Task(
      title: taskTitle,
      dueDate: dueDate,
      priority: priority,
    );

    await taskService.addTask(task);
    await speechService.speak("Task added: $taskTitle");
  }

  Future<void> _handleCompleteTask(String command) async {
    // Extract task identifier
    String taskIdentifier = command;

    if (command.contains('complete')) {
      taskIdentifier = command.split('complete')[1].trim();
    } else if (command.contains('finish')) {
      taskIdentifier = command.split('finish')[1].trim();
    } else if (command.contains('mark as done')) {
      taskIdentifier = command.split('mark as done')[1].trim();
    }

    // Search for tasks matching the identifier
    final tasks = await taskService.searchTasks(taskIdentifier);

    if (tasks.isEmpty) {
      await speechService
          .speak("I couldn't find a task matching: $taskIdentifier");
    } else if (tasks.length == 1) {
      // If exactly one task matches, complete it
      final task = tasks.first.copyWith(isCompleted: true);
      await taskService.updateTask(task);
      await speechService.speak("Completed task: ${task.title}");
    } else {
      // If multiple tasks match, ask for clarification
      await speechService.speak(
          "I found multiple tasks matching: $taskIdentifier. Please be more specific.");
    }
  }

  Future<void> _handleDeleteTask(String command) async {
    // Extract task identifier
    String taskIdentifier = command;

    if (command.contains('delete')) {
      taskIdentifier = command.split('delete')[1].trim();
    } else if (command.contains('remove')) {
      taskIdentifier = command.split('remove')[1].trim();
    }

    // Search for tasks matching the identifier
    final tasks = await taskService.searchTasks(taskIdentifier);

    if (tasks.isEmpty) {
      await speechService
          .speak("I couldn't find a task matching: $taskIdentifier");
    } else if (tasks.length == 1) {
      // If exactly one task matches, delete it
      await taskService.deleteTask(tasks.first.id);
      await speechService.speak("Deleted task: ${tasks.first.title}");
    } else {
      // If multiple tasks match, ask for clarification
      await speechService.speak(
          "I found multiple tasks matching: $taskIdentifier. Please be more specific.");
    }
  }

  Future<void> _handleListTasks(String command) async {
    final tasks = await taskService.getAllTasks();

    if (tasks.isEmpty) {
      await speechService.speak("You have no tasks.");
    } else {
      final taskCount = tasks.length;
      final completedCount = tasks.where((t) => t.isCompleted).length;
      final pendingCount = taskCount - completedCount;

      String response =
          "You have $taskCount tasks. $completedCount completed and $pendingCount pending. ";

      if (pendingCount > 0) {
        response += "Your pending tasks are: ";
        final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
        for (int i = 0; i < pendingTasks.length; i++) {
          response += "${i + 1}, ${pendingTasks[i].title}. ";
        }
      }

      await speechService.speak(response);
    }
  }

  Future<void> _handleSearchTasks(String command) async {
    String query = command;

    if (command.startsWith('search')) {
      query = command.substring(6).trim();
    } else if (command.startsWith('find')) {
      query = command.substring(4).trim();
    }

    final tasks = await taskService.searchTasks(query);

    if (tasks.isEmpty) {
      await speechService.speak("I couldn't find any tasks matching: $query");
    } else {
      final taskCount = tasks.length;
      String response = "I found $taskCount tasks matching: $query. ";

      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        response +=
            "${i + 1}, ${task.title}, ${task.isCompleted ? 'completed' : 'pending'}. ";
      }

      await speechService.speak(response);
    }
  }

  Future<void> startVoiceCommand() async {
    await speechService.startListening((result) {
      if (result.finalResult) {
        processVoiceCommand(result.recognizedWords);
      }
    });
  }

  Future<void> stopVoiceCommand() async {
    await speechService.stopListening();
  }
}
