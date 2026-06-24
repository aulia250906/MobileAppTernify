<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RekamMedis extends Model
{
    protected $table = 'rekam_medis';

    protected $fillable = [
        'user_id',
        'id_domba',
        'ear_tag',
        'tanggal_pemeriksaan',
        'berat',
        'suhu_tubuh',
        'status_kesehatan',
        'vaksinasi',
        'obat',
        'catatan',
    ];

    protected $casts = [
        'tanggal_pemeriksaan' => 'date',
        'berat'               => 'float',
        'suhu_tubuh'          => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function domba()
    {
        return $this->belongsTo(Domba::class, 'id_domba', 'id_domba');
    }
}
