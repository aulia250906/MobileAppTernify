<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
public function up(): void
{
    Schema::table('domba', function (Blueprint $table) {
        if (!Schema::hasColumn('domba', 'user_id')) {
            $table->foreignId('user_id')
                ->nullable()
                ->after('id_domba')
                ->constrained('users')
                ->nullOnDelete();
        }
    });

    Schema::table('kandang', function (Blueprint $table) {
        if (!Schema::hasColumn('kandang', 'user_id')) {
            $table->foreignId('user_id')
                ->nullable()
                ->after('id_kandang')
                ->constrained('users')
                ->nullOnDelete();
        }
    });
}
public function down(): void
{
    Schema::table('domba', function (Blueprint $table) {
        if (Schema::hasColumn('domba', 'user_id')) {
            $table->dropColumn('user_id');
        }
    });

    Schema::table('kandang', function (Blueprint $table) {
        if (Schema::hasColumn('kandang', 'user_id')) {
            $table->dropColumn('user_id');
        }
    });
}};
