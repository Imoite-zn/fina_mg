import 'dart:async';
import 'package:fintracker/features/import/models/import_history.model.dart';
import 'package:fintracker/helpers/db.helper.dart';

/// Data Access Object for Import History
class ImportHistoryDao {
  Future<int> create(ImportHistory history) async {
    final db = await getDBInstance();
    try {
      var result = await db.insert("import_history", history.toJson());
      return result;
    } catch (e) {
      // Handle unique constraint violation (duplicate import)
      return -1;
    }
  }

  Future<List<ImportHistory>> find({
    String? source,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await getDBInstance();
    String where = "1=1";
    List<dynamic> whereArgs = [];

    if (source != null) {
      where += " AND source = ?";
      whereArgs.add(source);
    }

    if (startDate != null) {
      where += " AND imported_at >= ?";
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += " AND imported_at <= ?";
      whereArgs.add(endDate.toIso8601String());
    }

    List<ImportHistory> history = [];
    List<Map<String, Object?>> rows = await db.query(
      "import_history",
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: "imported_at DESC",
      limit: limit,
    );

    for (var row in rows) {
      history.add(ImportHistory.fromJson(Map<String, dynamic>.from(row)));
    }

    return history;
  }

  /// Check if a message has already been imported
  Future<bool> isImported(String source, String sourceId) async {
    final db = await getDBInstance();
    List<Map<String, Object?>> rows = await db.query(
      "import_history",
      where: "source = ? AND source_id = ?",
      whereArgs: [source, sourceId],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  /// Get import history for a specific source message
  Future<ImportHistory?> findBySourceId(String source, String sourceId) async {
    final db = await getDBInstance();
    List<Map<String, Object?>> rows = await db.query(
      "import_history",
      where: "source = ? AND source_id = ?",
      whereArgs: [source, sourceId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ImportHistory.fromJson(Map<String, dynamic>.from(rows.first));
  }

  /// Update the payment ID for an import history record
  Future<int> updatePaymentId(int id, int paymentId) async {
    final db = await getDBInstance();
    var result = await db.update(
      "import_history",
      {'payment_id': paymentId},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    var result = await db.delete(
      "import_history",
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  /// Get count of imported messages by source
  Future<Map<String, int>> getImportCounts() async {
    final db = await getDBInstance();
    final smsCount = await db.rawQuery(
      "SELECT COUNT(*) as count FROM import_history WHERE source = 'sms'",
    );
    final emailCount = await db.rawQuery(
      "SELECT COUNT(*) as count FROM import_history WHERE source = 'email'",
    );

    return {
      'sms': (smsCount.first['count'] as int?) ?? 0,
      'email': (emailCount.first['count'] as int?) ?? 0,
    };
  }
}
