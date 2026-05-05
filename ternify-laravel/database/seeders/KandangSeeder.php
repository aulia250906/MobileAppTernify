<?php

namespace Database\Seeders;

use App\Models\Kandang;
use Illuminate\Database\Seeder;

class KandangSeeder extends Seeder
{
    public function run(): void
    {
        $data = [
            [
                'id_kandang'   => 'KDG-001',
                'nama_kandang' => 'Kandang A',
                'tipe_kandang' => 'Blok Utara',
                'kapasitas'    => 60,
            ],
            [
                'id_kandang'   => 'KDG-002',
                'nama_kandang' => 'Kandang B',
                'tipe_kandang' => 'Blok Selatan',
                'kapasitas'    => 50,
            ],
            [
                'id_kandang'   => 'KDG-003',
                'nama_kandang' => 'Kandang C',
                'tipe_kandang' => 'Blok Timur',
                'kapasitas'    => 40,
            ],
        ];

        foreach ($data as $item) {
            Kandang::create($item);
        }
    }
}