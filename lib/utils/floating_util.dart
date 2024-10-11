import 'package:flutter/widgets.dart';
import 'package:pip_view/pip_view.dart';

class FloatingUtil {
  static final FloatingUtil _instance = FloatingUtil._internal();

  factory FloatingUtil() {
    return _instance;
  }

  static final ValueNotifier<bool> _isFloatingShown = ValueNotifier(false);

  static bool get isShown => _isFloatingShown.value;

  static void showFull() {
    _isFloatingShown.value = true;
  }

  static void minimize(BuildContext context) {
    PIPView.of(context)?.present();
  }

  static void close() {
    _isFloatingShown.value = false;
  }

  static void listen(VoidCallback callback) {
    _isFloatingShown.addListener(callback);
  }

  FloatingUtil._internal();
}
