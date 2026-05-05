<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('riwayat_kandang', function (Blueprint $table) {
            $table->string('id_riwayat_kandang')->primary();
            $table->string('id_kandang');
            $table->string('id_domba');
            $table->date('tanggal_masuk');
            $table->date('tanggal_keluar')->nullable(); // null = masih di kandang
            $table->timestamps();

            $table->foreign('id_kandang')
                  ->references('id_kandang')->on('kandang')->cascadeOnDelete();
            $table->foreign('id_domba')
                  ->references('id_domba')->on('domba')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('riwayat_kandang');
    }
};