<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rekam_medis', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('id_domba')->nullable();
            $table->string('ear_tag');

            $table->date('tanggal_pemeriksaan');
            $table->decimal('berat', 5, 1)->nullable();
            $table->decimal('suhu_tubuh', 4, 1)->nullable();
            $table->string('status_kesehatan')->nullable();
            $table->string('vaksinasi')->nullable();
            $table->text('obat')->nullable();
            $table->text('catatan')->nullable();

            $table->timestamps();

            $table->foreign('id_domba')
                ->references('id_domba')->on('domba')->nullOnDelete();

            $table->index(['user_id', 'ear_tag']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rekam_medis');
    }
};
