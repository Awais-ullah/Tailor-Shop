import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Keeps the hand-written translation tables consistent with English.
///
/// Missing translations fall back to English at runtime, so they are not
/// errors. They are listed in [_allowlistPath] instead: anything missing
/// that is NOT on the list fails, so new gaps are noticed. To refresh the
/// list after translating, run:
///
///   UPDATE_L10N_ALLOWLIST=1 flutter test test/translations_test.dart
const String _allowlistPath = 'test/l10n_missing_allowlist.txt';

final RegExp _placeholder = RegExp(r'\{(\w+)\}');

Set<String> _placeholders(String text) =>
    {for (final m in _placeholder.allMatches(text)) m.group(1)!};

/// 'orderCountLabel#one' -> 'orderCountLabel'.
String _base(String key) => key.split('#').first;

bool _isPlural(String key) => key.contains('#');

void main() {
  final tables = S.debugTables;
  final en = tables['en']!;
  final others = {
    for (final entry in tables.entries)
      if (entry.key != 'en') entry.key: entry.value,
  };

  test('every supported language has a table', () {
    for (final language in AppLanguage.all) {
      expect(tables.containsKey(language.code), isTrue,
          reason: 'No strings for ${language.code}');
    }
  });

  test('no language has keys that English does not have', () {
    final problems = <String>[];
    others.forEach((code, table) {
      for (final key in table.keys) {
        final known = _isPlural(key)
            ? en.containsKey('${_base(key)}#other')
            : en.containsKey(key);
        if (!known) problems.add('$code: $key');
      }
    });
    expect(problems, isEmpty,
        reason: 'Unknown keys (typo, or missing from English):\n'
            '${problems.join('\n')}');
  });

  test('placeholders match English', () {
    final problems = <String>[];
    others.forEach((code, table) {
      table.forEach((key, value) {
        final english = _isPlural(key) ? en['${_base(key)}#other'] : en[key];
        if (english == null) return;

        final expected = _placeholders(english);
        final actual = _placeholders(value);
        // A plural "one" form may spell the number out ("one order"),
        // but it must never invent a placeholder.
        final ok = _isPlural(key)
            ? expected.containsAll(actual)
            : actual.length == expected.length && actual.containsAll(expected);
        if (!ok) problems.add('$code: $key has $actual, English has $expected');
      });
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every plural has an "other" form in every language that uses it', () {
    final problems = <String>[];
    tables.forEach((code, table) {
      for (final key in table.keys.where(_isPlural)) {
        if (!table.containsKey('${_base(key)}#other')) {
          problems.add('$code: ${_base(key)}#other');
        }
      }
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('no new untranslated strings', () {
    final missing = <String>[];
    others.forEach((code, table) {
      for (final key in en.keys) {
        // Plural forms differ per language; only "other" is required.
        if (_isPlural(key) && !key.endsWith('#other')) continue;
        if (!table.containsKey(key)) missing.add('$code:$key');
      }
    });
    missing.sort();

    final file = File(_allowlistPath);
    if (Platform.environment['UPDATE_L10N_ALLOWLIST'] == '1') {
      file.writeAsStringSync('${missing.join('\n')}\n');
      return;
    }

    final allowed = file.existsSync()
        ? file
            .readAsLinesSync()
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toSet()
        : <String>{};

    final newGaps = missing.where((k) => !allowed.contains(k)).toList();
    final nowTranslated =
        allowed.where((k) => !missing.contains(k)).toList()..sort();

    expect(newGaps, isEmpty,
        reason: 'These strings have no translation. Add them to every '
            'language table:\n${newGaps.join('\n')}');
    expect(nowTranslated, isEmpty,
        reason: 'These are translated now; remove them from '
            '$_allowlistPath:\n${nowTranslated.join('\n')}');
  });
}
