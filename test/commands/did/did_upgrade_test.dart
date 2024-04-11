// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late MockDidPublish didPublish;
  late DidUpgrade didUpgrade;
  late CommandRunner<void> runner;

  final messages = <String>[];
  final ggLog = messages.add;

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    registerFallbackValue(d);
    didPublish = MockDidPublish();
    didUpgrade = DidUpgrade(ggLog: ggLog, didPublish: didPublish);
    runner = CommandRunner<void>('test', 'test')..addCommand(didUpgrade);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  // ...........................................................................
  group('DidUpgrade', () {
    group('should throw', () {
      group('when not everything is published', () {
        for (final way in ['programmatically', 'via CLI']) {
          test(way, () async {
            didPublish.mockSuccess(false);
            late String exception;
            try {
              if (way == 'programmatically') {
                await didUpgrade.exec(directory: d, ggLog: ggLog);
              } else {
                await runner.run(['upgrade', '-i', d.path]);
              }
            } catch (e) {
              exception = e.toString();
            }
            expect(exception, contains('❌ Everything is published'));
          });
        }
      });
    });

    group('should succeed', () {
      group('when everything is published', () {
        for (final way in ['programmatically', 'via CLI']) {
          test(way, () async {
            didPublish.mockSuccess(true);
            await didUpgrade.exec(directory: d, ggLog: ggLog);
            expect(messages.last, '✅ Everything is published');
          });
        }
      });
    });

    group('special cases', () {
      test('initialized with default arguments', () {
        final didUpgrade = DidUpgrade(ggLog: ggLog);
        expect(didUpgrade.name, 'upgrade');
        expect(
          didUpgrade.description,
          'Are the dependencies of the package upgraded?',
        );
      });
    });
  });
}
