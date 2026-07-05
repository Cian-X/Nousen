import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Typography guardrails', () {
    final RegExp hardcodedFontSizePattern = RegExp(
      r'fontSize\s*:\s*\d+(\.\d+)?',
    );
    final RegExp heavyFontWeightPattern = RegExp(r'FontWeight\.w(800|900)');

    const Set<String> allowHardcodedFontSize = <String>{
      'lib/core/theme/app_theme.dart',
    };
    const Set<String> allowHeavyFontWeight = <String>{
      'lib/core/theme/app_theme.dart',
    };

    test('no hardcoded fontSize outside theme', () {
      final List<String> violations = <String>[];
      for (final File file in _dartFilesUnderLib()) {
        final String path = _normalizePath(file.path);
        if (allowHardcodedFontSize.contains(path)) {
          continue;
        }
        final String content = file.readAsStringSync();
        final Iterable<RegExpMatch> matches = hardcodedFontSizePattern
            .allMatches(content);
        for (final RegExpMatch match in matches) {
          final int line = _lineForOffset(content, match.start);
          violations.add('$path:$line -> ${match.group(0)}');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Use theme text tokens instead of hardcoded fontSize.\n${violations.join('\n')}',
      );
    });

    test('no FontWeight.w800/w900 outside theme', () {
      final List<String> violations = <String>[];
      for (final File file in _dartFilesUnderLib()) {
        final String path = _normalizePath(file.path);
        if (allowHeavyFontWeight.contains(path)) {
          continue;
        }
        final String content = file.readAsStringSync();
        final Iterable<RegExpMatch> matches = heavyFontWeightPattern.allMatches(
          content,
        );
        for (final RegExpMatch match in matches) {
          final int line = _lineForOffset(content, match.start);
          violations.add('$path:$line -> ${match.group(0)}');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Avoid extra-heavy weights in feature pages.\n${violations.join('\n')}',
      );
    });

    test('theme contains required role tokens', () {
      final String content = File(
        'lib/core/theme/app_theme.dart',
      ).readAsStringSync();

      expect(
        RegExp(
          r'titleLarge:\s*baseText\.titleLarge\?\.copyWith\([\s\S]*?fontSize:\s*21[\s\S]*?fontWeight:\s*FontWeight\.w700',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'titleMedium:\s*baseText\.titleMedium\?\.copyWith\([\s\S]*?fontSize:\s*17[\s\S]*?fontWeight:\s*FontWeight\.w600',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'titleSmall:\s*baseText\.titleSmall\?\.copyWith\([\s\S]*?fontSize:\s*16[\s\S]*?fontWeight:\s*FontWeight\.w600',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'headlineSmall:\s*baseText\.headlineSmall\?\.copyWith\([\s\S]*?fontSize:\s*24[\s\S]*?fontWeight:\s*FontWeight\.w700',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'bodyMedium:\s*baseText\.bodyMedium\?\.copyWith\([\s\S]*?fontSize:\s*14[\s\S]*?fontWeight:\s*FontWeight\.w400',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'bodySmall:\s*baseText\.bodySmall\?\.copyWith\([\s\S]*?fontSize:\s*13[\s\S]*?fontWeight:\s*FontWeight\.w400[\s\S]*?color:\s*secondaryText',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'labelLarge:\s*baseText\.labelLarge\?\.copyWith\([\s\S]*?fontSize:\s*15[\s\S]*?fontWeight:\s*FontWeight\.w500',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
      expect(
        RegExp(
          r'labelSmall:\s*baseText\.labelSmall\?\.copyWith\([\s\S]*?fontSize:\s*12[\s\S]*?fontWeight:\s*FontWeight\.w500[\s\S]*?color:\s*secondaryText',
          multiLine: true,
        ).hasMatch(content),
        isTrue,
      );
    });
  });
}

Iterable<File> _dartFilesUnderLib() sync* {
  final Directory root = Directory('lib');
  if (!root.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String path = _normalizePath(entity.path);
    if (path.contains('/generated/') ||
        path.contains('/l10n/') ||
        path.endsWith('.g.dart')) {
      continue;
    }
    yield entity;
  }
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

int _lineForOffset(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;
