import '../database/local_database.dart';
import '../models/domba_model.dart';
import '../services/api_service.dart';

class DombaRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  // ─────────────────────────────────────────────
  // FETCH DOMBA
  // 1. Coba sync pending
  // 2. Coba ambil server
  // 3. Simpan server ke SQLite
  // 4. Tampilkan dari SQLite
  // ─────────────────────────────────────────────
  Future<List<Domba>> fetchDomba({String? search, String? jenisKelamin}) async {
    try {
      await syncPendingDomba();

      final serverData = await ApiService.fetchDomba(
        search: search,
        jenisKelamin: jenisKelamin,
      );

      for (final item in serverData) {
        await _localDb.upsertDombaFromServer(item);
      }
    } catch (_) {
      // Jika offline atau server gagal, tetap lanjut ambil data lokal
    }

    final localData = await _localDb.getLocalDomba(
      search: search,
      jenisKelamin: jenisKelamin,
    );

    return localData.map(_mapLocalToDomba).toList();
  }

  // ─────────────────────────────────────────────
  // CREATE DOMBA
  // Simpan lokal dulu, lalu coba upload ke server.
  // Kalau server gagal, data tetap tersimpan lokal dengan status pending.
  // ─────────────────────────────────────────────
  Future<void> createDomba(Map<String, dynamic> payload) async {
    final localId = await _localDb.insertLocalDomba({
      ...payload,
      'sync_status': 'pending',
    });

    try {
      final result = await ApiService.createDomba(payload);
      final data = Map<String, dynamic>.from(result['data'] ?? {});
      final serverId = data['id_domba']?.toString();

      if (serverId != null && serverId.isNotEmpty) {
        await _localDb.markDombaAsSynced(localId: localId, serverId: serverId);
      }
    } catch (_) {
      // Data tetap pending di SQLite.
      // Nanti bisa dikirim ulang saat online.
    }
  }

  Future<void> createDombaFromScan(Map<String, dynamic> payload) async {
  await ApiService.createDombaFromScan(payload);
}

Future<List<Domba>> fetchBelumKandang() async {
  final data = await ApiService.fetchDombaBelumKandang();
  return data.map((e) => Domba.fromJson(e)).toList();
}

  // ─────────────────────────────────────────────
  // UPDATE DOMBA
  // Untuk tahap awal: update langsung ke server, lalu refresh lokal.
  // Offline update bisa kita sempurnakan setelah create offline berhasil.
  // ─────────────────────────────────────────────
  Future<void> updateDomba(String idDomba, Map<String, dynamic> payload) async {
    await ApiService.updateDomba(idDomba, payload);

    await _localDb.upsertDombaFromServer({...payload, 'id_domba': idDomba});
  }

  // ─────────────────────────────────────────────
  // DELETE DOMBA
  // Untuk tahap awal: delete langsung ke server, lalu hapus lokal.
  // ─────────────────────────────────────────────
  Future<void> deleteDomba(String idDomba) async {
    await ApiService.deleteDomba(idDomba);
    await _localDb.deleteLocalDombaByServerId(idDomba);
  }

  // ─────────────────────────────────────────────
  // DROPDOWN BETINA
  // ─────────────────────────────────────────────
  Future<List<Domba>> fetchBetina() async {
    try {
      final data = await ApiService.fetchBetina();

      for (final item in data) {
        await _localDb.upsertDombaFromServer(item);
      }

      return data.map((e) => Domba.fromJson(e)).toList();
    } catch (_) {
      final localData = await _localDb.getLocalDomba(jenisKelamin: 'betina');
      return localData.map(_mapLocalToDomba).toList();
    }
  }

  // ─────────────────────────────────────────────
  // DROPDOWN JANTAN
  // ─────────────────────────────────────────────
  Future<List<Domba>> fetchJantan() async {
    try {
      final data = await ApiService.fetchJantan();

      for (final item in data) {
        await _localDb.upsertDombaFromServer(item);
      }

      return data.map((e) => Domba.fromJson(e)).toList();
    } catch (_) {
      final localData = await _localDb.getLocalDomba(jenisKelamin: 'jantan');
      return localData.map(_mapLocalToDomba).toList();
    }
  }

  // ─────────────────────────────────────────────
  // STATISTIK UNTUK DASHBOARD
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchStatistik() async {
    try {
      return await ApiService.fetchDombaStatistik();
    } catch (_) {
      final localData = await _localDb.getLocalDomba();

      final total = localData.length;
      final totalJantan = localData
          .where((e) => e['jenis_kelamin'] == 'jantan')
          .length;
      final totalBetina = localData
          .where((e) => e['jenis_kelamin'] == 'betina')
          .length;

      return {
        'total_domba': total,
        'total_jantan': totalJantan,
        'total_betina': totalBetina,
        'status': {'sehat': total, 'bunting': 0, 'sakit': 0},
        'domba_terbaru': localData.take(5).map((e) {
          return {
            'id_domba': e['server_id'] ?? '',
            'ear_tag': e['ear_tag'],
            'id_bangsa': e['id_bangsa'],
            'jenis_kelamin': e['jenis_kelamin'],
            'tanggal_lahir': e['tanggal_lahir'],
            'id_induk': e['id_induk'],
            'ear_tag_induk': e['ear_tag_induk'],
            'id_pejantan': e['id_pejantan'],
            'ear_tag_pejantan': e['ear_tag_pejantan'],
            'created_at': e['created_at'],
            'updated_at': e['updated_at'],
          };
        }).toList(),
      };
    }
  }

  // ─────────────────────────────────────────────
  // SYNC PENDING
  // ─────────────────────────────────────────────
  Future<void> syncPendingDomba() async {
    final pending = await _localDb.getPendingDomba();

    print('[SYNC DOMBA] Jumlah pending: ${pending.length}');

    for (final item in pending) {
      final localId = item['local_id'] as int;

      final payload = {
        'ear_tag': item['ear_tag'],
        'id_bangsa': item['id_bangsa'],
        'jenis_kelamin': item['jenis_kelamin'],
        'tanggal_lahir': item['tanggal_lahir'],
        'id_induk': item['id_induk'],
        'ear_tag_induk': item['ear_tag_induk'],
        'id_pejantan': item['id_pejantan'],
        'ear_tag_pejantan': item['ear_tag_pejantan'],
      };

      print('[SYNC DOMBA] Kirim local_id=$localId payload=$payload');

      try {
        final result = await ApiService.createDomba(payload);

        print('[SYNC DOMBA] Response server: $result');

        final data = Map<String, dynamic>.from(result['data'] ?? {});
        final serverId = data['id_domba']?.toString();

        if (serverId != null && serverId.isNotEmpty) {
          await _localDb.markDombaAsSynced(
            localId: localId,
            serverId: serverId,
          );

          print(
            '[SYNC DOMBA] Berhasil sync local_id=$localId server_id=$serverId',
          );
        } else {
          print('[SYNC DOMBA] Gagal: id_domba kosong dari server');
        }
      } catch (e) {
        print('[SYNC DOMBA] Gagal sync local_id=$localId: $e');
      }
    }
  }

  Domba _mapLocalToDomba(Map<String, dynamic> map) {
    return Domba(
      idDomba: map['server_id']?.toString() ?? 'local-${map['local_id']}',
      earTag: map['ear_tag']?.toString() ?? '',
      idBangsa: map['id_bangsa']?.toString(),
      jenisKelamin: map['jenis_kelamin']?.toString() ?? '',
      tanggalLahir: map['tanggal_lahir']?.toString(),
      idInduk: map['id_induk']?.toString(),
      earTagInduk: map['ear_tag_induk']?.toString(),
      idPejantan: map['id_pejantan']?.toString(),
      earTagPejantan: map['ear_tag_pejantan']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
