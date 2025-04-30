// views/voice_feedback_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/providers.dart';

class VoiceFeedbackBanner extends ConsumerWidget {
  final String message;
  
  const VoiceFeedbackBanner({
    required this.message,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Theme.of(context).primaryColorLight,
      child: Row(
        children: [
          Icon(Icons.record_voice_over),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () {
              ref.read(feedbackMessageProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }
}