// views/task_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../controllers/providers.dart';
import 'task_item.dart';

class TaskList extends ConsumerWidget {
  final List<Task> tasks;

  const TaskList({
    required this.tasks,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final filteredTasks =
        ref.read(tasksProvider.notifier).getFilteredTasks(filter);

    // Sort tasks: incomplete first, then by priority, then by due date
    final sortedTasks = [...filteredTasks]..sort((a, b) {
        // Completed tasks go to the bottom
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }

        // Sort by priority (if available)
        if (a.priority != null && b.priority != null) {
          return a.priority!.compareTo(b.priority!);
        } else if (a.priority != null) {
          return -1;
        } else if (b.priority != null) {
          return 1;
        }

        // Sort by due date (if available)
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1;
        } else if (b.dueDate != null) {
          return 1;
        }

        // Default: sort by creation time
        return b.createdAt.compareTo(a.createdAt);
      });

    if (sortedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No tasks match the filter',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try changing the filter or add new tasks',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        return TaskItem(task: sortedTasks[index]);
      },
    );
  }
}
