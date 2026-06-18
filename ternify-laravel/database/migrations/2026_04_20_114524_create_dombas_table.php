<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
       Schema::create('domba', function (Blueprint $table) {
    $table->string('id_domba')->primary();

    $table->foreignId('user_id')
        ->constrained('users')
        ->cascadeOnDelete();

    $table->string('ear_tag');
    $table->string('id_bangsa')->nullable();
    $table->enum('jenis_kelamin', ['jantan', 'betina']);
    $table->date('tanggal_lahir')->nullable();
    $table->decimal('berat', 5, 1)->nullable();
    $table->enum('status', ['Sehat', 'Bunting', 'Sakit'])->default('Sehat');
    $table->string('vaksinasi')->nullable();

    $table->string('id_induk')->nullable();
    $table->string('id_pejantan')->nullable();

    $table->timestamps();
    $table->softDeletes();

    $table->unique(['user_id', 'ear_tag']);

    $table->foreign('id_induk')
        ->references('id_domba')->on('domba')->nullOnDelete();

    $table->foreign('id_pejantan')
        ->references('id_domba')->on('domba')->nullOnDelete();
});

        // Riwayat berat
        Schema::create('riwayat_berat', function (Blueprint $table) {
    $table->id();

    $table->foreignId('user_id')
        ->constrained('users')
        ->cascadeOnDelete();

    $table->string('id_domba');
    $table->decimal('berat', 5, 1);
    $table->date('tanggal');

    $table->timestamps();

    $table->foreign('id_domba')
        ->references('id_domba')->on('domba')->cascadeOnDelete();
});
    }

    public function down(): void
    {
        Schema::dropIfExists('riwayat_berat');
        Schema::dropIfExists('domba');
    }
};