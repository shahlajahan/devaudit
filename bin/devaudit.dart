/// DevAudit
///
/// Copyright (c) Pharos Labs.
/// Licensed under the Apache License, Version 2.0.
library;

import 'dart:io';

import 'package:devaudit/cli/devaudit_command_runner.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await DevAuditCommandRunner().run(arguments);
}
