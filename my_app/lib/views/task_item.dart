// views/task_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../controllers/providers.dart';

class TaskItem extends ConsumerWidget {
  final Task task;

  const TaskItem({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('task_${task.id}'),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.check, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _showDeleteConfirmation(context, ref);
        } else {
          ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                task.isCompleted ? 'Task marked incomplete' : 'Task completed'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Show task details or edit
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                _buildPriorityIndicator(),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      if (_buildSubtitle(context) != null) ...[
                        SizedBox(height: 4),
                        _buildSubtitle(context)!,
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context, ref),
                      tooltip: 'Delete Task',
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: (bool? value) {
                          ref
                              .read(tasksProvider.notifier)
                              .toggleTaskCompletion(task.id);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(tasksProvider.notifier).deleteTask(task.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task deleted'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        ref.read(tasksProvider.notifier).undoDelete();
                      },
                    ),
                  ),
                );
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityIndicator() {
    if (task.priority == null) {
      return Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    Color color;
    switch (task.priority) {
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.orange;
        break;
      case 3:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    if (task.dueDate == null &&
        (task.description == null || task.description!.isEmpty)) {
      return null;
    }

    final parts = <Widget>[];

    if (task.dueDate != null) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dueDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);

      String dueDateText;
      Color dueDateColor;

      if (dueDate.difference(DateTime(now.year, now.month, now.day)).inDays ==
          0) {
        dueDateText = 'Today';
        dueDateColor = Colors.red;
      } else if (dueDate
              .difference(DateTime(now.year, now.month, now.day))
              .inDays ==
          1) {
        dueDateText = 'Tomorrow';
        dueDateColor = Colors.orange;
      } else {
        dueDateText = DateFormat('MMM d').format(dueDate);
        dueDateColor = Colors.grey;
      }

      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: dueDateColor),
            SizedBox(width: 4),
            Text(
              dueDateText,
              style: TextStyle(
                fontSize: 12,
                color: dueDateColor,
              ),
            ),
          ],
        ),
      );
    }

    if (task.description != null && task.description!.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add(
          Text(
            ' • ',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      parts.add(
        Text(
          task.description!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Row(
      children: parts,
    );
  }
}
