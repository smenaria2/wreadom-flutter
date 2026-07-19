import 'package:flutter_riverpod/flutter_riverpod.dart';

final showSemanticsDebuggerProvider =
    NotifierProvider<ShowSemanticsDebuggerNotifier, bool>(ShowSemanticsDebuggerNotifier.new);

class ShowSemanticsDebuggerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
