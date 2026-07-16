<?php

use App\Http\Resources\KandangResource;
use App\Models\Kandang;
use App\Models\User;
use Illuminate\Http\Request;

it('transforms kandang model to correct array structure', function () {
    $user = User::factory()->create();

    $kandang = Kandang::create([
        'user_id' => $user->id,
        'nama_kandang' => 'Kandang C',
        'tipe_kandang' => 'Pembesaran',
        'kapasitas' => 30,
    ]);

    $resource = new KandangResource($kandang);
    $array = $resource->resolve();

    expect($array['id_kandang'])->toBe($kandang->id_kandang);
    expect($array['nama_kandang'])->toBe('Kandang C');
    expect($array['tipe_kandang'])->toBe('Pembesaran');
    expect($array['kapasitas'])->toBe(30);
    expect($array['jumlah_domba'])->toBe(0); // accessor based on db
});
