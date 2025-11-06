// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/src/server/a2a_server.dart';
import 'package:a2a_dart/src/server/create_task_handler.dart';
import 'package:a2a_dart/src/server/task_manager.dart';

Future<void> main(List<String> arguments) async {
  final taskManager = TaskManager();
  final server = A2AServer([CreateTaskHandler(taskManager)]);

  await server.start();
}
