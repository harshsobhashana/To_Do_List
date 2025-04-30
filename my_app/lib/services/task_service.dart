// services/task_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final Box<Task> _taskBox = Hive.box<Task>('tasks');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userUid; // In a real app, this would come from authentication
  
  TaskService({String? userUid}) : _userUid = userUid ?? 'demo_user';
  
  CollectionReference get _tasksCollection => 
      _firestore.collection('users').doc(_userUid).collection('tasks');
  
  // Local operations
  Future<List<Task>> getAllTasks() async {
    return _taskBox.values.toList();
  }
  
  Future<Task?> getTaskById(String id) async {
    return _taskBox.values.firstWhere((task) => task.id == id);
  }
  
  Future<List<Task>> searchTasks(String query) async {
    query = query.toLowerCase();
    return _taskBox.values.where((task) => 
      task.title.toLowerCase().contains(query) || 
      (task.description?.toLowerCase().contains(query) ?? false) ||
      task.tags.any((tag) => tag.toLowerCase().contains(query))
    ).toList();
  }
  
  Future<void> addTask(Task task) async {
    // Add to local storage
    await _taskBox.put(task.id, task);
    
    // If online, sync to Firestore
    try {
      await _tasksCollection.doc(task.id).set(task.toMap());
    } catch (e) {
      // If offline, add to pending commands
      await _addPendingCommand('add', task.toMap());
    }
  }
  
  Future<void> updateTask(Task task) async {
    // Update local storage
    await _taskBox.put(task.id, task);
    
    // If online, sync to Firestore
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
    } catch (e) {
      // If offline, add to pending commands
      await _addPendingCommand('update', task.toMap());
    }
  }
  
  Future<void> deleteTask(String taskId) async {
    // Delete from local storage
    await _taskBox.delete(taskId);
    
    // If online, delete from Firestore
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      // If offline, add to pending commands
      await _addPendingCommand('delete', {'id': taskId});
    }
  }
  
  // Queue commands for offline operation
  Future<void> _addPendingCommand(String commandType, Map<String, dynamic> payload) async {
    final pendingCommandsBox = Hive.box<PendingCommand>('pendingCommands');
    final command = PendingCommand(
      commandType: commandType,
      payload: payload,
    );
    await pendingCommandsBox.put(command.id, command);
  }
  
  // Listen for real-time changes from Firestore
  Stream<List<Task>> tasksStream() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
  
  // Sync local changes with Firestore when back online
  Future<void> syncToCloud() async {
    final pendingCommandsBox = Hive.box<PendingCommand>('pendingCommands');
    final commands = pendingCommandsBox.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (var command in commands) {
      try {
        switch (command.commandType) {
          case 'add':
          case 'update':
            await _tasksCollection.doc(command.payload['id']).set(
              command.payload, 
              SetOptions(merge: true)
            );
            break;
          case 'delete':
            await _tasksCollection.doc(command.payload['id']).delete();
            break;
        }
        // Remove processed command
        await pendingCommandsBox.delete(command.key);
      } catch (e) {
        // If still offline or error, keep the command for next attempt
        print('Error syncing command: $e');
        break;
      }
    }
  }
}

