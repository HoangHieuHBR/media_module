import 'package:flutter/widgets.dart';
import 'package:pip_view/pip_view.dart';

enum FloatingState { full, minimized, closed }

class FloatingUtil {
  static final FloatingUtil _instance = FloatingUtil._internal();

  factory FloatingUtil() {
    return _instance;
  }

  static final ValueNotifier<FloatingState> _floatingState =
      ValueNotifier(FloatingState.closed);

  static FloatingState get state => _floatingState.value;

  static void showFull() {
    _floatingState.value = FloatingState.full;
  }

  static void minimize(BuildContext context) {
    PIPView.of(context)?.present();
    _floatingState.value = FloatingState.minimized;
  }

  static void close() {
    _floatingState.value = FloatingState.closed;
  }

  static void listen(VoidCallback callback) {
    _floatingState.addListener(callback);
  }
  
  FloatingUtil._internal();
}
