import 'package:eduportfolio/core/database/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Provider for DatabaseHelper instance
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provider for Database instance
///
/// This provider returns a `Future<Database>` that can be used with FutureProvider
final databaseProvider = FutureProvider<Database>((ref) async {
  final helper = ref.watch(databaseHelperProvider);
  return helper.database;
});
