import 'package:flutter_test/flutter_test.dart';
import 'package:ternify/models/perkawinan_model.dart';

void main() {
  group('Perkawinan Model Tests', () {
    test('fromJson mengekstrak data JSON dengan benar', () {
      final json = {
        'id': 10,
        'id_domba_betina': 'B001',
        'id_domba_jantan': 'J001',
        'ear_tag_betina': 'E-Betina',
        'ear_tag_jantan': 'E-Jantan',
        'tanggal_kawin': '2023-10-15',
        'metode_kawin': 'alami',
        'tanggal_perkiraan_lahir': '2024-03-15',
        'status_perkawinan': 'bunting',
        'jumlah_anak': 2,
        'catatan': 'Normal',
        'betina': {'ear_tag': 'E-Betina-Relasi'},
        'jantan': {'ear_tag': 'E-Jantan-Relasi'},
      };

      final perkawinan = Perkawinan.fromJson(json);

      expect(perkawinan.id, 10);
      expect(perkawinan.idDombaBetina, 'B001');
      expect(perkawinan.earTagBetina, 'E-Betina');
      expect(perkawinan.tanggalKawin, '2023-10-15');
      expect(perkawinan.metodeKawin, 'alami');
      expect(perkawinan.tanggalPerkiraanLahir, '2024-03-15');
      expect(perkawinan.statusPerkawinan, 'bunting');
      expect(perkawinan.jumlahAnak, 2);
      expect(perkawinan.catatan, 'Normal');
      expect(perkawinan.betina?['ear_tag'], 'E-Betina-Relasi');
    });

    test('fromJson menangani json dengan field null secara aman', () {
      final json = <String, dynamic>{
        'ear_tag_betina': null,
        'ear_tag_jantan': null,
        'tanggal_kawin': null,
      };

      final perkawinan = Perkawinan.fromJson(json);

      expect(perkawinan.earTagBetina, '');
      expect(perkawinan.earTagJantan, '');
      expect(perkawinan.tanggalKawin, '');
      expect(perkawinan.id, isNull);
      expect(perkawinan.jumlahAnak, isNull);
    });

    test('toJson mengembalikan Map yang sesuai', () {
      const perkawinan = Perkawinan(
        earTagBetina: 'E-B',
        earTagJantan: 'E-J',
        tanggalKawin: '2023-01-01',
        metodeKawin: 'ib',
        jumlahAnak: 1,
      );

      final json = perkawinan.toJson();

      expect(json['ear_tag_betina'], 'E-B');
      expect(json['ear_tag_jantan'], 'E-J');
      expect(json['tanggal_kawin'], '2023-01-01');
      expect(json['metode_kawin'], 'ib');
      expect(json['jumlah_anak'], 1);
    });

    test('computed property statusLabel merapikan teks status', () {
      const pKawin = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', statusPerkawinan: 'kawin');
      const pBunting = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', statusPerkawinan: 'bunting');
      const pLahir = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', statusPerkawinan: 'lahir');
      const pGagal = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', statusPerkawinan: 'gagal');
      const pLain = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', statusPerkawinan: 'Lainnya');
      const pNull = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '');

      expect(pKawin.statusLabel, 'Kawin');
      expect(pBunting.statusLabel, 'Bunting');
      expect(pLahir.statusLabel, 'Sudah Lahir');
      expect(pGagal.statusLabel, 'Gagal');
      expect(pLain.statusLabel, 'Lainnya');
      expect(pNull.statusLabel, '-');
    });

    test('computed property metodeLabel merapikan teks metode', () {
      const mAlami1 = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', metodeKawin: 'alami');
      const mAlami2 = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', metodeKawin: 'natural');
      const mIb1 = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', metodeKawin: 'ib');
      const mIb2 = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '', metodeKawin: 'inseminasi buatan');
      const mNull = Perkawinan(earTagBetina: '', earTagJantan: '', tanggalKawin: '');

      expect(mAlami1.metodeLabel, 'Alami');
      expect(mAlami2.metodeLabel, 'Alami');
      expect(mIb1.metodeLabel, 'Inseminasi Buatan');
      expect(mIb2.metodeLabel, 'Inseminasi Buatan');
      expect(mNull.metodeLabel, '-');
    });

    test('computed property tanggalKawinDisplay dan tanggalLahirDisplay memformat tanggal', () {
      const perkawinan = Perkawinan(
        earTagBetina: '',
        earTagJantan: '',
        tanggalKawin: '2023-10-15',
        tanggalPerkiraanLahir: '2024-03-05',
      );

      expect(perkawinan.tanggalKawinDisplay, '15 Okt 2023');
      expect(perkawinan.tanggalLahirDisplay, '5 Mar 2024');
    });

    test('computed property tanggal fallback saat format tidak valid atau null', () {
      const perkawinan = Perkawinan(
        earTagBetina: '',
        earTagJantan: '',
        tanggalKawin: 'InvalidDate',
      );

      expect(perkawinan.tanggalKawinDisplay, 'InvalidDate');
      expect(perkawinan.tanggalLahirDisplay, '-');
    });

    test('computed property betinaLabel dan jantanLabel fallback', () {
      const perkawinan1 = Perkawinan(
        earTagBetina: 'E-B',
        earTagJantan: 'E-J',
        tanggalKawin: '',
        betina: {'ear_tag': 'Relasi-B'},
        jantan: {'ear_tag': 'Relasi-J'},
      );
      expect(perkawinan1.betinaLabel, 'Relasi-B');
      expect(perkawinan1.jantanLabel, 'Relasi-J');

      const perkawinan2 = Perkawinan(
        earTagBetina: 'E-B',
        earTagJantan: 'E-J',
        tanggalKawin: '',
      );
      expect(perkawinan2.betinaLabel, 'E-B');
      expect(perkawinan2.jantanLabel, 'E-J');
    });
  });
}
