import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

double safeDouble(dynamic value) {
  try {
    return double.parse(value);
  } catch (err) {
    return 0;
  }
}

void v1(Database database) async {
  debugPrint("Running first migration....");
  await database.execute('''
    CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      account INTEGER NOT NULL,
      category INTEGER NOT NULL,
      amount REAL NOT NULL,
      datetime TEXT NOT NULL,
      type TEXT NOT NULL
    )
  ''');

  // Import feature tables
  await database.execute('''
    CREATE TABLE import_rules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      source TEXT NOT NULL,
      pattern TEXT NOT NULL,
      account_id INTEGER,
      category_id INTEGER,
      type TEXT NOT NULL,
      enabled INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      sender_filter TEXT,
      subject_filter TEXT
    )
  ''');

  await database.execute('''
    CREATE TABLE import_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source TEXT NOT NULL,
      source_id TEXT NOT NULL,
      payment_id INTEGER,
      imported_at TEXT NOT NULL,
      raw_content TEXT,
      UNIQUE(source, source_id)
    )
  ''');

  await database.execute("CREATE TABLE categories ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT,"
      "icon INTEGER,"
      "color INTEGER,"
      "budget REAL NULL, "
      "type TEXT"
      ")");

  await database.execute("CREATE TABLE accounts ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT,"
      "holderName TEXT NULL, "
      "accountNumber TEXT NULL, "
      "icon INTEGER,"
      "color INTEGER,"
      "isDefault INTEGER"
      ")");
}
