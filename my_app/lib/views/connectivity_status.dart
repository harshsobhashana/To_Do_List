// views/connectivity_status.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controllers/providers.dart';

class ConnectivityStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    
    return connectivityAsync.when(
      data: (ConnectivityResult result) {
        final bool isOnline = result != ConnectivityResult.none;
        return Padding(
          padding: EdgeInsets.only(right: 16),
          child: Tooltip(
            message: isOnline ? 'Online' : 'Offline - Changes will sync when connection is restored',
            child: Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: isOnline ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => Icon(Icons.error),
    );
  }
}