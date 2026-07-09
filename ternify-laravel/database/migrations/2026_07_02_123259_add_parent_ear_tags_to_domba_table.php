<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('domba', function (Blueprint $table) {
            $table->string('ear_tag_induk')->nullable()->after('id_induk');
            $table->string('ear_tag_pejantan')->nullable()->after('id_pejantan');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('domba', function (Blueprint $table) {
            $table->dropColumn(['ear_tag_induk', 'ear_tag_pejantan']);
        });
    }
};
