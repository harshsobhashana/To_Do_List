// views/voice_command_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/providers.dart';

class VoiceCommandButton extends ConsumerWidget {
  final bool isListening;
  final bool isProcessing;

  const VoiceCommandButton({
    required this.isListening,
    required this.isProcessing,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: isProcessing ? null : () => _toggleListening(ref),
      tooltip: isListening ? 'Stop Listening' : 'Start Voice Command',
      backgroundColor: _getButtonColor(),
      child: _getButtonIcon(),
    );
  }

  void _toggleListening(WidgetRef ref) async {
    final voiceCommandService = ref.read(voiceCommandServiceProvider);
    final isCurrentlyListening = ref.read(listeningStateProvider);

    if (isCurrentlyListening) {
      await voiceCommandService.stopVoiceCommand();
      ref.read(listeningStateProvider.notifier).update((state) => false);
    } else {
      ref.read(processingCommandProvider.notifier).update((state) => true);

      try {
        // Start listening for voice commands
        await voiceCommandService.startVoiceCommand();
        ref.read(listeningStateProvider.notifier).update((state) => true);
      } catch (e) {
        // Show error feedback if unable to start listening
        ref.read(feedbackMessageProvider.notifier).update((state) =>
            "Couldn't start voice recognition. Please check microphone permissions.");

        // Clear feedback after a delay
        Future.delayed(Duration(seconds: 3), () {
          ref.read(feedbackMessageProvider.notifier).update((state) => null);
        });
      } finally {
        ref.read(processingCommandProvider.notifier).update((state) => false);
      }
    }
  }

  Color _getButtonColor() {
    if (isProcessing) {
      return Colors.grey;
    } else if (isListening) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  Widget _getButtonIcon() {
    if (isProcessing) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    } else if (isListening) {
      return Icon(Icons.mic, color: Colors.white);
    } else {
      return Icon(Icons.mic_none, color: Colors.white);
    }
  }
}
