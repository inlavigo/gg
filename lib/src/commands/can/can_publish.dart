// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/gg.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_publish/gg_publish.dart';

/// Are the last changes ready to be published?
class CanPublish extends CommandCluster {
  /// Constructor
  CanPublish({
    required super.ggLog,
    super.name = 'publish',
    super.description = 'Are the last changes ready to be published?',
    super.shortDescription = 'Can publish?',
    super.stateKey = 'canPublish',
    DidCommit? didCommit,
    IsVersionPrepared? isVersionPrepared,
    Pana? pana,
    HasRightFormat? changeLogHasRightFormat,
  }) : super(
         commands: [
           isVersionPrepared ??
               IsVersionPrepared(ggLog: ggLog, treatUnpublishedAsOk: true),
           changeLogHasRightFormat ?? HasRightFormat(ggLog: ggLog),
           didCommit ?? DidCommit(ggLog: ggLog),
           pana ?? Pana(ggLog: ggLog, publishedOnly: true),
         ],
       );
}

// .............................................................................
/// A mocktail mock
class MockCanPublish extends MockDirCommand<void> implements CanPublish {}
