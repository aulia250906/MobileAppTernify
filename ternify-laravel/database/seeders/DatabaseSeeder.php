<?php

namespace Database\Seeders;

use App\Models\Domba;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Betina (bisa jadi induk)
        $betina1 = Domba::create([
            'ear_tag'       => 'EAR-001',
            'id_bangsa'     => 'merino',
            'jenis_kelamin' => 'betina',
            'tanggal_lahir' => '2022-03-10',
        ]);

        $betina2 = Domba::create([
            'ear_tag'       => 'EAR-002',
            'id_bangsa'     => 'garut',
            'jenis_kelamin' => 'betina',
            'tanggal_lahir' => '2021-07-15',
        ]);

        // Jantan (bisa jadi pejantan)
        $jantan1 = Domba::create([
            'ear_tag'       => 'EAR-003',
            'id_bangsa'     => 'merino',
            'jenis_kelamin' => 'jantan',
            'tanggal_lahir' => '2021-11-20',
        ]);

        // Anak dari betina1 + jantan1
        Domba::create([
            'ear_tag'       => 'EAR-004',
            'id_bangsa'     => 'merino',
            'jenis_kelamin' => 'betina',
            'tanggal_lahir' => '2023-05-01',
            'id_induk'      => $betina1->id_domba,
            'id_pejantan'   => $jantan1->id_domba,
        ]);

        Domba::create([
            'ear_tag'       => 'EAR-005',
            'id_bangsa'     => 'garut',
            'jenis_kelamin' => 'jantan',
            'tanggal_lahir' => '2023-08-22',
            'id_induk'      => $betina2->id_domba,
            'id_pejantan'   => $jantan1->id_domba,
        ]);
    }
}