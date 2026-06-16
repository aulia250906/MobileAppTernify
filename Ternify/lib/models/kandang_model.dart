class Kandang {
  final String idKandang;
  final String namaKandang;
  final String? tipeKandang;
  final int kapasitas;
  final int jumlahDomba;

  const Kandang({
    required this.idKandang,
    required this.namaKandang,
    this.tipeKandang,
    required this.kapasitas,
    this.jumlahDomba = 0,
  });

  factory Kandang.fromJson(Map<String, dynamic> json) {
    return Kandang(
      idKandang: json['id_kandang'] ?? '',
      namaKandang: json['nama_kandang'] ?? '',
      tipeKandang: json['tipe_kandang'],
      kapasitas: json['kapasitas'] as int? ?? 0,
      jumlahDomba: json['jumlah_domba'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'nama_kandang': namaKandang,
    'tipe_kandang': tipeKandang,
    'kapasitas': kapasitas,
  };

  double get persentaseIsi =>
      kapasitas > 0 ? (jumlahDomba / kapasitas).clamp(0.0, 1.0) : 0.0;

  int get persentaseIsiDisplay => (persentaseIsi * 100).round();
}
