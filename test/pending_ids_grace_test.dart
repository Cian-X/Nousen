import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nousen/app/providers.dart';

/// Grace badge pending (keputusan owner, uji device 2026-10-18): badge amber
/// hanya tampil kalau tulisan belum di-ACK server lebih lama dari
/// [pendingBadgeGrace] — online normal (ACK cepat) tidak pernah tampil,
/// offline/lambat tampil dan bertahan sampai ACK.
void main() {
  group('pendingIdsWithGrace', () {
    const Duration grace = Duration(milliseconds: 150);

    late StreamController<Set<String>> source;
    late List<Set<String>> emitted;
    late List<Object> errors;
    late StreamSubscription<Set<String>> sub;

    setUp(() {
      source = StreamController<Set<String>>();
      emitted = <Set<String>>[];
      errors = <Object>[];
      sub = pendingIdsWithGrace(source.stream, grace: grace).listen(
        emitted.add,
        onError: errors.add,
      );
    });

    tearDown(() async {
      await sub.cancel();
      await source.close();
    });

    test('ACK cepat (online normal): badge tidak pernah tampil', () async {
      source.add(<String>{'p1'});
      await Future<void>.delayed(const Duration(milliseconds: 40));
      source.add(const <String>{});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(emitted, isEmpty);
    });

    test('pending > grace (offline/lambat): badge tampil dan bertahan',
        () async {
      source.add(<String>{'p1'});
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(emitted, <Set<String>>[
        <String>{'p1'},
      ]);

      // Snapshot berikutnya dengan pending sama: tidak menggandakan emisi.
      source.add(<String>{'p1'});
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitted, hasLength(1));
    });

    test('ACK setelah badge tampil: badge langsung hilang', () async {
      source.add(<String>{'p1'});
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(emitted, hasLength(1));

      source.add(const <String>{});
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitted, hasLength(2));
      expect(emitted.last, isEmpty);
    });

    test('satu id ACK cepat, id lain tetap pending: hanya yang pending tampil',
        () async {
      source.add(<String>{'p1', 'p2'});
      await Future<void>.delayed(const Duration(milliseconds: 60));
      source.add(<String>{'p2'});
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(emitted, <Set<String>>[
        <String>{'p2'},
      ]);
    });

    test('error source diteruskan apa adanya', () async {
      source.addError(StateError('cloud down'));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
    });
  });
}
