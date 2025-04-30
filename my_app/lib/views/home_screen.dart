// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/providers.dart';
import '../models/task.dart';
import 'task_list.dart';
import 'voice_command_button.dart';
import 'connectivity_status.dart';
import 'voice_feedback_banner.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final isProcessing = ref.watch(processingCommandProvider);
    final feedbackMessage = ref.watch(feedbackMessageProvider);
    final isListening = ref.watch(listeningStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TaskFlow',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          ConnectivityStatusIndicator(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            if (feedbackMessage != null)
              VoiceFeedbackBanner(message: feedbackMessage),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tasks yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add a task using voice or manually',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : TaskList(tasks: tasks),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'manual_add',
            onPressed: () => _showAddTaskDialog(context, ref),
            child: Icon(Icons.add),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: 16),
          VoiceCommandButton(
            isListening: isListening,
            isProcessing: isProcessing,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoButton(context),
            SizedBox(width: 48),
            _buildFilterButton(context),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    int selectedPriority = 2; // Default to medium priority
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text('High')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('Low')),
                  ],
                  onChanged: (value) {
                    selectedPriority = value!;
                  },
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Due Date'),
                  subtitle: Text(dueDate == null
                      ? 'Not set'
                      : dueDate.toString().split(' ')[0]),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      dueDate = pickedDate;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    priority: selectedPriority,
                    dueDate: dueDate,
                    isCompleted: false,
                    createdAt: DateTime.now(),
                  );
                  ref.read(tasksProvider.notifier).addTask(task);
                  Navigator.pop(context);
                }
              },
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.info_outline),
      tooltip: 'Voice Command Help',
      onPressed: () {
        _showVoiceCommandHelp(context);
      },
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentFilter = ref.watch(filterProvider);

        return PopupMenuButton<PriorityFilter>(
          icon: Icon(
            Icons.filter_list,
            color: currentFilter != PriorityFilter.all
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          tooltip: 'Filter Tasks',
          onSelected: (PriorityFilter filter) {
            ref.read(filterProvider.notifier).state = filter;
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<PriorityFilter>>[
            PopupMenuItem<PriorityFilter>(
              value: PriorityFilter.all,
              child: Row(
                children: [
                  Icon(Icons.all_inclusive, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('All Tasks'),
                ],
              ),
            ),
            PopupMenuItem<PriorityFilter>(
              value: PriorityFilter.high,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('High Priority'),
                ],
              ),
            ),
            PopupMenuItem<PriorityFilter>(
              value: PriorityFilter.medium,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text('Medium Priority'),
                ],
              ),
            ),
            PopupMenuItem<PriorityFilter>(
              value: PriorityFilter.low,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Low Priority'),
                ],
              ),
            ),
            PopupMenuItem<PriorityFilter>(
              value: PriorityFilter.none,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.grey, size: 16),
                  SizedBox(width: 8),
                  Text('No Priority'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVoiceCommandHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Command Examples',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              _buildHelpItem(context, 'Add a task', 'Add buy groceries'),
              _buildHelpItem(
                  context, 'Add with due date', 'Add call mom due tomorrow'),
              _buildHelpItem(context, 'Add with priority',
                  'Add finish report priority high'),
              _buildHelpItem(
                  context, 'Complete a task', 'Complete buy groceries'),
              _buildHelpItem(context, 'Delete a task', 'Delete call mom'),
              _buildHelpItem(context, 'List all tasks', 'Show my tasks'),
              _buildHelpItem(context, 'Search tasks', 'Find groceries'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String example) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text('Example: "$example"',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
