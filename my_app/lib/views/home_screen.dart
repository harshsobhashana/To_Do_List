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
        title: Text('TaskFlow'),
        actions: [
          ConnectivityStatusIndicator(),
        ],
      ),
      body: Column(
        children: [
          // Feedback banner for voice commands
          if (feedbackMessage != null)
            VoiceFeedbackBanner(message: feedbackMessage),
          
          // Task list - main content
          Expanded(
            child: tasks.isEmpty 
              ? Center(child: Text('No tasks yet. Try adding one with your voice!'))
              : TaskList(tasks: tasks),
          ),
        ],
      ),
      floatingActionButton: VoiceCommandButton(
        isListening: isListening,
        isProcessing: isProcessing,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoButton(context),
            SizedBox(width: 48), // Space for the FAB
            _buildFilterButton(context),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
    return IconButton(
      icon: Icon(Icons.filter_list),
      tooltip: 'Filter Tasks',
      onPressed: () {
        // Show filter options
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
              _buildHelpItem(context, 'Add with due date', 'Add call mom due tomorrow'),
              _buildHelpItem(context, 'Add with priority', 'Add finish report priority high'),
              _buildHelpItem(context, 'Complete a task', 'Complete buy groceries'),
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
          Text('Example: "$example"', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

