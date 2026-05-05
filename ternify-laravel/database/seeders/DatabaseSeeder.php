<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Urutan penting: kandang harus ada sebelum domba
        $this->call([
            KandangSeeder::class,
            DombaSeeder::class,
        ]);
    }
}