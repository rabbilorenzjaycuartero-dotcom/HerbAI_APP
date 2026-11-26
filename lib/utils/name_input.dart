import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../core/context_extensions.dart';

/// Shared rules for a person's name (Create Account "Full Name" and Edit
/// Profile "Display Name"): letters only -- including accented letters such
/// as the ñ in "Peña" -- plus space, period ("Juan D. Cruz"), apostrophe and
/// hyphen, with the first letter of every word capitalized.

const _allowedChars = r"A-Za-zÀ-ÖØ-öø-ÿ .'\-";
final _allowedPattern = RegExp('^[$_allowedChars]*\$');
final _letter = RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ]");

/// Title-cases [text] without changing its length: the first letter of each
/// word is uppercased and the rest lowercased. A new word starts after a
/// space, hyphen or apostrophe ("dela-cruz" -> "Dela-Cruz").
String _titleCase(String text) {
  final out = StringBuffer();
  var startOfWord = true;
  for (final ch in text.split('')) {
    if (_letter.hasMatch(ch)) {
      out.write(startOfWord ? ch.toUpperCase() : ch.toLowerCase());
      startOfWord = false;
    } else {
      out.write(ch);
      startOfWord = ch == ' ' || ch == '-' || ch == "'";
    }
  }
  return out.toString();
}

class _TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Same length as the input, so the cursor/selection stays valid as-is.
    return newValue.copyWith(text: _titleCase(newValue.text));
  }
}

/// Blocks numbers and symbols (typed or pasted), then title-cases.
final List<TextInputFormatter> nameInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp('[$_allowedChars]')),
  _TitleCaseFormatter(),
];

/// Final clean-up before saving: trim, collapse repeated spaces, title-case.
String normalizeName(String name) =>
    _titleCase(name.trim().replaceAll(RegExp(r'\s+'), ' '));

/// Form validator for a full name.
String? validateName(String? value, BuildContext context) {
  final name = (value ?? '').trim();
  if (name.isEmpty) return context.trRead('please_enter_name');
  if (!_allowedPattern.hasMatch(name)) return context.trRead('name_letters_only');
  if (_letter.allMatches(name).length < 2) return context.trRead('name_too_short');
  return null;
}
