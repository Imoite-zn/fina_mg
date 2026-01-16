import 'dart:async';
import 'package:fintracker/features/import/models/import_rule.model.dart';
import 'package:fintracker/helpers/db.helper.dart';

/// Data Access Object for Import Rules
class ImportRuleDao {
  Future<int> create(ImportRule rule) async {
    final db = await getDBInstance();
    var result = await db.insert("import_rules", rule.toJson());
    return result;
  }

  Future<List<ImportRule>> find({
    String? source,
    bool? enabled,
  }) async {
    final db = await getDBInstance();
    String where = "1=1";
    List<dynamic> whereArgs = [];

    if (source != null) {
      where += " AND source = ?";
      whereArgs.add(source);
    }

    if (enabled != null) {
      where += " AND enabled = ?";
      whereArgs.add(enabled ? 1 : 0);
    }

    List<ImportRule> rules = [];
    List<Map<String, Object?>> rows = await db.query(
      "import_rules",
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: "created_at DESC",
    );

    for (var row in rows) {
      rules.add(ImportRule.fromJson(Map<String, dynamic>.from(row)));
    }

    return rules;
  }

  Future<ImportRule?> findById(int id) async {
    final db = await getDBInstance();
    List<Map<String, Object?>> rows = await db.query(
      "import_rules",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ImportRule.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<int> update(ImportRule rule) async {
    final db = await getDBInstance();
    var result = await db.update(
      "import_rules",
      rule.toJson(),
      where: "id = ?",
      whereArgs: [rule.id],
    );
    return result;
  }

  Future<int> upsert(ImportRule rule) async {
    if (rule.id != null) {
      return await update(rule);
    } else {
      return await create(rule);
    }
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    var result = await db.delete(
      "import_rules",
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> toggleEnabled(int id, bool enabled) async {
    final db = await getDBInstance();
    var result = await db.update(
      "import_rules",
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }
}
