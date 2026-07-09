import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Tambahan untuk deteksi Web

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();

  static Database? _database;

  LocalDatabase._init();

  // Ubah menjadi nullable (Database?) agar bisa mereturn null saat di Web
  Future<Database?> get database async {
    if (kIsWeb) return null; // Cegah inisialisasi sqflite jika di Web

    if (_database != null) return _database!;
    _database = await _initDB('ternify_local.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_domba (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        ear_tag TEXT NOT NULL,
        id_bangsa TEXT,
        jenis_kelamin TEXT NOT NULL,
        tanggal_lahir TEXT,
        id_induk TEXT,
        ear_tag_induk TEXT,
        id_pejantan TEXT,
        ear_tag_pejantan TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_sync_at TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_local_domba_server_id 
      ON local_domba(server_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_local_domba_sync_status 
      ON local_domba(sync_status)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE local_domba ADD COLUMN ear_tag_induk TEXT');
      await db.execute('ALTER TABLE local_domba ADD COLUMN ear_tag_pejantan TEXT');
    }
  }

  // ─────────────────────────────────────────────
  // INSERT DATA LOKAL
  // ─────────────────────────────────────────────
  Future<int> insertLocalDomba(Map<String, dynamic> data) async {
    if (kIsWeb) return 0; // Bypass untuk Web

    final db = (await database)!;
    final now = DateTime.now().toIso8601String();

    return await db.insert('local_domba', {
      'server_id': data['server_id'],
      'ear_tag': data['ear_tag'],
      'id_bangsa': data['id_bangsa'],
      'jenis_kelamin': data['jenis_kelamin'],
      'tanggal_lahir': data['tanggal_lahir'],
      'id_induk': data['id_induk'],
      'ear_tag_induk': data['ear_tag_induk'],
      'id_pejantan': data['id_pejantan'],
      'ear_tag_pejantan': data['ear_tag_pejantan'],
      'sync_status': data['sync_status'] ?? 'pending',
      'created_at': data['created_at'] ?? now,
      'updated_at': data['updated_at'] ?? now,
      'last_sync_at': data['last_sync_at'],
      'deleted_at': data['deleted_at'],
    });
  }

  // ─────────────────────────────────────────────
  // AMBIL SEMUA DATA LOKAL
  // ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLocalDomba({
    String? search,
    String? jenisKelamin,
  }) async {
    if (kIsWeb) return []; // Kembalikan list kosong agar UI tidak error di Web

    final db = (await database)!;

    final where = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (search != null && search.trim().isNotEmpty) {
      where.add('(ear_tag LIKE ? OR id_bangsa LIKE ?)');
      args.add('%${search.trim()}%');
      args.add('%${search.trim()}%');
    }

    if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
      where.add('jenis_kelamin = ?');
      args.add(jenisKelamin);
    }

    return await db.query(
      'local_domba',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'local_id DESC',
    );
  }

  // ─────────────────────────────────────────────
  // AMBIL DATA YANG BELUM SYNC
  // ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPendingDomba() async {
    if (kIsWeb) return []; // Bypass untuk Web

    final db = (await database)!;

    return await db.query(
      'local_domba',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'local_id ASC',
    );
  }

  // ─────────────────────────────────────────────
  // UPSERT DATA DARI SERVER KE LOKAL
  // ─────────────────────────────────────────────
  Future<void> upsertDombaFromServer(Map<String, dynamic> data) async {
    if (kIsWeb) return; // Bypass untuk Web

    final db = (await database)!;
    final now = DateTime.now().toIso8601String();

    final serverId = data['id_domba'];

    final existing = await db.query(
      'local_domba',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );

    final localData = {
      'server_id': serverId,
      'ear_tag': data['ear_tag'],
      'id_bangsa': data['id_bangsa'],
      'jenis_kelamin': data['jenis_kelamin'],
      'tanggal_lahir': data['tanggal_lahir'],
      'id_induk': data['id_induk'],
      'ear_tag_induk': data['ear_tag_induk'],
      'id_pejantan': data['id_pejantan'],
      'ear_tag_pejantan': data['ear_tag_pejantan'],
      'sync_status': 'synced',
      'last_sync_at': now,
      'updated_at': now,
      'deleted_at': null,
    };

    if (existing.isEmpty) {
      await db.insert('local_domba', {
        ...localData,
        'created_at': data['created_at'] ?? now,
      });
    } else {
      await db.update(
        'local_domba',
        localData,
        where: 'server_id = ?',
        whereArgs: [serverId],
      );
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE STATUS SETELAH BERHASIL SYNC
  // ─────────────────────────────────────────────
  Future<void> markDombaAsSynced({
    required int localId,
    required String serverId,
  }) async {
    if (kIsWeb) return; // Bypass untuk Web

    final db = (await database)!;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'local_domba',
      {
        'server_id': serverId,
        'sync_status': 'synced',
        'last_sync_at': now,
        'updated_at': now,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  // ─────────────────────────────────────────────
  // UPDATE LOCAL DATA
  // ─────────────────────────────────────────────
  Future<void> updateLocalDombaByServerId({
    required String serverId,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return; // Bypass untuk Web

    final db = (await database)!;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'local_domba',
      {
        'ear_tag': data['ear_tag'],
        'id_bangsa': data['id_bangsa'],
        'jenis_kelamin': data['jenis_kelamin'],
        'tanggal_lahir': data['tanggal_lahir'],
        'id_induk': data['id_induk'],
        'ear_tag_induk': data['ear_tag_induk'],
        'id_pejantan': data['id_pejantan'],
        'ear_tag_pejantan': data['ear_tag_pejantan'],
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
  }

  // ─────────────────────────────────────────────
  // HAPUS LOKAL
  // ─────────────────────────────────────────────
  Future<void> deleteLocalDombaByServerId(String serverId) async {
    if (kIsWeb) return; // Bypass untuk Web

    final db = (await database)!;

    await db.delete(
      'local_domba',
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
  }

  // ─────────────────────────────────────────────
  // RESET DATA LOKAL
  // ─────────────────────────────────────────────
  Future<void> clearLocalDomba() async {
    if (kIsWeb) return; // Bypass untuk Web

    final db = (await database)!;
    await db.delete('local_domba');
  }
}
