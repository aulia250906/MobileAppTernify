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
        'id_domba',
        'ear_tag',
        'id_bangsa',
        'jenis_kelamin',
        'tanggal_lahir',
        'id_induk',
        'id_pejantan',
    ];

    protected $casts = [
        'tanggal_lahir' => 'date',
    ];

    // Auto-generate ID sebelum create
    protected static function booted(): void
    {
        static::creating(function (Domba $domba) {
            if (empty($domba->id_domba)) {
                $domba->id_domba = 'DMB-' . strtoupper(Str::random(8));
            }
        });
    }

    // === RELASI SELF-REFERENCING ===

    // Induk (betina) dari domba ini
    public function induk(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Domba::class, 'id_induk', 'id_domba');
    }

    // Pejantan (jantan) dari domba ini
    public function pejantan(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Domba::class, 'id_pejantan', 'id_domba');
    }

    // Anak-anak yang lahir dari domba ini sebagai induk
    public function anakSebagaiInduk(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Domba::class, 'id_induk', 'id_domba');
    }

    // Anak-anak yang lahir dari domba ini sebagai pejantan
    public function anakSebagaipejantan(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Domba::class, 'id_pejantan', 'id_domba');
    }
}