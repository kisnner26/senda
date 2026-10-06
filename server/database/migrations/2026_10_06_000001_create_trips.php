<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->dateTime('started_at')->index();
            $table->dateTime('ended_at');
            $table->string('payload_hash', 64);
            $table->timestamps();
        });
        Schema::create('measurements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->dateTime('timestamp');
            $table->double('latitude');
            $table->double('longitude');
            $table->double('accuracy');
            $table->double('latency')->nullable();
            $table->string('quality', 12);
            $table->string('interface', 32);
            $table->index(['trip_id', 'timestamp']);
            $table->index(['latitude', 'longitude']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('measurements');
        Schema::dropIfExists('trips');
    }
};
