import 'package:flutter_test/flutter_test.dart';
import 'package:ternify/models/rekam_medis_model.dart';

void main() {
  group('RekamMedis Model Tests', () {
    test('fromJson mengekstrak data JSON dengan benar', () {
      final json = {
        'id': 101,
        'id_domba': '1',
        'ear_tag': 'E001',
        'tanggal_pemeriksaan': '2023-10-15',
        'berat': '12.5',
        'suhu_tubuh': '39.0',
        'status_kesehatan': 'sakit',
        'vaksinasi': 'belum',
        'obat': 'antibiotik',
        'catatan': 'Diare',
      };

      final rekam = RekamMedis.fromJson(json);

      expect(rekam.id, '101');
      expect(rekam.idDomba, '1');
      expect(rekam.earTag, 'E001');
      expect(rekam.tanggalPemeriksaan, '2023-10-15');
      expect(rekam.berat, 12.5);
      expect(rekam.suhuTubuh, 39.0);
      expect(rekam.statusKesehatan, 'sakit');
      expect(rekam.vaksinasi, 'belum');
      expect(rekam.obat, 'antibiotik');
      expect(rekam.catatan, 'Diare');
    });

    test('fromJson menangani json dengan field null secara aman', () {
      final json = <String, dynamic>{
        'ear_tag': null,
        'tanggal_pemeriksaan': null,
        'berat': null,
      };

      final rekam = RekamMedis.fromJson(json);

      expect(rekam.earTag, '');
      expect(rekam.tanggalPemeriksaan, '');
      expect(rekam.id, isNull);
      expect(rekam.berat, isNull);
    });

    test('toJson mengembalikan Map yang sesuai', () {
      const rekam = RekamMedis(
        earTag: 'E001',
        tanggalPemeriksaan: '2023-10-15',
        berat: 12.5,
        statusKesehatan: 'sehat',
      );

      final json = rekam.toJson();

      expect(json['ear_tag'], 'E001');
      expect(json['tanggal_pemeriksaan'], '2023-10-15');
      expect(json['berat'], 12.5);
      expect(json['status_kesehatan'], 'sehat');
    });

    test('computed property statusLabel merapikan teks status', () {
      const rSehat = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'sehat');
      const rSakit1 = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'sakit');
      const rSakit2 = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'dalam perawatan');
      const rSakit3 = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'karantina');
      const rBunting = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'bunting');
      const rHamil = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'hamil');
      const rLain = RekamMedis(earTag: '', tanggalPemeriksaan: '', statusKesehatan: 'Lainnya');
      const rNull = RekamMedis(earTag: '', tanggalPemeriksaan: '');

      expect(rSehat.statusLabel, 'Sehat');
      expect(rSakit1.statusLabel, 'Sakit');
      expect(rSakit2.statusLabel, 'Sakit');
      expect(rSakit3.statusLabel, 'Sakit');
      expect(rBunting.statusLabel, 'Bunting');
      expect(rHamil.statusLabel, 'Bunting');
      expect(rLain.statusLabel, 'Lainnya');
      expect(rNull.statusLabel, '-');
    });

    test('computed property tanggalDisplay memformat tanggal', () {
      const rekam = RekamMedis(
        earTag: '',
        tanggalPemeriksaan: '2023-10-15',
      );

      expect(rekam.tanggalDisplay, '15 Okt 2023');
    });

    test('computed property tanggalDisplay fallback saat format tidak valid', () {
      const rekam = RekamMedis(
        earTag: '',
        tanggalPemeriksaan: 'InvalidDate',
      );

      expect(rekam.tanggalDisplay, 'InvalidDate');
    });
  });
}
