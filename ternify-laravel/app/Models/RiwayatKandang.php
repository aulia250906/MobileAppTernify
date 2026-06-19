<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class RiwayatKandang extends Model
{
    protected $table = 'riwayat_kandang';
    protected $primaryKey = 'id_riwayat_kandang';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id_riwayat_kandang', 
        'user_id', 
        'id_kandang', 
        'id_domba',
        'tanggal_masuk', 
        'tanggal_keluar',
    ];

    protected $casts = [
        'tanggal_masuk'  => 'date',
        'tanggal_keluar' => 'date',
    ];

    protected static function booted(): void
    {
        static::creating(function (RiwayatKandang $rk) {
            if (empty($rk->id_riwayat_kandang)) {
                $rk->id_riwayat_kandang = 'RK-' . strtoupper(Str::random(8));
            }
        });
    }

    public function kandang()
    {
        return $this->belongsTo(Kandang::class, 'id_kandang', 'id_kandang');
    }

    public function domba()
    {
        return $this->belongsTo(Domba::class, 'id_domba', 'id_domba');
    }
}