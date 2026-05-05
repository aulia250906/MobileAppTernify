<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kandang', function (Blueprint $table) {
            $table->string('id_kandang')->primary();
            $table->string('nama_kandang')->unique();
            $table->string('tipe_kandang')->nullable();
            $table->integer('kapasitas')->default(0);
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kandang');
    }
};