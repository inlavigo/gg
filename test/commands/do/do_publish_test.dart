// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/can_publish.dart';
import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late DoPublish doPublish;

  // ...........................................................................
  late CanPublish canPublish;
  late Publish publish;
  late GgState state;
  late AddVersionTag addVersionTag;
  late DoPush doPush;

  // ...........................................................................
  void mockCanPublish(bool success) => when(
        () => canPublish.exec(
          directory: d,
          ggLog: ggLog,
        ),
      ).thenAnswer((_) async {
        if (!success) {
          throw Exception('Can not publish');
        } else {
          ggLog('Can publish did pass.');
        }
      });

  void mockWasPreviouslySuccessful(bool success) => when(
        () => state.readSuccess(
          directory: d,
          key: 'doPublish',
          ggLog: ggLog,
        ),
      ).thenAnswer((_) async {
        return success;
      });

  void mockPublishIsSuccessful(bool success) => when(
        () => publish.exec(
          directory: d,
          ggLog: ggLog,
        ),
      ).thenAnswer((_) async {
        if (!success) {
          throw Exception('Publishing failed.');
        } else {
          ggLog('Publishing was successful.');
        }
      });

  void mockWriteSuccess() => when(
        () => state.writeSuccess(
          directory: d,
          key: 'doPublish',
        ),
      ).thenAnswer((_) async {
        ggLog('State was written for key "doPublish".');
      });

  void mockAddVersionTag() => when(
        () => addVersionTag.exec(
          directory: d,
          ggLog: ggLog,
        ),
      ).thenAnswer((_) async {
        ggLog('Version tag was added.');
      });

  void mockDoPush() => when(
        () => doPush.gitPush(
          directory: d,
          force: false,
        ),
      ).thenAnswer((_) async {
        ggLog('Did push.');
      });

  // ...........................................................................
  setUp(() async {
    d = await Directory.systemTemp.createTemp();
    messages.clear();

    canPublish = MockCanPublish();
    publish = MockPublish();
    state = MockGgState();
    addVersionTag = MockAddVersionTag();
    doPush = MockDoPush();

    doPublish = DoPublish(
      ggLog: ggLog,
      canPublish: canPublish,
      publish: publish,
      state: state,
      addVersionTag: addVersionTag,
      doPush: doPush,
    );

    // Mock the method to pass all methods by default
    mockCanPublish(true);
    mockWasPreviouslySuccessful(false);
    mockPublishIsSuccessful(true);
    mockWriteSuccess();
    mockAddVersionTag();
    mockDoPush();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('DoPublish', () {
    group('should log', () {
      group('»Current state is already published.«', () {
        test('when the command is called the second time', () async {
          mockWasPreviouslySuccessful(true);
          await doPublish.exec(directory: d, ggLog: ggLog);
          expect(messages.last, yellow('Current state is already published.'));
        });
      });
    });

    test('should perform a variety of steps before and after publishing',
        () async {
      await doPublish.exec(directory: d, ggLog: ggLog);
      expect(messages[0], 'Can publish did pass.');
      expect(messages[1], 'Publishing was successful.');
      expect(messages[2], 'State was written for key "doPublish".');
      expect(messages[3], 'Version tag was added.');
      expect(messages[4], 'Did push.');
    });

    test('should have a code coverage of 100%', () {
      expect(DoPublish(ggLog: ggLog), isNotNull);
    });
  });
}
