<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'nama_lengkap',
        'email',
        'password',
        'no_telepon',
        'nama_peternakan',
        'lokasi',
    ];

    protected $hidden = [
        'password',
    ];

    public function domba()
    {
        return $this->hasMany(Domba::class);
    }

    public function kandang()
    {
        return $this->hasMany(Kandang::class);
    }
}