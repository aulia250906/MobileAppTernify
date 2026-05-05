<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RiwayatBerat extends Model
{
    protected $table = 'riwayat_berat';

    protected $fillable = ['id_domba', 'berat', 'tanggal'];

    protected $casts = [
        'berat'   => 'float',
        'tanggal' => 'date',
    ];

    public function domba()
    {
        return $this->belongsTo(Domba::class, 'id_domba', 'id_domba');
    }
}