<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Perkawinan extends Model
{
    protected $table = 'perkawinan';

    protected $fillable = [
        'user_id',
        'id_domba_betina',
        'id_domba_jantan',
        'ear_tag_betina',
        'ear_tag_jantan',
        'tanggal_kawin',
        'metode_kawin',
        'tanggal_perkiraan_lahir',
        'status_perkawinan',
        'jumlah_anak',
        'catatan',
    ];

    protected $casts = [
        'tanggal_kawin'           => 'date',
        'tanggal_perkiraan_lahir' => 'date',
        'jumlah_anak'             => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function betina()
    {
        return $this->belongsTo(Domba::class, 'id_domba_betina', 'id_domba');
    }

    public function jantan()
    {
        return $this->belongsTo(Domba::class, 'id_domba_jantan', 'id_domba');
    }
}
