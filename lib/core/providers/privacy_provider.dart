import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the privacy blur mode across the app.
/// When enabled, sensitive content (medication names, cycle day) is blurred.
/// A long-press on any [PrivacyBlur] widget disables the blur for that session.
class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setFalse() => state = false;
}

final privacyModeProvider =
    NotifierProvider<PrivacyModeNotifier, bool>(PrivacyModeNotifier.new);
