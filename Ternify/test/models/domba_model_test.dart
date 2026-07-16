import 'package:flutter_test/flutter_test.dart';
import 'package:ternify/models/domba_model.dart';

void main() {
  group('Domba Model Tests', () {
    test('fromJson mengekstrak data JSON dengan benar', () {
      final json = {
        'id_domba': '1',
        'ear_tag': 'E001',
        'id_bangsa': 'B1',
        'jenis_kelamin': 'jantan',
        'tanggal_lahir': '2023-01-01',
        'id_induk': '2',
        'ear_tag_induk': 'E002',
        'id_pejantan': '3',
        'ear_tag_pejantan': 'E003',
        'berat': '15.5',
        'status': 'sehat',
        'vaksinasi': 'sudah',
        'status_ketersediaan': 'tersedia',
      };

      final domba = Domba.fromJson(json);

      expect(domba.idDomba, '1');
      expect(domba.earTag, 'E001');
      expect(domba.idBangsa, 'B1');
      expect(domba.jenisKelamin, 'jantan');
      expect(domba.tanggalLahir, '2023-01-01');
      expect(domba.idInduk, '2');
      expect(domba.earTagInduk, 'E002');
      expect(domba.idPejantan, '3');
      expect(domba.earTagPejantan, 'E003');
      expect(domba.berat, 15.5);
      expect(domba.status, 'sehat');
      expect(domba.vaksinasi, 'sudah');
      expect(domba.statusKetersediaan, 'tersedia');
    });

    test('fromJson menangani json dengan field null secara aman', () {
      final json = <String, dynamic>{
        'id_domba': null,
        'ear_tag': null,
        'jenis_kelamin': null,
      };

      final domba = Domba.fromJson(json);

      expect(domba.idDomba, '');
      expect(domba.earTag, '');
      expect(domba.jenisKelamin, '');
      expect(domba.idBangsa, isNull);
      expect(domba.berat, isNull);
      expect(domba.statusKetersediaan, 'tersedia');
    });

    test('toJson mengembalikan Map yang sesuai', () {
      const domba = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
        berat: 10.0,
      );

      final json = domba.toJson();

      expect(json['ear_tag'], 'E001');
      expect(json['jenis_kelamin'], 'jantan');
      expect(json['berat'], 10.0);
    });

    test('computed property namaInduk fallback dengan benar', () {
      // Prioritas 1: objek induk['ear_tag']
      final domba1 = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
        induk: {'ear_tag': 'Induk-Obj'},
        earTagInduk: 'Induk-String',
        idInduk: 'I1',
      );
      expect(domba1.namaInduk, 'Induk-Obj');

      // Prioritas 2: earTagInduk
      final domba2 = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
        earTagInduk: 'Induk-String',
        idInduk: 'I1',
      );
      expect(domba2.namaInduk, 'Induk-String');

      // Prioritas 3: idInduk
      final domba3 = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
        idInduk: 'I1',
      );
      expect(domba3.namaInduk, 'I1');

      // Prioritas 4: '-' jika semua null
      const domba4 = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
      );
      expect(domba4.namaInduk, '-');
    });

    test('computed property namaPejantan fallback dengan benar', () {
      final domba1 = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
        pejantan: {'ear_tag': 'Jantan-Obj'},
        earTagPejantan: 'Jantan-String',
      );
      expect(domba1.namaPejantan, 'Jantan-Obj');

      final domba2 = Domba(
        idDomba: '1',
        earTag: 'E001',
        jenisKelamin: 'jantan',
        earTagPejantan: 'Jantan-String',
      );
      expect(domba2.namaPejantan, 'Jantan-String');
    });

    test('computed property umur dihitung berdasarkan tanggalLahir', () {
      // Jika null
      const dombaNull = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'j');
      expect(dombaNull.umur, '-');

      // Hitung umur statis relatif
      final now = DateTime.now();
      
      // Kasus 1: Umur < 1 tahun (misal 5 bulan lalu)
      final fiveMonthsAgo = DateTime(now.year, now.month - 5, now.day);
      final dombaKecil = Domba(
        idDomba: '1',
        earTag: 'E',
        jenisKelamin: 'j',
        tanggalLahir: fiveMonthsAgo.toIso8601String(),
      );
      expect(dombaKecil.umur, '5 bln');

      // Kasus 2: Umur >= 1 tahun (misal 1 tahun 3 bulan lalu)
      final fifteenMonthsAgo = DateTime(now.year - 1, now.month - 3, now.day);
      final dombaDewasa = Domba(
        idDomba: '1',
        earTag: 'E',
        jenisKelamin: 'j',
        tanggalLahir: fifteenMonthsAgo.toIso8601String(),
      );
      expect(dombaDewasa.umur, '1 th 3 bln');
    });

    test('computed property jenisKelaminLabel merapikan teks', () {
      const dombaJ = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'jantan');
      const dombaB = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'betina');
      const dombaO = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'lainnya');

      expect(dombaJ.jenisKelaminLabel, 'Jantan');
      expect(dombaB.jenisKelaminLabel, 'Betina');
      expect(dombaO.jenisKelaminLabel, 'lainnya');
    });

    test('computed property statusKetersediaanLabel merapikan teks', () {
      const domba1 = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'j', statusKetersediaan: 'terjual');
      const domba2 = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'j', statusKetersediaan: 'mati');
      const domba3 = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'j', statusKetersediaan: 'tersedia');
      const domba4 = Domba(idDomba: '1', earTag: 'E', jenisKelamin: 'j', statusKetersediaan: 'unknown');

      expect(domba1.statusKetersediaanLabel, 'Terjual');
      expect(domba2.statusKetersediaanLabel, 'Mati');
      expect(domba3.statusKetersediaanLabel, 'Tersedia');
      expect(domba4.statusKetersediaanLabel, 'Tersedia'); // fallback default
    });
  });
}
