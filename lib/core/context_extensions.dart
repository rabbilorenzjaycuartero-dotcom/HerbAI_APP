import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Shorthand for looking up a translated string against the current
/// language, so call sites stay as short as `Text(context.tr('sign_in'))`
/// instead of threading `Provider.of` for `ThemeProvider` everywhere.
extension AppStringsX on BuildContext {
  /// For use inside a build method -- uses context.watch, so the widget
  /// rebuilds automatically when the user changes Settings -> Language.
  String tr(String key) => watch<ThemeProvider>().t(key);

  /// For use outside build (callbacks, async methods, Timer ticks), where
  /// context.watch would throw. No rebuild subscription is needed here
  /// since these call sites already trigger setState themselves.
  String trRead(String key) => read<ThemeProvider>().t(key);
}
