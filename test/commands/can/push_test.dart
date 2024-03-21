// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_check/gg_check.dart';
import 'package:gg_check/src/commands/can/push.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_publish/gg_publish.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late CheckCommands commands;
  final messages = <String>[];
  late Push push;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.isCommitted.run(directory: d)).thenAnswer((_) async {
      messages.add('did commit');
    });
    when(() => commands.isUpgraded.run(directory: d)).thenAnswer((_) async {
      messages.add('did upgrade');
    });
  }

  // ...........................................................................
  setUp(() {
    commands = CheckCommands(
      log: messages.add,
      isCommitted: MockIsCommited(),
      isUpgraded: MockIsUpgraded(),
    );

    push = Push(log: messages.add, checkCommands: commands);
    d = Directory.systemTemp.createTempSync();
    mockCommands();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('Can', () {
    group('constructor', () {
      test('with defaults', () {
        final c = Push(log: messages.add);
        expect(c.name, 'push');
        expect(c.description, 'Checks if code is ready to push.');
      });
    });

    group('Push', () {
      group('run(directory)', () {
        test('should check if everything is upgraded and commited', () async {
          await push.run(directory: d);
          expect(messages[0], 'did upgrade');
          expect(messages[1], 'did commit');
        });
      });
    });
  });
}
