import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  static const List<String> _faDigits = <String>[
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹'
  ];

  static String toFaDigits(String input) {
    final StringBuffer sb = StringBuffer();
    for (final int code in input.runes) {
      if (code >= 48 && code <= 57) {
        sb.write(_faDigits[code - 48]);
      } else {
        sb.write(String.fromCharCode(code));
      }
    }
    return sb.toString();
  }

  static String toEnDigits(String input) {
    String out = input;
    for (int i = 0; i < _faDigits.length; i++) {
      out = out.replaceAll(_faDigits[i], i.toString());
    }
    return out;
  }

  static String localizedNumber(String languageCode, num value) {
    final String raw = value.toString();
    return languageCode == 'en' ? raw : toFaDigits(raw);
  }

  static bool isRtl(String languageCode) => languageCode == 'fa';

  static String pick(Object? node, String languageCode,
      {String fallback = ''}) {
    if (node == null) return fallback;
    if (node is String) return node;
    if (node is Map) {
      final Object? v = node[languageCode] ?? node['fa'] ?? node['en'];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return fallback;
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  static Color onColor(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

  static Color parseHex(String hex,
      {Color fallback = const Color(0xFF1E88E5)}) {
    String value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final int? parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  static void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.start),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }
}
