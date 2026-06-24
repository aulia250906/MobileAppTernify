class Perkawinan {
  final int? id;
  final String? idDombaBetina;
  final String? idDombaJantan;
  final String earTagBetina;
  final String earTagJantan;
  final String tanggalKawin;
  final String? metodeKawin;
  final String? tanggalPerkiraanLahir;
  final String? statusPerkawinan;
  final int? jumlahAnak;
  final String? catatan;
  final String? createdAt;

  // Relasi data (dari eager load)
  final Map<String, dynamic>? betina;
  final Map<String, dynamic>? jantan;

  const Perkawinan({
    this.id,
    this.idDombaBetina,
    this.idDombaJantan,
    required this.earTagBetina,
    required this.earTagJantan,
    required this.tanggalKawin,
    this.metodeKawin,
    this.tanggalPerkiraanLahir,
    this.statusPerkawinan,
    this.jumlahAnak,
    this.catatan,
    this.createdAt,
    this.betina,
    this.jantan,
  });

  factory Perkawinan.fromJson(Map<String, dynamic> json) {
    return Perkawinan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      idDombaBetina: json['id_domba_betina']?.toString(),
      idDombaJantan: json['id_domba_jantan']?.toString(),
      earTagBetina: json['ear_tag_betina']?.toString() ?? '',
      earTagJantan: json['ear_tag_jantan']?.toString() ?? '',
      tanggalKawin: json['tanggal_kawin']?.toString() ?? '',
      metodeKawin: json['metode_kawin'],
      tanggalPerkiraanLahir: json['tanggal_perkiraan_lahir'],
      statusPerkawinan: json['status_perkawinan'],
      jumlahAnak: json['jumlah_anak'] != null
          ? int.tryParse(json['jumlah_anak'].toString())
          : null,
      catatan: json['catatan'],
      createdAt: json['created_at'],
      betina: json['betina'] != null
          ? Map<String, dynamic>.from(json['betina'])
          : null,
      jantan: json['jantan'] != null
          ? Map<String, dynamic>.from(json['jantan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'ear_tag_betina': earTagBetina,
    'ear_tag_jantan': earTagJantan,
    'tanggal_kawin': tanggalKawin,
    'metode_kawin': metodeKawin,
    'tanggal_perkiraan_lahir': tanggalPerkiraanLahir,
    'status_perkawinan': statusPerkawinan,
    'jumlah_anak': jumlahAnak,
    'catatan': catatan,
  };

  /// Status label
  String get statusLabel {
    switch (statusPerkawinan?.toLowerCase()) {
      case 'kawin':
        return 'Kawin';
      case 'bunting':
        return 'Bunting';
      case 'lahir':
        return 'Sudah Lahir';
      case 'gagal':
        return 'Gagal';
      default:
        return statusPerkawinan ?? '-';
    }
  }

  /// Metode label
  String get metodeLabel {
    switch (metodeKawin?.toLowerCase()) {
      case 'alami':
      case 'natural':
        return 'Alami';
      case 'ib':
      case 'inseminasi':
      case 'inseminasi buatan':
        return 'Inseminasi Buatan';
      default:
        return metodeKawin ?? '-';
    }
  }

  /// Formatted tanggal kawin
  String get tanggalKawinDisplay {
    final dt = DateTime.tryParse(tanggalKawin);
    if (dt == null) return tanggalKawin;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  /// Formatted tanggal perkiraan lahir
  String get tanggalLahirDisplay {
    if (tanggalPerkiraanLahir == null) return '-';
    final dt = DateTime.tryParse(tanggalPerkiraanLahir!);
    if (dt == null) return tanggalPerkiraanLahir!;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  /// Ear tag betina display
  String get betinaLabel => betina?['ear_tag'] ?? earTagBetina;

  /// Ear tag jantan display
  String get jantanLabel => jantan?['ear_tag'] ?? earTagJantan;
}
