import 'package:flutter/services.dart';
import 'package:vuta/core/social_parser.dart';

class ClipboardService {
  static void startListening(Function(String) onUrlDetected) async {
    // Note: On Android 10+, background clipboard access is restricted.
    // This is best implemented as a foreground service or via platform channels.
    // For this prototype, we simulate periodic polling or app resume checks.
    
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final url = data!.text!;
      if (SocialParser.isLinkSupported(url)) {
        onUrlDetected(url);
      }
    }
  }
}
