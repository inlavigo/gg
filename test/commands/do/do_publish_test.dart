// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/can_publish.dart';
import 'package:gg/src/commands/did/did_publish.dart';
import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_json/gg_json.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late Directory dRemote;
  late Directory Function() dMock;
  late DoPublish doPublish;
  late CanPublish canPublish;
  late PublishedVersion publishedVersion;
  late IsVersionPrepared isVersionPrepared;

  late int successHash;
  late int needsChangeHash;
  const ggJson = GgJson();
  late Version publishedVersionValue;

  // ...........................................................................
  // Mocks
  late Publish publish;

  void mockPublishIsSuccessful(bool success) => when(
        () => publish.exec(
          directory: dMock(),
          ggLog: ggLog,
        ),
      ).thenAnswer((_) async {
        if (!success) {
          throw Exception('Publishing failed.');
        } else {
          publishedVersionValue = Version.parse('1.2.4');
          ggLog('Publishing was successful.');
        }
      });

  void mockPublishedVersion() => when(
        () => publishedVersion.get(
          directory: dMock(),
          ggLog: any(named: 'ggLog'),
        ),
      ).thenAnswer((_) async {
        return publishedVersionValue;
      });

  // ...........................................................................
  setUp(() async {
    // Create repositories
    d = await Directory.systemTemp.createTemp('local');
    await initLocalGit(d);
    dRemote = await Directory.systemTemp.createTemp('remote');
    await initRemoteGit(dRemote);
    await addRemoteToLocal(local: d, remote: dRemote);
    publishedVersionValue = Version.parse('1.2.3');

    // Clear messages
    messages.clear();

    // Setup a pubspec.yaml and a CHANGELOG.md with right versions
    await File(join(d.path, 'pubspec.yaml')).writeAsString(
      'name: gg\n\nversion: 1.2.4\n'
      'repository: https://github.com/inlavigo/gg.git',
    );

    // Prepare ChangeLog
    await File(join(d.path, 'CHANGELOG.md')).writeAsString(
      '# Changelog\n\n'
      '## Unreleased\n'
      '-Message 1\n'
      '-Message 2\n'
      '## 1.2.3 - 2024-04-05\n\n- First version',
    );

    // Create a .gg.json that has all preconditions for publishing
    needsChangeHash = 12345;

    // Mock publishing
    dMock = () => any(
          named: 'directory',
          that: predicate<Directory>((x) => x.path == d.path),
        );
    registerFallbackValue(d);
    publish = MockPublish();

    publishedVersion = MockPublishedVersion();

    isVersionPrepared = IsVersionPrepared(
      ggLog: ggLog,
      publishedVersion: publishedVersion,
    );

    canPublish = CanPublish(
      ggLog: ggLog,
      isVersionPrepared: isVersionPrepared,
    );
    mockPublishIsSuccessful(true);
    mockPublishedVersion();

    // Instantiate with mocks
    doPublish = DoPublish(
      ggLog: ggLog,
      publish: publish,
      prepareNextVersion: PrepareNextVersion(
        ggLog: ggLog,
        publishedVersion: publishedVersion,
      ),
      canPublish: canPublish,
    );

    successHash = await LastChangesHash(ggLog: ggLog).get(
      directory: d,
      ggLog: ggLog,
      ignoreFiles: GgState.ignoreFiles,
    );

    await File(join(d.path, '.gg.json')).writeAsString(
      '{"canCommit":{"success":{"hash":$successHash}},'
      '"doCommit":{"success":{"hash":$successHash}},'
      '"canPush":{"success":{"hash":$successHash}},'
      '"doPush":{"success":{"hash":$successHash}},'
      '"canPublish":{"success":{"hash":$successHash}},'
      '"doPublish":{"success":{"hash":$successHash}}}',
    );
  });

  tearDown(() async {
    await d.delete(recursive: true);
    await dRemote.delete(recursive: true);
  });

  group('DoPublish', () {
    group('exec(directory)', () {
      group('should not publish', () {
        test('when publishing was already successful', () async {
          await ggJson.writeFile(
            file: File(join(d.path, '.gg.json')),
            path: 'doPublish/success/hash',
            value: successHash,
          );

          await doPublish.exec(
            directory: d,
            ggLog: ggLog,
          );
          expect(messages[0], yellow('Current state is already published.'));
        });
      });
      group('should publish', () {
        group('to pub.dev', () {
          test('when no »publish_to: none« is found in pubspec.yaml', () async {
            // Mock needing publish
            await ggJson.writeFile(
              file: File(join(d.path, '.gg.json')),
              path: 'doPublish/success/hash',
              value: needsChangeHash,
            );

            // Publish
            await doPublish.exec(
              directory: d,
              ggLog: ggLog,
            );

            // Were the steps performed?
            var i = 0;
            expect(messages[i++], contains('Can publish?'));
            expect(messages[i++], contains('✅ Everything is fine.'));
            expect(messages[i++], contains('Publishing was successful.'));
            expect(messages[i++], contains('Tag 1.2.4 added.'));
            expect(messages[i++], contains('⌛️ Increase version'));
            expect(messages[i++], contains('✅ Increase version'));

            // Was a new version created?
            final pubspec =
                await File(join(d.path, 'pubspec.yaml')).readAsString();
            final changeLog =
                await File(join(d.path, 'CHANGELOG.md')).readAsString();
            expect(pubspec, contains('version: 1.2.5'));
            expect(changeLog, contains('## [1.2.4] -'));

            // Was the new version checked in?
            final headMessage = await HeadMessage(ggLog: ggLog).get(
              directory: d,
              ggLog: ggLog,
            );
            expect(headMessage, 'Prepare development of version 1.2.5');

            // Was .gg.json updated in a way that didCommit,
            // didPush and didPublish return true?
            expect(
              await DidCommit(ggLog: ggLog).get(directory: d, ggLog: ggLog),
              isTrue,
            );

            expect(
              await DidPush(ggLog: ggLog).get(directory: d, ggLog: ggLog),
              isTrue,
            );

            expect(
              await DidPublish(ggLog: ggLog).get(directory: d, ggLog: ggLog),
              isTrue,
            );
          });
        });
      });
    });

    test('should have a code coverage of 100%', () {
      expect(DoPublish(ggLog: ggLog), isNotNull);
    });
  });
}
