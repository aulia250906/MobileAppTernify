<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('domba', function (Blueprint $table) {
            $table->enum('status_ketersediaan', ['tersedia', 'terjual', 'mati'])
                  ->default('tersedia')
                  ->after('vaksinasi');
        });
    }

    public function down(): void
    {
        Schema::table('domba', function (Blueprint $table) {
            $table->dropColumn('status_ketersediaan');
        });
    }
};
