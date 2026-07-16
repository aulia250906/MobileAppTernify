<?php

use App\Models\Domba;
use App\Models\User;
use Illuminate\Support\Str;

it('generates id_domba automatically when creating', function () {
    $user = User::factory()->create();

    $domba = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'E001',
        'jenis_kelamin' => 'jantan',
    ]);

    expect($domba->id_domba)->not->toBeNull();
    expect(Str::startsWith($domba->id_domba, 'DMB-'))->toBeTrue();
});

it('does not overwrite id_domba if already provided', function () {
    $user = User::factory()->create();

    $domba = Domba::create([
        'id_domba' => 'DMB-CUSTOM',
        'user_id' => $user->id,
        'ear_tag' => 'E002',
        'jenis_kelamin' => 'betina',
    ]);

    expect($domba->id_domba)->toBe('DMB-CUSTOM');
});

it('can perform soft deletes', function () {
    $user = User::factory()->create();

    $domba = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'E003',
        'jenis_kelamin' => 'jantan',
    ]);

    $dombaId = $domba->id_domba;
    
    // Perform soft delete
    $domba->delete();

    // Ensure it is not in normal queries
    expect(Domba::find($dombaId))->toBeNull();

    // Ensure it is in withTrashed queries
    expect(Domba::withTrashed()->find($dombaId))->not->toBeNull();
});

it('belongs to a user', function () {
    $user = User::factory()->create();

    $domba = Domba::create([
        'user_id' => $user->id,
        'ear_tag' => 'E004',
        'jenis_kelamin' => 'betina',
    ]);

    expect($domba->user)->toBeInstanceOf(User::class);
    expect($domba->user->id)->toBe($user->id);
});

it('can have induk and pejantan relations', function () {
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

    expect($anak->induk)->toBeInstanceOf(Domba::class);
    expect($anak->induk->id_domba)->toBe($induk->id_domba);
    
    expect($anak->pejantan)->toBeInstanceOf(Domba::class);
    expect($anak->pejantan->id_domba)->toBe($pejantan->id_domba);
});
