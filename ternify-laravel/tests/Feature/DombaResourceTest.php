<?php

use App\Http\Resources\DombaResource;
use App\Models\Domba;
use App\Models\User;
use Illuminate\Http\Request;

it('transforms domba model to correct array structure', function () {
    $user = User::factory()->create();

    $domba = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'E001',
        'jenis_kelamin' => 'jantan',
        'tanggal_lahir' => '2023-01-01',
        'berat' => 10.5,
    ]);

    $resource = new DombaResource($domba);
    $array = $resource->resolve();

    expect($array['id_domba'])->toBe($domba->id_domba);
    expect($array['ear_tag'])->toBe('E001');
    expect($array['jenis_kelamin'])->toBe('jantan');
    expect($array['tanggal_lahir'])->toBe('2023-01-01');
    expect($array['berat'])->toBe(10.5);
    expect($array['status_ketersediaan'])->toBe('tersedia'); // default value
    expect($array)->not->toHaveKey('induk'); // Not loaded
    expect($array)->not->toHaveKey('pejantan'); // Not loaded
});

it('includes related induk and pejantan when loaded', function () {
    $user = User::factory()->create();

    $induk = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'I-001',
        'jenis_kelamin' => 'betina',
    ]);

    $pejantan = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'P-001',
        'jenis_kelamin' => 'jantan',
    ]);

    $anak = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'A-001',
        'jenis_kelamin' => 'betina',
        'id_induk' => $induk->id_domba,
        'id_pejantan' => $pejantan->id_domba,
    ]);

    $anak->load(['induk', 'pejantan']);

    $resource = new DombaResource($anak);
    $array = $resource->resolve();

    expect($array)->toHaveKey('induk');
    expect($array['induk']['id_domba'])->toBe($induk->id_domba);
    expect($array['induk']['ear_tag'])->toBe('I-001');

    expect($array)->toHaveKey('pejantan');
    expect($array['pejantan']['id_domba'])->toBe($pejantan->id_domba);
    expect($array['pejantan']['ear_tag'])->toBe('P-001');
});
