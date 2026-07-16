<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $fillable = [
        'google_id',
    'nama_lengkap',
    'email',
    'password',
    'avatar',
    'email_verified_at',
    'no_telepon',
    'nama_peternakan',
    'lokasi',
    ];
    
    protected $casts = [
    'email_verified_at' => 'datetime',
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