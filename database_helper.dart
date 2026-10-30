import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('procurement.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier TEXT,
        category TEXT,
        item_code TEXT UNIQUE,
        description TEXT,
        unit TEXT,
        unit_price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        order_no INTEGER PRIMARY KEY,
        order_date TEXT,
        branch TEXT,
        department TEXT,
        supplier TEXT,
        editor TEXT,
        director TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no INTEGER,
        item_code TEXT,
        description TEXT,
        unit TEXT,
        quantity REAL,
        unit_price REAL,
        total REAL,
        FOREIGN KEY (order_no) REFERENCES orders (order_no) ON DELETE CASCADE
      )
    ''');

    try {
      String jsonString = await rootBundle.loadString('assets/seed_data.json');
      Map<String, dynamic> data = jsonDecode(jsonString);
      List<dynamic> items = data['items'];

      Batch batch = db.batch();
      for (var item in items) {
        batch.insert('items', {
          'supplier': item['Supplier'],
          'category': item['Category'],
          'item_code': item['ItemCode'],
          'description': item['ItemDescription'],
          'unit': item['Unit'],
          'unit_price': item['UnitPrice'] ?? 0.0,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('خطأ في تحميل البيانات الأولية: \$e');
    }
  }

  Future<int> insertOrder(Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    int orderNo = order['order_no'];
    await db.transaction((txn) async {
      await txn.insert('orders', order, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var item in items) {
        item['order_no'] = orderNo;
        await txn.insert('order_items', item);
      }
    });
    return orderNo;
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await instance.database;
    return await db.query('orders', orderBy: 'order_no DESC');
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderNo) async {
    final db = await instance.database;
    return await db.query('order_items', where: 'order_no = ?', whereArgs: [orderNo]);
  }

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    final db = await instance.database;
    return await db.query(
      'items',
      where: 'description LIKE ? OR item_code LIKE ?',
      whereArgs: ['%\$query%', '%\$query%'],
    );
  }
}
