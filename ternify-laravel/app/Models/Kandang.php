<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Kandang extends Model
{
    use SoftDeletes;

    protected $table = 'kandang';
    protected $primaryKey = 'id_kandang';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id_kandang', 'user_id', 'nama_kandang', 'tipe_kandang', 'kapasitas',
    ];

    protected $casts = [
        'kapasitas' => 'integer',
    ];

    protected static function booted(): void
    {
        static::creating(function (Kandang $kandang) {
            if (empty($kandang->id_kandang)) {
                $kandang->id_kandang = 'KDG-' . strtoupper(Str::random(6));
            }
        });
    }

    // Pemilik kandang
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Semua riwayat kandang
    public function riwayatKandang()
    {
        return $this->hasMany(RiwayatKandang::class, 'id_kandang', 'id_kandang');
    }

    // Domba yang sedang aktif di kandang ini (tanggal_keluar null)
    public function dombaAktif()
    {
        return $this->hasManyThrough(
            Domba::class,
            RiwayatKandang::class,
            'id_kandang', // FK di riwayat_kandang
            'id_domba',   // FK di domba
            'id_kandang', // PK di kandang
            'id_domba'    // FK di riwayat_kandang
        )->whereNull('riwayat_kandang.tanggal_keluar');
    }

    // Accessor: jumlah domba aktif
    public function getJumlahDombaAttribute(): int
    {
        return RiwayatKandang::where('id_kandang', $this->id_kandang)
                             ->whereNull('tanggal_keluar')
                             ->whereHas('domba', function ($q) {
                                 $q->whereNull('deleted_at')
                                   ->where('status_ketersediaan', 'tersedia');
                             })
                             ->count();
    }
}