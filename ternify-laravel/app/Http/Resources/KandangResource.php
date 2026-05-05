<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class KandangResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_kandang'    => $this->id_kandang,
            'nama_kandang'  => $this->nama_kandang,
            'tipe_kandang'  => $this->tipe_kandang,
            'kapasitas'     => $this->kapasitas,
            'jumlah_domba'  => $this->jumlah_domba,   // dari accessor
            'created_at'    => $this->created_at?->toDateTimeString(),
            'updated_at'    => $this->updated_at?->toDateTimeString(),
        ];
    }
}