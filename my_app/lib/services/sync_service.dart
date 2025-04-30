// services/sync_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'task_service.dart';

class SyncService {
  final TaskService taskService;
  
  SyncService({required this.taskService});
  
  Future<void> processPendingCommands() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    
    if (connectivityResult != ConnectivityResult.none) {
      await taskService.syncToCloud();
    }
  }
  
  // Initialize listeners for online/offline state
  void initialize() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        processPendingCommands();
      }
    });
  }
}