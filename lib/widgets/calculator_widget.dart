import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Small, self-contained calculator (no external math package).
class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key, required this.languageCode});

  final String languageCode;

  static Future<void> show(BuildContext context, String languageCode) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CalculatorWidget(languageCode: languageCode),
      ),
    );
  }

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _expression = '';
  String _result = '0';

  static const List<String> _keys = <String>[
    'C',
    '%',
    '⌫',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '−',
    '1',
    '2',
    '3',
    '+',
    '00',
    '0',
    '.',
    '=',
  ];

  void _press(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expression = '';
          _result = '0';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _result = _evaluate(_expression);
          }
          break;
        case '=':
          final String value = _evaluate(_expression);
          _result = value;
          if (value != 'error') _expression = value;
          break;
        default:
          _expression += key;
          _result = _evaluate(_expression);
      }
    });
  }

  /// Tokenises and evaluates + − × ÷ % with correct precedence.
  String _evaluate(String input) {
    if (input.trim().isEmpty) return '0';
    final String normalized =
        input.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');

    final List<String> tokens = <String>[];
    final StringBuffer number = StringBuffer();
    for (int i = 0; i < normalized.length; i++) {
      final String ch = normalized[i];
      if ('0123456789.'.contains(ch)) {
        number.write(ch);
      } else if ('+-*/%'.contains(ch)) {
        if (number.isEmpty && ch == '-' && tokens.isEmpty) {
          number.write(ch);
          continue;
        }
        if (number.isNotEmpty) {
          tokens.add(number.toString());
          number.clear();
        }
        tokens.add(ch);
      } else {
        return 'error';
      }
    }
    if (number.isNotEmpty) tokens.add(number.toString());
    if (tokens.isEmpty) return '0';
    if ('+-*/%'.contains(tokens.last)) tokens.removeLast();
    if (tokens.isEmpty) return '0';

    // first pass: * / %
    final List<String> pass = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      final String token = tokens[i];
      if (token == '*' || token == '/' || token == '%') {
        if (i + 1 >= tokens.length || pass.isEmpty) return 'error';
        final double left = double.tryParse(pass.removeLast()) ?? 0;
        final double right = double.tryParse(tokens[i + 1]) ?? 0;
        double value;
        if (token == '*') {
          value = left * right;
        } else if (token == '/') {
          if (right == 0) return 'error';
          value = left / right;
        } else {
          if (right == 0) return 'error';
          value = left % right;
        }
        pass.add(value.toString());
        i++;
      } else {
        pass.add(token);
      }
    }

    // second pass: + -
    double total = double.tryParse(pass.first) ?? 0;
    for (int i = 1; i < pass.length - 1; i += 2) {
      final String op = pass[i];
      final double right = double.tryParse(pass[i + 1]) ?? 0;
      if (op == '+') {
        total += right;
      } else if (op == '-') {
        total -= right;
      } else {
        return 'error';
      }
    }

    if (total.isNaN || total.isInfinite) return 'error';
    if (total == total.roundToDouble() && total.abs() < 1e15) {
      return total.toInt().toString();
    }
    return total.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
  }

  String _display(String value) =>
      widget.languageCode == 'en' ? value : Helpers.toFaDigits(value);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _display(_expression.isEmpty ? '' : _expression),
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _display(_result),
                    style: theme.textTheme.displayLarge,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemCount: _keys.length,
              itemBuilder: (BuildContext context, int index) {
                final String key = _keys[index];
                final bool isOperator =
                    <String>['÷', '×', '−', '+', '%'].contains(key);
                final bool isEquals = key == '=';
                final bool isClear = key == 'C' || key == '⌫';

                Color background = theme.cardColor;
                Color foreground = theme.colorScheme.onSurface;
                if (isOperator) {
                  background = AppColors.primary.withOpacity(0.12);
                  foreground = AppColors.primary;
                } else if (isEquals) {
                  background = AppColors.accent;
                  foreground = Colors.white;
                } else if (isClear) {
                  background = AppColors.inactive.withOpacity(0.16);
                }

                return Material(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _press(key),
                    child: Center(
                      child: Text(
                        key,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: foreground),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
