// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';

/// Are the last changes ready for »git commit«?
class CanCommit extends CommandCluster {
  /// Constructor
  CanCommit({
    required super.ggLog,
    Checks? checks,
    super.name = 'commit',
    super.description = 'Are the last changes ready for »git commit«?',
    super.shortDescription = 'Can commit?',
    super.stateKey = 'canCommit',
  }) : super(commands: _checks(checks, ggLog));

  // ...........................................................................
  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
    bool? force,
    bool? saveState,
  }) async {
    // Execute commands.
    await super.get(directory: directory, ggLog: ggLog, force: force);
  }

  // ...........................................................................
  static List<DirCommand<void>> _checks(
    Checks? checks,
    GgLog ggLog,
  ) {
    checks ??= Checks(ggLog: ggLog);

    return [
      checks.analyze,
      checks.format,
      checks.tests,
    ];
  }
}

// .............................................................................
/// A mocktail mock
class MockCanCommit extends MockDirCommand<void> implements CanCommit {}
