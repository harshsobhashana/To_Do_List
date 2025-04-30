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
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.check, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Delete task
          ref.read(tasksProvider.notifier).deleteTask(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task deleted'))
          );
        } else {
          // Mark as completed
          ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(task.isCompleted ? 'Task marked incomplete' : 'Task completed'))
          );
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: _buildPriorityIndicator(),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: _buildSubtitle(context),
          trailing: Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) {
              ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
            },
          ),
          onTap: () {
            // Show task details or edit
          },
        ),
      ),
    );
  }
  
  Widget _buildPriorityIndicator() {
    if (task.priority == null) {
      return Icon(Icons.circle, color: Colors.grey, size: 16);
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
    
    return Icon(Icons.circle, color: color, size: 16);
  }
  
  Widget? _buildSubtitle(BuildContext context) {
    if (task.dueDate == null && (task.description == null || task.description!.isEmpty)) {
      return null;
    }
    
    final parts = <String>[];
    
    if (task.dueDate != null) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      
      String dueDateText;
      if (dueDate.difference(DateTime(now.year, now.month, now.day)).inDays == 0) {
        dueDateText = 'Today';
      } else if (dueDate.difference(DateTime(now.year, now.month, now.day)).inDays == 1) {
        dueDateText = 'Tomorrow';
      } else {
        dueDateText = DateFormat('MMM d').format(dueDate);
      }
      
      parts.add('Due: $dueDateText');
    }
    
    if (task.description != null && task.description!.isNotEmpty) {
      parts.add(task.description!);
    }
    
    return Text(parts.join(' • '));
  }
}



