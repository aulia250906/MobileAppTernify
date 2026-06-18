<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
       Schema::create('users', function (Blueprint $table) {
    $table->id();

    $table->string('google_id')->nullable()->unique();
    $table->string('nama_lengkap');
    $table->string('email')->unique();
    $table->string('password')->nullable();

    $table->string('avatar')->nullable();
    $table->timestamp('email_verified_at')->nullable();

    $table->string('no_telepon')->nullable();
    $table->string('nama_peternakan')->nullable();
    $table->string('lokasi')->nullable();

    $table->timestamps();
});
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};