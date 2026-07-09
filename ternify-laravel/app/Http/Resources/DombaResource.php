<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DombaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_domba' => $this->id_domba,
            'ear_tag' => $this->ear_tag,
            'id_bangsa' => $this->id_bangsa,
            'jenis_kelamin' => $this->jenis_kelamin,
            'tanggal_lahir' => $this->tanggal_lahir?->format('Y-m-d'),
            'berat' => $this->berat,
            'status' => $this->status,
            'vaksinasi' => $this->vaksinasi,
            'status_ketersediaan' => $this->status_ketersediaan ?? 'tersedia',
            'id_induk' => $this->id_induk,
            'ear_tag_induk' => $this->ear_tag_induk,
            'id_pejantan' => $this->id_pejantan,
            'ear_tag_pejantan' => $this->ear_tag_pejantan,

            // Relasi (dimuat hanya jika di-load)
            'induk' => $this->whenLoaded('induk', fn () => [
                'id_domba' => $this->induk?->id_domba,
                'ear_tag' => $this->induk?->ear_tag,
            ]),
            'pejantan' => $this->whenLoaded('pejantan', fn () => [
                'id_domba' => $this->pejantan?->id_domba,
                'ear_tag' => $this->pejantan?->ear_tag,
            ]),

            'created_at' => $this->created_at?->toDateTimeString(),
            'updated_at' => $this->updated_at?->toDateTimeString(),
        ];
    }
}
