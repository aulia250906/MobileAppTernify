<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('log_digitalisasi', function (Blueprint $table) {
            $table->string('id_scan')->primary();

            // Relasi ke akun user
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Data tampilan riwayat scan
            $table->string('nama_file')->nullable();

            // Atribut sesuai ERD
            $table->string('jenis_dokumen');
            $table->date('tanggal_scan');
            $table->unsignedTinyInteger('akurasi_score')->default(0);

            // Opsional untuk menyimpan hasil OCR
            $table->longText('hasil_ocr')->nullable();
            $table->json('detail_data')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'tanggal_scan']);
            $table->index(['user_id', 'akurasi_score']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('log_digitalisasi');
    }
};