<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Domba extends Model
{
    use SoftDeletes;

    protected $table = 'domba';
    protected $primaryKey = 'id_domba';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id_domba', 'user_id', 'ear_tag', 'id_bangsa', 'jenis_kelamin',
        'tanggal_lahir', 'berat', 'status', 'vaksinasi',
        'id_induk', 'id_pejantan',
    ];

    protected $casts = [
        'tanggal_lahir' => 'date',
        'berat'         => 'float',
    ];

    protected static function booted(): void
    {
        static::creating(function (Domba $domba) {
            if (empty($domba->id_domba)) {
                $domba->id_domba = 'DMB-' . strtoupper(Str::random(8));
            }
        });
    }

    // Pemilik domba
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Self-referencing
    public function induk()
    {
        return $this->belongsTo(Domba::class, 'id_induk', 'id_domba');
    }

    public function pejantan()
    {
        return $this->belongsTo(Domba::class, 'id_pejantan', 'id_domba');
    }

    // Riwayat berat
    public function riwayatBerat()
    {
        return $this->hasMany(RiwayatBerat::class, 'id_domba', 'id_domba')
                    ->orderBy('tanggal', 'asc')
                    ->limit(5);
    }

    // Riwayat kandang
    public function riwayatKandang()
    {
        return $this->hasMany(RiwayatKandang::class, 'id_domba', 'id_domba')
                    ->orderBy('tanggal_masuk', 'desc');
    }

    // Kandang aktif saat ini (tanggal_keluar null)
    public function kandangAktif()
    {
        return $this->hasOne(RiwayatKandang::class, 'id_domba', 'id_domba')
                    ->whereNull('tanggal_keluar')
                    ->latest('tanggal_masuk');
    }
}