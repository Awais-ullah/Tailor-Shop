import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The data layer holds models, repositories and pure logic. It must not
/// depend on widgets or the theme, so stored ids are never tied to icons
/// or colours and the logic stays testable without a UI.
const List<String> _banned = [
  'package:flutter/material.dart',
  'package:flutter/widgets.dart',
  'package:flutter/cupertino.dart',
  'core/theme/',
];

void main() {
  test('nothing under features/*/data imports UI or theme code', () {
    final problems = <String>[];
    final features = Directory('lib/features');

    for (final entity in features.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!entity.path.contains(
        '${Platform.pathSeparator}data'
        '${Platform.pathSeparator}',
      )) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('import ')) continue;
        for (final banned in _banned) {
          if (line.contains(banned)) {
            problems.add('${entity.path}:${i + 1}  $line');
          }
        }
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'Move icons, colours and widgets to presentation/:\n'
          '${problems.join('\n')}',
    );
  });
}
