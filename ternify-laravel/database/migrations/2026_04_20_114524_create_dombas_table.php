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
            $table->string('ear_tag')->unique();
            $table->string('id_bangsa')->nullable();
            $table->enum('jenis_kelamin', ['jantan', 'betina']);
            $table->date('tanggal_lahir')->nullable();
            $table->string('id_induk')->nullable();
            $table->string('id_pejantan')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Self-referencing foreign keys
            $table->foreign('id_induk')
                  ->references('id_domba')
                  ->on('domba')
                  ->nullOnDelete();

            $table->foreign('id_pejantan')
                  ->references('id_domba')
                  ->on('domba')
                  ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('domba');
    }
};