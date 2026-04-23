class Domba {
  final String idDomba;
  final String earTag;
  final String? idBangsa;
  final String jenisKelamin;
  final String? tanggalLahir;
  final String? idInduk;
  final String? idPejantan;
  final Map<String, dynamic>? induk;
  final Map<String, dynamic>? pejantan;
  final String? createdAt;
  final String? updatedAt;

  const Domba({
    required this.idDomba,
    required this.earTag,
    this.idBangsa,
    required this.jenisKelamin,
    this.tanggalLahir,
    this.idInduk,
    this.idPejantan,
    this.induk,
    this.pejantan,
    this.createdAt,
    this.updatedAt,
  });

  factory Domba.fromJson(Map<String, dynamic> json) {
    return Domba(
      idDomba:      json['id_domba'] ?? '',
      earTag:       json['ear_tag'] ?? '',
      idBangsa:     json['id_bangsa'],
      jenisKelamin: json['jenis_kelamin'] ?? '',
      tanggalLahir: json['tanggal_lahir'],
      idInduk:      json['id_induk'],
      idPejantan:   json['id_pejantan'],
      induk:        json['induk'] != null ? Map<String, dynamic>.from(json['induk']) : null,
      pejantan:     json['pejantan'] != null ? Map<String, dynamic>.from(json['pejantan']) : null,
      createdAt:    json['created_at'],
      updatedAt:    json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ear_tag':       earTag,
    'id_bangsa':     idBangsa,
    'jenis_kelamin': jenisKelamin,
    'tanggal_lahir': tanggalLahir,
    'id_induk':      idInduk,
    'id_pejantan':   idPejantan,
  };

  /// Nama induk dari relasi (jika dimuat)
  String get namaInduk => induk?['ear_tag'] ?? '-';

  /// Nama pejantan dari relasi (jika dimuat)
  String get namaPejantan => pejantan?['ear_tag'] ?? '-';

  /// Hitung umur dari tanggal_lahir
  String get umur {
    if (tanggalLahir == null) return '-';
    final lahir = DateTime.tryParse(tanggalLahir!);
    if (lahir == null) return '-';
    final now = DateTime.now();
    final years = now.year - lahir.year;
    final months = now.month - lahir.month;
    final totalMonths = years * 12 + months;
    final th = totalMonths ~/ 12;
    final bln = totalMonths % 12;
    if (th == 0) return '$bln bln';
    return '$th th $bln bln';
  }

  /// Label jenis kelamin yang lebih rapi
  String get jenisKelaminLabel =>
      jenisKelamin == 'jantan' ? 'Jantan' : jenisKelamin == 'betina' ? 'Betina' : jenisKelamin;
}