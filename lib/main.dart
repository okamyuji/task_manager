import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'repositories/task_local_repository.dart';

/// アプリケーションのエントリーポイント
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hiveの初期化
  await TaskLocalRepository.initialize();

  runApp(const ProviderScope(child: App()));
}
