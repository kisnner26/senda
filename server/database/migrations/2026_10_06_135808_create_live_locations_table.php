<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('live_locations', function (Blueprint $table) {
            $table->id();
            $table->double('event_at')->default(0);
            $table->text('position')->nullable();
        });
        DB::table('live_locations')->insert(['id' => 1, 'event_at' => 0]);
    }

    public function down(): void
    {
        Schema::dropIfExists('live_locations');
    }
};
