<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class LogDigitalisasi extends Model
{
    use SoftDeletes;

    protected $table = 'log_digitalisasi';
    protected $primaryKey = 'id_scan';

    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id_scan',
        'user_id',
        'nama_file',
        'jenis_dokumen',
        'tanggal_scan',
        'akurasi_score',
        'hasil_ocr',
        'detail_data',
    ];

    protected $casts = [
        'tanggal_scan' => 'date',
        'akurasi_score' => 'integer',
        'detail_data' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}