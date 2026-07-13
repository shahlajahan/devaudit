/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import '../shared/tool_version.dart';
import 'exit_codes.dart';
import 'scan_command.dart';

/// The top-level `devaudit` command-line entry point.
///
/// Since: 0.1.0-dev.1
class DevAuditCommandRunner extends CommandRunner<int> {
  /// Creates the DevAudit command runner and registers its subcommands.
  DevAuditCommandRunner()
    : super(
        'devaudit',
        'DevAudit — Analyze. Understand. Improve.\n\n'
            'A plugin-based developer audit platform.',
      ) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version and exit.',
    );
    addCommand(ScanCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      if (topLevelResults.flag('version')) {
        stdout.writeln('devaudit $toolVersion');
        return 0;
      }
      final exitCode = await runCommand(topLevelResults);
      return exitCode ?? 0;
    } on UsageException catch (error) {
      stderr
        ..writeln(error.message)
        ..writeln()
        ..writeln(error.usage);
      return executionErrorExitCode;
    }
  }
}
