<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('perkawinan', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('id_domba_betina')->nullable();
            $table->string('id_domba_jantan')->nullable();
            $table->string('ear_tag_betina');
            $table->string('ear_tag_jantan');

            $table->date('tanggal_kawin');
            $table->string('metode_kawin')->nullable();           // alami, IB
            $table->date('tanggal_perkiraan_lahir')->nullable();
            $table->string('status_perkawinan')->default('kawin'); // kawin, bunting, lahir, gagal
            $table->integer('jumlah_anak')->nullable();
            $table->text('catatan')->nullable();

            $table->timestamps();

            $table->foreign('id_domba_betina')
                ->references('id_domba')->on('domba')->nullOnDelete();

            $table->foreign('id_domba_jantan')
                ->references('id_domba')->on('domba')->nullOnDelete();

            $table->index(['user_id', 'ear_tag_betina']);
            $table->index(['user_id', 'ear_tag_jantan']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('perkawinan');
    }
};
