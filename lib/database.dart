import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._privateConstructor();
  static Database? _database;

  DBHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile_cache (
        id TEXT PRIMARY KEY,
        username TEXT,
        gender TEXT,
        fullname TEXT,
        email TEXT,
        profile_url TEXT
      )
    ''');
  }

  // Save or Update user profile locally
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    await db.insert(
      'profile_cache',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace, // Updates existing ID
    );
  }

  // Get the profile to display on the screen
  Future<Map<String, dynamic>?> getProfile(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'profile_cache',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }
}