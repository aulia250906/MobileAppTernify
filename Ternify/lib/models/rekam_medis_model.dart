class RekamMedis {
  final String? id;
  final String? idDomba;
  final String earTag;
  final String tanggalPemeriksaan;
  final double? berat;
  final double? suhuTubuh;
  final String? statusKesehatan;
  final String? vaksinasi;
  final String? obat;
  final String? catatan;
  final String? createdAt;

  const RekamMedis({
    this.id,
    this.idDomba,
    required this.earTag,
    required this.tanggalPemeriksaan,
    this.berat,
    this.suhuTubuh,
    this.statusKesehatan,
    this.vaksinasi,
    this.obat,
    this.catatan,
    this.createdAt,
  });

  factory RekamMedis.fromJson(Map<String, dynamic> json) {
    return RekamMedis(
      id: json['id']?.toString(),
      idDomba: json['id_domba']?.toString(),
      earTag: json['ear_tag']?.toString() ?? '',
      tanggalPemeriksaan: json['tanggal_pemeriksaan']?.toString() ?? '',
      berat: json['berat'] != null
          ? double.tryParse(json['berat'].toString())
          : null,
      suhuTubuh: json['suhu_tubuh'] != null
          ? double.tryParse(json['suhu_tubuh'].toString())
          : null,
      statusKesehatan: json['status_kesehatan'],
      vaksinasi: json['vaksinasi'],
      obat: json['obat'],
      catatan: json['catatan'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ear_tag': earTag,
    'tanggal_pemeriksaan': tanggalPemeriksaan,
    'berat': berat,
    'suhu_tubuh': suhuTubuh,
    'status_kesehatan': statusKesehatan,
    'vaksinasi': vaksinasi,
    'obat': obat,
    'catatan': catatan,
  };

  /// Status label — disesuaikan dengan 3 status di dashboard
  String get statusLabel {
    switch (statusKesehatan?.toLowerCase()) {
      case 'sehat':
        return 'Sehat';
      case 'sakit':
      case 'dalam perawatan':
      case 'perawatan':
      case 'karantina':
        return 'Sakit';
      case 'bunting':
      case 'hamil':
        return 'Bunting';
      default:
        return statusKesehatan ?? '-';
    }
  }

  /// Formatted date display
  String get tanggalDisplay {
    final dt = DateTime.tryParse(tanggalPemeriksaan);
    if (dt == null) return tanggalPemeriksaan;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
