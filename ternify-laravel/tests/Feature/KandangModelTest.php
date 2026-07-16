<?php

use App\Models\Domba;
use App\Models\Kandang;
use App\Models\RiwayatKandang;
use App\Models\User;
use Illuminate\Support\Str;

it('generates id_kandang automatically when creating', function () {
    $user = User::factory()->create();

    $kandang = Kandang::create([
        'user_id' => $user->id,
        'nama_kandang' => 'Kandang A',
        'tipe_kandang' => 'Penggemukan',
        'kapasitas' => 20,
    ]);

    expect($kandang->id_kandang)->not->toBeNull();
    expect(Str::startsWith($kandang->id_kandang, 'KDG-'))->toBeTrue();
});

it('can perform soft deletes on kandang', function () {
    $user = User::factory()->create();

    $kandang = Kandang::create([
        'user_id' => $user->id,
        'nama_kandang' => 'Kandang B',
        'kapasitas' => 10,
    ]);

    $id = $kandang->id_kandang;
    $kandang->delete();

    expect(Kandang::find($id))->toBeNull();
    expect(Kandang::withTrashed()->find($id))->not->toBeNull();
});

it('calculates jumlah_domba attribute correctly based on riwayat_kandang', function () {
    $user = User::factory()->create();

    $kandang = Kandang::create([
        'user_id' => $user->id,
        'nama_kandang' => 'Kandang Induk',
        'kapasitas' => 50,
    ]);

    // Domba 1: Aktif di kandang ini
    $domba1 = Domba::create(['user_id' => $user->id, 'ear_tag' => 'D1', 'jenis_kelamin' => 'betina', 'status_ketersediaan' => 'tersedia']);
    RiwayatKandang::create([
        'user_id' => $user->id,
        'id_kandang' => $kandang->id_kandang,
        'id_domba' => $domba1->id_domba,
        'tanggal_masuk' => now(),
    ]);

    // Domba 2: Sudah keluar (tanggal_keluar not null)
    $domba2 = Domba::create(['user_id' => $user->id, 'ear_tag' => 'D2', 'jenis_kelamin' => 'jantan', 'status_ketersediaan' => 'tersedia']);
    RiwayatKandang::create([
        'user_id' => $user->id,
        'id_kandang' => $kandang->id_kandang,
        'id_domba' => $domba2->id_domba,
        'tanggal_masuk' => now()->subDays(10),
        'tanggal_keluar' => now(),
    ]);

    // Domba 3: Aktif tapi status ketersediaan 'terjual' (bukan 'tersedia')
    $domba3 = Domba::create(['user_id' => $user->id, 'ear_tag' => 'D3', 'jenis_kelamin' => 'jantan', 'status_ketersediaan' => 'terjual']);
    RiwayatKandang::create([
        'user_id' => $user->id,
        'id_kandang' => $kandang->id_kandang,
        'id_domba' => $domba3->id_domba,
        'tanggal_masuk' => now(),
    ]);

    // Domba 4: Aktif tapi domba-nya sudah di-soft delete
    $domba4 = Domba::create(['user_id' => $user->id, 'ear_tag' => 'D4', 'jenis_kelamin' => 'betina', 'status_ketersediaan' => 'tersedia']);
    RiwayatKandang::create([
        'user_id' => $user->id,
        'id_kandang' => $kandang->id_kandang,
        'id_domba' => $domba4->id_domba,
        'tanggal_masuk' => now(),
    ]);
    $domba4->delete(); // Soft delete domba4

    // Yang dihitung hanya Domba 1
    expect($kandang->jumlah_domba)->toBe(1);
});
